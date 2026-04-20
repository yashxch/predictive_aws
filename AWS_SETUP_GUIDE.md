# AWS Setup Guide - Hospital Equipment Monitoring

## Quick Summary
- **App**: Sends metrics to AWS CloudWatch every time it loads equipment data
- **Alarms**: Automatic notifications when devices fail or health drops below 80%
- **Dashboard**: Visual monitoring in AWS console
- **Email Alerts**: Get notified instantly of device problems

---

## STEP 1: Connect to Your EC2 Instance (SSH)

```bash
# On your local machine (PowerShell, Mac Terminal, etc.)
ssh -i predictive-maintenance.pem ec2-user@<YOUR_EC2_IP>
```

**Find YOUR_EC2_IP:**
- AWS Console → EC2 → Instances
- Select your instance → Copy the "Public IPv4 address"

---

## STEP 2: Install Python & Dependencies

```bash
# SSH into EC2, then run:
sudo yum update -y
sudo yum install python3-pip git -y
pip3 install --upgrade pip

# Install project dependencies
cd ~/predictive-maintenance  # or wherever you cloned it
pip3 install -r requirements.txt
```

---

## STEP 3: Train the ML Model (Optional, if not already trained)

```bash
cd ~/predictive-maintenance
python3 models/train.py
# Output: "Model trained successfully" + accuracy scores
```

---

## STEP 4: Start the Application

```bash
cd ~/predictive-maintenance
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000
# Output: "Uvicorn running on 0.0.0.0:8000"
```

✅ **App is now publishing metrics to CloudWatch!**

---

## STEP 5: View Dashboard in AWS Console

### Option A: CloudWatch Dashboard (Recommended)

1. Go to **AWS Console** → **CloudWatch** → **Dashboards**
2. Find and click **"PredictiveMaintenanceDashboard"**
3. You should see:
   - Equipment Health Scores (line chart)
   - Equipment Usage Hours (line chart)
   - Device Failure Alerts (red line when problems occur)

⏱️ **Note:** Metrics appear 1-2 minutes after app startup.

### Option B: View Raw Metrics

1. Go to **CloudWatch** → **Metrics** → **Custom Namespaces**
2. Select **"PredictiveMaintenance"**
3. Expand and see all metrics:
   - `HospitalEquipmentHealthScore`
   - `HospitalEquipmentUsageHours`
   - `HospitalEquipmentTemperature`
   - `HospitalEquipmentVibration`
   - `HospitalDeviceAlerts`
   - `HospitalDeviceFailurePredicted`
   - `PredictionAccuracy`

---

## STEP 6: Set Up Email Alerts

### Confirm SNS Subscription (Do This First!)

1. **Check your email** (the one you used as `alert_email` in Terraform)
2. Look for email from AWS SNS
3. **Click the confirmation link**
4. ✅ Subscription confirmed!

### Test Alert

```bash
# SSH into EC2, then send a test alert:
aws sns publish \
  --topic-arn arn:aws:sns:ap-south-1:YOUR_ACCOUNT_ID:predictive-maintenance-device-alerts \
  --message "Test alert" \
  --region ap-south-1
```

You'll get an email within 30 seconds.

---

## STEP 7: View Alarms

1. Go to **CloudWatch** → **Alarms**
2. You should see:
   - ✅ `PredictiveMaintenance-DeviceFailureAlert` (fires when failure predicted)
   - ✅ `PredictiveMaintenance-LowHealthScore` (fires when health < 80%)

### When Do Alarms Trigger?

- **DeviceFailureAlert**: When `/predict` endpoint returns `failure=1`
- **LowHealthScore**: When average equipment health score drops below 0.80

---

## STEP 8: Access Frontend Dashboard (Local Browser)

Open in your browser:
```
http://<YOUR_EC2_IP>:8000/dashboard
```

You'll see:
- Real-time equipment status table
- Health score charts
- Problem device alerts (highlighted in red)
- Live data from `data/hospital_equipment.csv`

---

## STEP 9: Test the Prediction API

```bash
# From your local machine:
curl -X POST "http://<YOUR_EC2_IP>:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{"sensor1": 95, "sensor2": 90, "sensor3": 88}'

# Response: {"failure": 0} or {"failure": 1, "alert": "⚠️ Failure likely!"}
```

Each prediction:
- Logs to `stdout` (visible in terminal)
- Publishes `PredictionAccuracy` metric to CloudWatch
- May trigger `DeviceFailureAlert` if failure detected

---

## STEP 10: Update Email for Alerts

Edit `devops/main.tf`:

```hcl
variable "alert_email" {
  description = "Email for device failure alerts"
  type        = string
  default     = "your-email@company.com"  # ← Change this
}
```

Then re-run Terraform:

```bash
cd devops
terraform plan
terraform apply
# Confirm the apply, then check new email for subscription confirmation
```

---

## Troubleshooting

### Metrics Not Showing?

```bash
# SSH into EC2 and check:

# 1. Is app running?
curl http://localhost:8000/equipment

# 2. Does EC2 have the IAM role?
aws iam list-instance-profiles-for-role predictive-maintenance-ec2-role

# 3. Can boto3 connect to CloudWatch?
python3 -c "import boto3; print(boto3.client('cloudwatch', region_name='ap-south-1').list_metrics(Namespace='PredictiveMaintenance'))"
```

### Email Not Received?

1. Check AWS Console → SNS → Subscriptions
2. Look for status: "PendingConfirmation" (needs email confirmation)
3. Check spam folder for AWS confirmation email
4. Re-run subscription confirmation

### Alarm Not Sending Email?

1. Go to CloudWatch → Alarms
2. Click alarm → "View in metrics"
3. Check if metric data is flowing
4. Wait 2-3 minutes for first alarm trigger

---

## Metrics Reference

| Metric | Unit | Range | Meaning |
|--------|------|-------|---------|
| `HospitalEquipmentHealthScore` | 0-1 | 0.80-0.99 | Device health (higher=better) |
| `HospitalEquipmentUsageHours` | hours | 400-2100 | How long device has been running |
| `HospitalEquipmentTemperature` | °C | 54-75 | Operating temperature |
| `HospitalEquipmentVibration` | 0-1 | 0.12-0.50 | Vibration levels (lower=better) |
| `HospitalDeviceAlerts` | count | 0-1 | 1 when device needs attention |
| `HospitalDeviceFailurePredicted` | count | 0+ | Number of failed predictions |
| `PredictionAccuracy` | 0-1 | 0 or 1 | 1=correct prediction, 0=no failure |

---

## Useful AWS Console Shortcuts

| Task | Steps |
|------|-------|
| **Stop/Restart App** | SSH → Ctrl+C → `python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000` |
| **View App Logs** | CloudWatch → Logs (when app logs enabled) |
| **Test Metric** | SSH → `aws cloudwatch get-metric-statistics --namespace PredictiveMaintenance --metric-name HospitalEquipmentHealthScore --start-time $(date -u -d '-10 minutes' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average --region ap-south-1` |
| **Delete Dashboard** | CloudWatch → Dashboards → Delete (if recreating) |
| **View All Alarms** | CloudWatch → Alarms (see all alarm states) |

---

## Next Steps (Optional)

- Add Grafana for advanced alerting and custom dashboards
- Set up CloudWatch Logs for application debugging
- Create SNS SMS alerts for critical failures
- Integrate with PagerDuty for on-call notifications

---

## Support

All metrics are sent automatically from the app to CloudWatch. No manual steps needed once the app is running!

If metrics aren't appearing, check the **Troubleshooting** section above.
