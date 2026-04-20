terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_iam_role" "ec2_role" {
  name = "predictive-maintenance-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "predictive-maintenance-cloudwatch-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:PutMetricAlarm",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_sns_topic" "device_alerts" {
  name = "predictive-maintenance-device-alerts"
}

resource "aws_sns_topic_subscription" "device_alerts_email" {
  topic_arn = aws_sns_topic.device_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

variable "alert_email" {
  description = "Email for device failure alerts"
  type        = string
  default     = "yc6155@srmist.edu.in"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "predictive-maintenance-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami                    = "ami-048f4445314bcaa09"
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode("#!/bin/bash\nset -e\nyum update -y\nyum install -y python3 python3-pip\npip3 install fastapi uvicorn pandas scikit-learn joblib pydantic prometheus-client boto3\necho 'Deployment complete'\n")

  tags = {
    Name = "Predictive-Maintenance-System"
  }

  depends_on = [aws_iam_role_policy.cloudwatch_policy]
}

# Security Group
resource "aws_security_group" "app_sg" {
  name_prefix = "predictive-maintenance-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "predictive-maintenance-sg"
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "device_failure" {
  alarm_name          = "PredictiveMaintenance-DeviceFailureAlert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HospitalDeviceFailurePredicted"
  namespace           = "HospitalEquipment"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.device_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "health_score" {
  alarm_name          = "PredictiveMaintenance-LowHealthScore"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HospitalEquipmentHealthScore"
  namespace           = "HospitalEquipment"
  period              = 300
  statistic           = "Average"
  threshold           = 0.80
  alarm_actions       = [aws_sns_topic.device_alerts.arn]
}

# For CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "PredictiveMaintenanceDashboard"
  dashboard_body = jsonencode({
    widgets = [{
      type = "metric"
      properties = {
        metrics = [
          ["HospitalEquipment", "HospitalEquipmentHealthScore"],
          [".", "HospitalDeviceFailurePredicted"]
        ]
        period = 300
        stat   = "Average"
        region = "ap-south-1"
        title  = "Equipment Metrics"
      }
    }]
  })
}

# Outputs
output "ec2_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "EC2 Instance Public IP"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.device_alerts.arn
  description = "SNS Topic for Alerts"
}

output "dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:name=PredictiveMaintenanceDashboard"
  description = "CloudWatch Dashboard URL"
}

              
              # Create directories
              mkdir -p api models data preprocessing
              
              # Create preprocessing/__init__.py
              touch preprocessing/__init__.py
              
              # Create models/__init__.py
              touch models/__init__.py
              
              # Create preprocessing/preprocess.py
              cat > preprocessing/preprocess.py << 'EOL'
import pandas as pd
from sklearn.preprocessing import StandardScaler

def preprocess_data(df):
    """Preprocess the equipment data for model training."""
    # Select features for prediction
    features = ['usage_hours', 'temperature', 'vibration', 'health_score']
    
    # Handle missing values
    df = df.fillna(df.mean(numeric_only=True))
    
    # Scale features
    scaler = StandardScaler()
    df_scaled = pd.DataFrame(
        scaler.fit_transform(df[features]),
        columns=features,
        index=df.index
    )
    
    return df_scaled, scaler
EOL
              
              # Create models/train.py
              cat > models/train.py << 'EOL'
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib
import os
from preprocessing.preprocess import preprocess_data

def train_model():
    """Train the predictive maintenance model."""
    # Load data
    data_path = 'data/hospital_equipment.csv'
    if not os.path.exists(data_path):
        print(f"Data file not found: {data_path}")
        return
    
    df = pd.read_csv(data_path)
    
    # Preprocess data
    X, scaler = preprocess_data(df)
    y = df['failure']
    
    # Split data- train:test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Train model
    model = RandomForestClassifier(
        n_estimators=100,
        random_state=42,
        class_weight='balanced'
    )
    model.fit(X_train, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model accuracy: {accuracy:.2f}")
    
    # Save model and scaler
    joblib.dump(model, 'models/model.pkl')
    joblib.dump(scaler, 'models/scaler.pkl')
    print("Model and scaler saved successfully")

if __name__ == "__main__":
    train_model()
EOL
              
              # Create data/hospital_equipment.csv
              cat > data/hospital_equipment.csv << 'EOL'
equipment_id,equipment_type,location,usage_hours,temperature,vibration,health_score,failure
MRI-001,MRI,Room 101,1250.5,45.2,0.15,0.85,0
CT-001,CT Scanner,Room 102,980.3,42.8,0.12,0.92,0
XRAY-001,X-Ray,Room 103,1456.7,38.9,0.08,0.78,0
VENT-001,Ventilator,ICU-1,2340.2,41.5,0.25,0.45,1
ECG-001,ECG Machine,Emergency,567.8,35.6,0.05,0.95,0
ANES-001,Anesthesia Machine,Surgery,1234.9,39.7,0.18,0.88,0
MRI-002,MRI,Room 104,890.1,46.3,0.14,0.82,0
CT-002,CT Scanner,Room 105,1205.4,43.1,0.16,0.79,0
XRAY-002,X-Ray,Room 106,1678.3,37.8,0.09,0.71,0
VENT-002,Ventilator,ICU-2,1987.6,42.2,0.28,0.38,1
ECG-002,ECG Machine,Emergency,723.4,36.1,0.06,0.93,0
ANES-002,Anesthesia Machine,Surgery,1456.2,40.8,0.22,0.55,1
DEFIB-001,Defibrillator,Emergency,345.9,34.7,0.04,0.97,0
US-001,Ultrasound,Room 107,678.5,35.9,0.07,0.89,0
MRI-003,MRI,Room 108,1345.8,44.6,0.17,0.76,0
CT-003,CT Scanner,Room 109,876.2,41.9,0.11,0.84,0
XRAY-003,X-Ray,Room 110,1890.4,39.2,0.10,0.69,0
VENT-003,Ventilator,ICU-3,1654.3,40.7,0.19,0.72,0
ECG-003,ECG Machine,Emergency,891.6,37.4,0.08,0.91,0
US-002,Ultrasound,Room 109,890.4,63.5,0.21,0.90,0
DEFIB-002,Defibrillator,Emergency,195.6,58.1,0.10,0.98,0
EOL
              
              # Create api/app.py
              cat > api/app.py << 'EOL'
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import pandas as pd
import joblib
import boto3
import os
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import json

app = FastAPI(title="Hospital Equipment Predictive Maintenance API")

# Load model and scaler
try:
    model = joblib.load('models/model.pkl')
    scaler = joblib.load('models/scaler.pkl')
except:
    model = None
    scaler = None

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])
EQUIPMENT_HEALTH_GAUGE = Gauge('hospital_equipment_health_score', 'Current health score of equipment', ['equipment_id'])
EQUIPMENT_USAGE_GAUGE = Gauge('hospital_equipment_usage_hours', 'Usage hours of equipment', ['equipment_id'])
FAILURE_PREDICTIONS = Counter('hospital_device_failure_predicted', 'Number of failure predictions', ['equipment_id'])
ALERTS_SENT = Counter('hospital_device_alerts', 'Number of alerts sent', ['equipment_id'])

# CloudWatch client
cloudwatch = boto3.client('cloudwatch', region_name='ap-south-1')

class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        REQUEST_COUNT.labels(method=request.method, endpoint=request.url.path).inc()
        with REQUEST_LATENCY.labels(method=request.method, endpoint=request.url.path).time():
            response = await call_next(request)
        return response

app.add_middleware(PrometheusMiddleware)

class EquipmentData(BaseModel):
    equipment_id: str
    equipment_type: str
    location: str
    usage_hours: float
    temperature: float
    vibration: float
    health_score: float

def publish_metric(namespace, metric_name, value, dimensions=None, unit='Count'):
    """Publish metric to CloudWatch."""
    try:
        cloudwatch.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Dimensions': dimensions or []
                }
            ]
        )
    except Exception as e:
        print(f"Failed to publish metric: {e}")

@app.get("/")
def read_root():
    return {"message": "Hospital Equipment Predictive Maintenance API", "status": "running"}

@app.get("/equipment")
def get_equipment():
    """Get all equipment data."""
    try:
        df = pd.read_csv('data/hospital_equipment.csv')
        equipment = df.to_dict('records')
        
        # Publish metrics to CloudWatch
        for item in equipment:
            publish_metric(
                'HospitalEquipment',
                'HospitalEquipmentHealthScore',
                item['health_score'],
                [{'Name': 'EquipmentID', 'Value': item['equipment_id']}]
            )
            publish_metric(
                'HospitalEquipment',
                'HospitalEquipmentUsageHours',
                item['usage_hours'],
                [{'Name': 'EquipmentID', 'Value': item['equipment_id']}]
            )
        
        return {"equipment": equipment}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict")
def predict_failure(equipment: EquipmentData):
    """Predict equipment failure."""
    if model is None or scaler is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        # Prepare data
        data = pd.DataFrame([{
            'usage_hours': equipment.usage_hours,
            'temperature': equipment.temperature,
            'vibration': equipment.vibration,
            'health_score': equipment.health_score
        }])
        
        # Scale data
        data_scaled = scaler.transform(data)
        
        # Make prediction
        prediction = model.predict(data_scaled)[0]
        probability = model.predict_proba(data_scaled)[0][1]
        
        # Publish metrics
        publish_metric(
            'HospitalEquipment',
            'HospitalDeviceFailurePredicted',
            1 if prediction == 1 else 0,
            [{'Name': 'EquipmentID', 'Value': equipment.equipment_id}]
        )
        
        if prediction == 1:
            publish_metric(
                'HospitalEquipment',
                'HospitalDeviceAlerts',
                1,
                [{'Name': 'EquipmentID', 'Value': equipment.equipment_id}]
            )
        
        result = {
            "equipment_id": equipment.equipment_id,
            "failure_predicted": bool(prediction),
            "failure_probability": float(probability),
            "recommendation": "Schedule maintenance immediately" if prediction == 1 else "Equipment operating normally"
        }
        
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics")
def get_metrics():
    """Prometheus metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    return HTMLResponse("""
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
        </style>
    </head>
    <body>
        <header>
            <h1>Hospital Equipment Monitoring</h1>
            <p class="small">Live metrics dashboard for hospital systems.</p>
        </header>

        <div class="grid">
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
            <div class="card">
                <h2>API Endpoints</h2>
                <p class="small">Dashboard: <code>/dashboard</code></p>
                <p class="small">Equipment Data: <code>/equipment</code></p>
                <p class="small">Metrics: <code>/metrics</code></p>
                <p class="small">Prediction: <code>POST /predict</code></p>
            </div>
        </div>

        <div class="card" style="margin-top: 24px;">
            <h2>Equipment Status Table</h2>
            <div id="tableContainer">Loading equipment data...</div>
        </div>

        <script>
            async function loadEquipment() {
                try {
                    const response = await fetch('/equipment');
                    const json = await response.json();
                    return json.equipment;
                } catch (err) {
                    document.getElementById('tableContainer').innerHTML = 'Error loading data: ' + err.message;
                    return [];
                }
            }

            function renderTable(items) {
                if (items.length === 0) {
                    document.getElementById('tableContainer').innerHTML = 'No equipment data available';
                    return;
                }
                
                let rows = '';
                items.forEach(item => {
                    const status = item.failure === 1 ? 'WARNING' : 'OK';
                    rows += '<tr>' +
                        '<td>' + item.equipment_id + '</td>' +
                        '<td>' + item.equipment_type + '</td>' +
                        '<td>' + item.location + '</td>' +
                        '<td>' + item.usage_hours + '</td>' +
                        '<td>' + item.health_score + '</td>' +
                        '<td>' + status + '</td>' +
                    '</tr>';
                });
                
                document.getElementById('tableContainer').innerHTML = 
                    '<table>' +
                        '<thead><tr>' +
                            '<th>ID</th><th>Type</th><th>Location</th><th>Usage</th><th>Health</th><th>Status</th>' +
                        '</tr></thead>' +
                        '<tbody>' + rows + '</tbody>' +
                    '</table>';
            }

            function createChart(ctx, type, labels, data, label, backgroundColor) {
                return new Chart(ctx, {
                    type: type,
                    data: {
                        labels: labels,
                        datasets: [{
                            label: label,
                            data: data,
                            backgroundColor: backgroundColor,
                            borderColor: '#3b82f6',
                            borderWidth: 1,
                        }],
                    },
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true,
                            },
                        },
                    },
                });
            }

            loadEquipment().then(items => {
                renderTable(items);
                
                if (items.length > 0) {
                    const labels = items.map(i => i.equipment_id);
                    const health = items.map(i => i.health_score);
                    const usage = items.map(i => i.usage_hours);

                    const typeCounts = {};
                    items.forEach(item => {
                        typeCounts[item.equipment_type] = (typeCounts[item.equipment_type] || 0) + 1;
                    });

                    const typeLabels = Object.keys(typeCounts);
                    const typeData = Object.values(typeCounts);

                    createChart(document.getElementById('healthChart'), 'bar', labels, health, 'Health Score', 'rgba(59, 130, 246, 0.6)');
                    createChart(document.getElementById('usageChart'), 'bar', labels, usage, 'Usage Hours', 'rgba(16, 185, 129, 0.6)');
                    createChart(document.getElementById('typeChart'), 'pie', typeLabels, typeData, 'Equipment Count', ['#3b82f6', '#10b981', '#f97316', '#8b5cf6', '#ec4899']);
                }
            });
        </script>
    </body>
    </html>""")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOL
              
              # Train the model
              python3 models/train.py
              
              # Start the application
              nohup python3 api/app.py &
              
              echo "Application deployed successfully"
              EOF
              
              # Create requirements.txt
              cat > requirements.txt << 'EOL'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pandas==2.1.3
scikit-learn==1.3.2
joblib==1.3.2
prometheus-client==0.19.0
boto3==1.34.0
pydantic==2.5.0
EOL
              
              # Install Python dependencies
              pip3 install -r requirements.txt
              
              # Create models directory and train script
              mkdir -p models
              cat > models/train.py << 'EOL'
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import joblib
import os

# Create sample data
data = {
    'sensor1': [1.2, 2.1, 1.8, 3.2, 2.5, 1.9, 2.8, 1.5, 3.1, 2.3],
    'sensor2': [0.8, 1.5, 1.2, 2.1, 1.8, 1.3, 2.0, 0.9, 2.2, 1.6],
    'sensor3': [45.2, 52.1, 48.5, 61.2, 55.8, 49.3, 58.9, 46.7, 63.1, 53.4],
    'failure': [0, 0, 0, 1, 0, 0, 1, 0, 1, 0]
}

df = pd.DataFrame(data)

# Split features and target
X = df[['sensor1', 'sensor2', 'sensor3']]
y = df['failure']

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# Save model
os.makedirs('models', exist_ok=True)
joblib.dump(model, 'models/model.pkl')
print("Model trained and saved successfully")
EOL
              
              # Create API directory and app
              mkdir -p api
              cat > api/app.py << 'EOL'
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import joblib
import pandas as pd
import boto3
import os
import csv
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
import time

app = FastAPI()

# Load model
try:
    model = joblib.load("models/model.pkl")
except:
    model = None

# AWS Configuration
AWS_REGION = os.getenv('AWS_REGION', 'ap-south-1')
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')

# CloudWatch client
cloudwatch_client = boto3.client(
    'cloudwatch',
    region_name=AWS_REGION,
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'http_status'])
PREDICTION_REQUESTS = Counter('prediction_requests_total', 'Total prediction requests')
PREDICTION_FAILURES = Counter('prediction_failures_total', 'Total prediction failures')
PREDICTION_DURATION = Histogram('prediction_duration_seconds', 'Prediction duration')

# Equipment health metrics
EQUIPMENT_HEALTH = Gauge('equipment_health_score', 'Equipment health score', ['equipment_type', 'equipment_id'])
EQUIPMENT_USAGE = Gauge('equipment_usage_hours', 'Equipment usage hours', ['equipment_type', 'equipment_id'])

class PredictRequest(BaseModel):
    sensor1: float
    sensor2: float
    sensor3: float

def publish_metric(namespace, metric_name, value, dimensions=None, unit='Count'):
    try:
        metric_data = {
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Timestamp': time.time()
        }
        if dimensions:
            metric_data['Dimensions'] = dimensions
        
        cloudwatch_client.put_metric_data(
            Namespace=namespace,
            MetricData=[metric_data]
        )
    except Exception as e:
        print(f"Failed to publish metric: {e}")

# Load equipment data
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
EQUIPMENT_CSV = os.path.join(DATA_DIR, "hospital_equipment.csv")

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
                
                # Publish metrics to CloudWatch
                publish_metric('PredictiveMaintenance', 'HospitalEquipmentHealthScore', row["health_score"], 
                             [{'Name': 'EquipmentType', 'Value': row["equipment_type"]},
                              {'Name': 'EquipmentId', 'Value': row["equipment_id"]}], 'None')
                publish_metric('PredictiveMaintenance', 'HospitalEquipmentUsageHours', row["usage_hours"],
                             [{'Name': 'EquipmentType', 'Value': row["equipment_type"]},
                              {'Name': 'EquipmentId', 'Value': row["equipment_id"]}], 'Count')
    return equipment

EQUIPMENT_DATA = load_equipment_data()

class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        duration = time.time() - start_time
        
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.url.path,
            http_status=str(response.status_code)
        ).inc()
        
        return response

app.add_middleware(PrometheusMiddleware)

@app.get("/")
def home():
    return {"message": "Predictive Maintenance API running"}

@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    return HTMLResponse("""
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
        </style>
    </head>
    <body>
        <header>
            <h1>Hospital Equipment Monitoring</h1>
            <p class="small">Live metrics dashboard for hospital systems.</p>
        </header>

        <div class="grid">
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
            <div class="card">
                <h2>API Endpoints</h2>
                <p class="small">Dashboard: <code>/dashboard</code></p>
                <p class="small">Equipment Data: <code>/equipment</code></p>
                <p class="small">Metrics: <code>/metrics</code></p>
                <p class="small">Prediction: <code>POST /predict</code></p>
            </div>
        </div>

        <div class="card" style="margin-top: 24px;">
            <h2>Equipment Status Table</h2>
            <div id="tableContainer">Loading equipment data...</div>
        </div>

        <script>
            async function loadEquipment() {
                try {
                    const response = await fetch('/equipment');
                    const json = await response.json();
                    return json.equipment;
                } catch (err) {
                    document.getElementById('tableContainer').innerHTML = 'Error loading data: ' + err.message;
                    return [];
                }
            }

            function renderTable(items) {
                if (items.length === 0) {
                    document.getElementById('tableContainer').innerHTML = 'No equipment data available';
                    return;
                }
                
                let rows = '';
                items.forEach(item => {
                    const status = item.failure === 1 ? 'WARNING' : 'OK';
                    rows += '<tr>' +
                        '<td>' + item.equipment_id + '</td>' +
                        '<td>' + item.equipment_type + '</td>' +
                        '<td>' + item.location + '</td>' +
                        '<td>' + item.usage_hours + '</td>' +
                        '<td>' + item.health_score + '</td>' +
                        '<td>' + status + '</td>' +
                    '</tr>';
                });
                
                document.getElementById('tableContainer').innerHTML = 
                    '<table>' +
                        '<thead><tr>' +
                            '<th>ID</th><th>Type</th><th>Location</th><th>Usage</th><th>Health</th><th>Status</th>' +
                        '</tr></thead>' +
                        '<tbody>' + rows + '</tbody>' +
                    '</table>';
            }

            function createChart(ctx, type, labels, data, label, backgroundColor) {
                return new Chart(ctx, {
                    type: type,
                    data: {
                        labels: labels,
                        datasets: [{
                            label: label,
                            data: data,
                            backgroundColor: backgroundColor,
                            borderColor: '#3b82f6',
                            borderWidth: 1,
                        }],
                    },
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true,
                            },
                        },
                    },
                });
            }

            loadEquipment().then(items => {
                renderTable(items);
                
                if (items.length > 0) {
                    const labels = items.map(i => i.equipment_id);
                    const health = items.map(i => i.health_score);
                    const usage = items.map(i => i.usage_hours);

                    const typeCounts = {};
                    items.forEach(item => {
                        typeCounts[item.equipment_type] = (typeCounts[item.equipment_type] || 0) + 1;
                    });

                    const typeLabels = Object.keys(typeCounts);
                    const typeData = Object.values(typeCounts);

                    createChart(document.getElementById('healthChart'), 'bar', labels, health, 'Health Score', 'rgba(59, 130, 246, 0.6)');
                    createChart(document.getElementById('usageChart'), 'bar', labels, usage, 'Usage Hours', 'rgba(16, 185, 129, 0.6)');
                    createChart(document.getElementById('typeChart'), 'pie', typeLabels, typeData, 'Equipment Count', ['#3b82f6', '#10b981', '#f97316', '#8b5cf6', '#ec4899']);
                }
            });
        </script>
    </body>
    </html>""")

@app.get('/equipment')
def equipment_data():
    return {'equipment': EQUIPMENT_DATA, 'count': len(EQUIPMENT_DATA)}       

@app.get('/metrics')
def metrics():
    return generate_latest()

@app.post('/predict')
def predict(data: PredictRequest):
    if model is None:
        raise HTTPException(status_code=503, detail='Model file not found; train the model first.')
    
    start_time = time.time()
    PREDICTION_REQUESTS.inc()
    
    values = [data.sensor1, data.sensor2, data.sensor3]
    prediction = model.predict([values])[0]
    
    duration = time.time() - start_time
    PREDICTION_DURATION.observe(duration)
    
    if prediction == 1:
        PREDICTION_FAILURES.inc()
        publish_metric('PredictiveMaintenance', 'HospitalDeviceFailurePredicted', 1, [], 'Count')
        return {"failure": 1, "alert": "⚠️ Failure likely!"}
    
    publish_metric('PredictiveMaintenance', 'HospitalDeviceFailurePredicted', 0, [], 'Count')
    return {"failure": 0}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOL
              
              # Create data directory and CSV
              mkdir -p data
              cat > data/hospital_equipment.csv << 'EOL'
equipment_id,equipment_type,location,usage_hours,temperature,vibration,health_score,failure
MRI-001,MRI,Room 101,1450.5,68.2,0.25,0.92,0
CT-001,CT Scanner,Room 102,1200.8,65.1,0.18,0.88,0
VENT-001,Ventilator,ICU 1,2100.2,72.5,0.45,0.65,1
ECG-001,ECG Machine,Emergency,800.3,58.9,0.12,0.95,0
XRAY-001,X-Ray,Room 105,980.7,69.8,0.22,0.89,0
ANES-001,Anesthesia Machine,OR 1,1650.4,71.3,0.38,0.78,0
LAB-001,Lab Analyzer,Lab 1,450.6,62.4,0.15,0.96,0
INFU-001,Infusion Pump,Ward A,320.9,55.7,0.08,0.98,0
US-001,Ultrasound,Room 108,750.1,64.2,0.19,0.91,0
DEFIB-001,Defibrillator,Emergency,280.4,57.8,0.11,0.97,0
MRI-002,MRI,Room 103,1680.9,70.1,0.31,0.85,0
CT-002,CT Scanner,Room 104,1350.6,66.8,0.26,0.87,0
VENT-002,Ventilator,ICU 2,1950.7,73.9,0.52,0.58,1
ECG-002,ECG Machine,Ward B,620.8,59.6,0.14,0.94,0
XRAY-002,X-Ray,Room 106,1120.3,68.7,0.28,0.86,0
ANES-002,Anesthesia Machine,OR 2,1420.1,72.8,0.41,0.72,1
LAB-002,Lab Analyzer,Lab 2,380.5,61.9,0.13,0.97,0
INFU-002,Infusion Pump,Ward C,410.2,56.3,0.09,0.99,0
US-002,Ultrasound,Room 109,890.4,63.5,0.21,0.90,0
DEFIB-002,Defibrillator,Emergency,195.6,58.1,0.10,0.98,0
EOL
              
              # Train the model
              python3 models/train.py
              
              # Start the application
              nohup python3 api/app.py &
              
              echo "Application deployed successfully"
EOF

  tags = {
    Name = "Predictive-Maintenance-System"
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "predictive-maintenance-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "FastAPI application"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "predictive-maintenance-sg"
  }
}

resource "aws_cloudwatch_metric_alarm" "device_failure_alert" {
  alarm_name          = "PredictiveMaintenance-DeviceFailureAlert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HospitalDeviceAlerts"
  namespace           = "PredictiveMaintenance"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when a device failure is predicted"
  alarm_actions       = [aws_sns_topic.device_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "low_health_score" {
  alarm_name          = "PredictiveMaintenance-LowHealthScore"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HospitalEquipmentHealthScore"
  namespace           = "PredictiveMaintenance"
  period              = 300
  statistic           = "Average"
  threshold           = 0.80
  alarm_description   = "Alert when equipment health falls below 80%"
  alarm_actions       = [aws_sns_topic.device_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_dashboard" "app_dashboard" {
  dashboard_name = "PredictiveMaintenanceDashboard"

  dashboard_body = <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["PredictiveMaintenance", "HospitalEquipmentHealthScore"]
        ],
        "region": "ap-south-1",
        "title": "Equipment Health Scores"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["PredictiveMaintenance", "HospitalEquipmentUsageHours"]
        ],
        "region": "ap-south-1",
        "title": "Equipment Usage Hours"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["PredictiveMaintenance", "HospitalDeviceFailurePredicted"],
          ["PredictiveMaintenance", "HospitalDeviceAlerts"]
        ],
        "region": "ap-south-1",
        "title": "Device Failure Alerts"
      }
    }
  ]
}
DASHBOARD
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for device alerts"
  value       = aws_sns_topic.device_alerts.arn
}

output "sns_subscription_arn" {
  description = "SNS subscription ARN (check email to confirm)"
  value       = aws_sns_topic_subscription.device_alerts_email.arn
}
