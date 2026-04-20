import csv
import os
import time
import logging

import boto3
import joblib
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import HTMLResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, generate_latest, Histogram
from pydantic import BaseModel

logger = logging.getLogger("uvicorn.error")
app = FastAPI()

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
EQUIPMENT_CSV = os.path.join(DATA_DIR, "hospital_equipment.csv")
model_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "models", "model.pkl")

try:
    model = joblib.load(model_path)
except FileNotFoundError:
    model = None
    logger.warning("Model file not found at %s", model_path)

AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
CLOUDWATCH_NAMESPACE = os.getenv("CLOUDWATCH_NAMESPACE", "PredictiveMaintenance")
cloudwatch_client = boto3.client("cloudwatch", region_name=AWS_REGION)

REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"],
)
PREDICTION_REQUESTS = Counter("prediction_requests_total", "Total prediction requests")
PREDICTION_FAILURES = Counter("prediction_failures_total", "Predicted failures")
PREDICTION_DURATION = Histogram("prediction_processing_seconds", "Time spent processing prediction requests")
EQUIPMENT_HEALTH = Gauge(
    "hospital_equipment_health_score",
    "Health score of hospital equipment",
    ["equipment_type", "equipment_id"],
)
EQUIPMENT_USAGE = Gauge(
    "hospital_equipment_usage_hours",
    "Usage hours of hospital equipment",
    ["equipment_type", "equipment_id"],
)

class PredictRequest(BaseModel):
    sensor1: float
    sensor2: float
    sensor3: float


def publish_metric(name, value, dimensions=None, unit="None"):
    if dimensions is None:
        dimensions = []
    try:
        cloudwatch_client.put_metric_data(
            Namespace=CLOUDWATCH_NAMESPACE,
            MetricData=[
                {
                    "MetricName": name,
                    "Dimensions": dimensions,
                    "Value": value,
                    "Unit": unit,
                }
            ],
        )
    except Exception as exc:
        logger.warning("CloudWatch metric publish failed: %s", exc)


def make_dimensions(equipment):
    return [
        {"Name": "equipment_type", "Value": equipment["equipment_type"]},
        {"Name": "equipment_id", "Value": equipment["equipment_id"]},
        {"Name": "location", "Value": equipment["location"]},
    ]


def load_equipment_data():
    equipment = []
    if os.path.exists(EQUIPMENT_CSV):
        with open(EQUIPMENT_CSV, newline="", encoding="utf-8") as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                row["usage_hours"] = float(row["usage_hours"])
                row["temperature"] = float(row["temperature"])
                row["vibration"] = float(row["vibration"])
                row["health_score"] = float(row["health_score"])
                row["failure"] = int(row["failure"])
                equipment.append(row)

                dimensions = make_dimensions(row)
                EQUIPMENT_HEALTH.labels(
                    equipment_type=row["equipment_type"],
                    equipment_id=row["equipment_id"],
                ).set(row["health_score"])
                EQUIPMENT_USAGE.labels(
                    equipment_type=row["equipment_type"],
                    equipment_id=row["equipment_id"],
                ).set(row["usage_hours"])

                publish_metric("HospitalEquipmentHealthScore", row["health_score"], dimensions, unit="None")
                publish_metric("HospitalEquipmentUsageHours", row["usage_hours"], dimensions, unit="None")
                publish_metric("HospitalEquipmentTemperature", row["temperature"], dimensions, unit="None")
                publish_metric("HospitalEquipmentVibration", row["vibration"], dimensions, unit="None")
                if row["failure"] == 1:
                    publish_metric("HospitalDeviceAlerts", 1, dimensions, unit="Count")
    return equipment

EQUIPMENT_DATA = load_equipment_data()


@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    response = await call_next(request)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        http_status=str(response.status_code),
    ).inc()
    return response


@app.get("/")
def home():
    return {"message": "Predictive Maintenance API running"}


@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    return HTMLResponse(
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Hospital Equipment Monitoring Dashboard</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f4f6fb; }
                header { margin-bottom: 24px; }
                h1 { margin: 0; color: #2e3b55; }
                .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px; }
                .card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.08); }
                table { width: 100%; border-collapse: collapse; margin-top: 12px; }
                th, td { padding: 10px; border-bottom: 1px solid #e0e6f0; text-align: left; }
                th { color: #4a5668; }
                .small { font-size: 0.95rem; color: #5e6c84; }
                .alert { color: #b91c1c; font-weight: bold; }
            </style>
        </head>
        <body>
            <header>
                <h1>Hospital Equipment Monitoring</h1>
                <p class="small">Live metrics dashboard for MRI, CT, ventilators, and other hospital systems.</p>
            </header>

            <div class="grid">
                <div class="card">
                    <h2>Operational Alert Summary</h2>
                    <div id="alertSummary"></div>
                </div>
                <div class="card">
                    <h2>Equipment Health Scores</h2>
                    <canvas id="healthChart"></canvas>
                </div>
                <div class="card">
                    <h2>Usage Hours by Device</h2>
                    <canvas id="usageChart"></canvas>
                </div>
                <div class="card">
                    <h2>Equipment Type Distribution</h2>
                    <canvas id="typeChart"></canvas>
                </div>
            </div>

            <div class="grid" style="margin-top: 24px;">
                <div class="card" style="grid-column: span 2;">
                    <h2>Equipment Status Table</h2>
                    <div id="tableContainer"></div>
                </div>
                <div class="card" style="grid-column: span 1;">
                    <h2>Monitoring Endpoints</h2>
                    <p class="small"><code>/metrics</code> - Prometheus scrape endpoint</p>
                    <p class="small"><code>/equipment</code> - equipment JSON</p>
                    <p class="small"><code>/dashboard</code> - this frontend dashboard</p>
                </div>
            </div>

            <script>
                async function loadEquipment() {
                    const response = await fetch('/equipment');
                    const json = await response.json();
                    return json.equipment;
                }

                function renderTable(items) {
                    const rows = items.map(item => `
                        <tr>
                            <td>${item.equipment_id}</td>
                            <td>${item.equipment_type}</td>
                            <td>${item.location}</td>
                            <td>${item.usage_hours}</td>
                            <td>${item.health_score}</td>
                            <td>${item.failure === 1 ? '⚠️ Problem' : 'OK'}</td>
                        </tr>
                    `).join('');
                    document.getElementById('tableContainer').innerHTML = `
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th><th>Type</th><th>Location</th><th>Usage</th><th>Health</th><th>Status</th>
                                </tr>
                            </thead>
                            <tbody>${rows}</tbody>
                        </table>
                    `;
                }

                function createChart(ctx, type, labels, data, label, backgroundColor) {
                    return new Chart(ctx, {
                        type,
                        data: {
                            labels,
                            datasets: [{
                                label,
                                data,
                                backgroundColor,
                                borderColor: '#3b82f6',
                                borderWidth: 1,
                            }],
                        },
                        options: {
                            responsive: true,
                            scales: {
                                y: { beginAtZero: true },
                            },
                        },
                    });
                }

                loadEquipment().then(items => {
                    const labels = items.map(i => i.equipment_id);
                    const health = items.map(i => i.health_score);
                    const usage = items.map(i => i.usage_hours);
                    const problematic = items.filter(i => i.failure === 1);

                    const alertSummary = document.getElementById('alertSummary');
                    if (problematic.length > 0) {
                        alertSummary.innerHTML = `
                            <p class="alert">${problematic.length} device(s) require attention.</p>
                            <p class="small">First alert: ${problematic[0].equipment_type} ${problematic[0].equipment_id} in ${problematic[0].location}</p>
                        `;
                    } else {
                        alertSummary.innerHTML = `<p>All monitored devices are operating normally.</p>`;
                    }

                    const typeCounts = items.reduce((acc, item) => {
                        acc[item.equipment_type] = (acc[item.equipment_type] || 0) + 1;
                        return acc;
                    }, {});

                    const typeLabels = Object.keys(typeCounts);
                    const typeData = Object.values(typeCounts);

                    createChart(document.getElementById('healthChart'), 'bar', labels, health, 'Health Score', 'rgba(59, 130, 246, 0.6)');
                    createChart(document.getElementById('usageChart'), 'bar', labels, usage, 'Usage Hours', 'rgba(16, 185, 129, 0.6)');
                    createChart(document.getElementById('typeChart'), 'pie', typeLabels, typeData, 'Equipment Count', ['#3b82f6', '#10b981', '#f97316', '#8b5cf6', '#ec4899']);
                    renderTable(items);
                }).catch(err => {
                    document.getElementById('tableContainer').innerHTML = `<p>Error loading equipment metrics: ${err.message}</p>`;
                });
            </script>
        </body>
        </html>
        """
    )


@app.get("/equipment")
def equipment_data():
    return {"equipment": EQUIPMENT_DATA, "count": len(EQUIPMENT_DATA)}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/predict")
def predict(data: PredictRequest):
    if model is None:
        raise HTTPException(status_code=503, detail="Model file not found; train the model first.")

    with PREDICTION_DURATION.time():
        values = [data.sensor1, data.sensor2, data.sensor3]
        prediction = int(model.predict([values])[0])

    PREDICTION_REQUESTS.inc()
    if prediction == 1:
        PREDICTION_FAILURES.inc()
        publish_metric("HospitalDeviceFailurePredicted", 1, unit="Count")
        publish_metric("HospitalDeviceAlerts", 1, unit="Count")
        publish_metric("PredictionAccuracy", 1, unit="None")
    else:
        publish_metric("PredictionAccuracy", 0, unit="None")

    result = {"failure": prediction}
    if prediction == 1:
        result["alert"] = "⚠️ Failure likely!"
    return result
