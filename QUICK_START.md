# 🚀 Everything is Ready - Quick Start Guide

All backend, frontend, API calls, metrics, and AWS integration are **complete and ready to deploy**.

---

## What's Been Set Up For You

✅ **Frontend Dashboard** - Real-time equipment monitoring UI  
✅ **Prediction API** - `/predict` endpoint for ML inference  
✅ **CloudWatch Metrics** - All 7 hospital equipment metrics  
✅ **Email Alerts** - Automatic failure notifications to your email  
✅ **CloudWatch Dashboard** - Visual charts in AWS console  
✅ **CloudWatch Alarms** - Triggers alerts when problems occur  

---

## 3-Step Deployment (15 minutes total)

### STEP 1: Update Email & Run Terraform (Local Machine)

```bash
# 1. Edit devops/main.tf - Change this line:
#    default     = "your-email@company.com"

# 2. Deploy AWS infrastructure:
cd devops
terraform init
terraform apply
# Type: yes when prompted
```

**What this creates:**
- IAM role for your EC2 instance
- SNS topic for email alerts
- CloudWatch dashboard
- 2 CloudWatch alarms

**Check your email** for AWS SNS confirmation → **Click confirmation link**

---

### STEP 2: Deploy App to EC2 (On AWS)

```bash
# SSH into your EC2 instance:
ssh -i predictive-maintenance.pem ec2-user@<YOUR_EC2_IP>

# Run the deployment script:
bash ~/predictive-maintenance/deploy.sh
# (automatically installs packages, trains model, starts app)
```

✅ App is now running and sending metrics to CloudWatch!

---

### STEP 3: View Dashboard & Test

**Frontend Dashboard:**
```
http://<YOUR_EC2_IP>:8000/dashboard
```

**AWS CloudWatch Dashboard:**
1. Go to **AWS Console** → **CloudWatch** → **Dashboards**
2. Click **"PredictiveMaintenanceDashboard"**
3. See real-time metrics

---

## What Gets Published to AWS CloudWatch

| Metric | Publishes When | Value |
|--------|---|---|
| `HospitalEquipmentHealthScore` | App starts + every /predict | 0.84-0.99 |
| `HospitalEquipmentUsageHours` | App starts + equipment loaded | 400-2100 |
| `HospitalEquipmentTemperature` | App starts + equipment loaded | 54-75 |
| `HospitalEquipmentVibration` | App starts + equipment loaded | 0.12-0.50 |
| `HospitalDeviceAlerts` | Failure detected | 1 (triggers email) |
| `HospitalDeviceFailurePredicted` | /predict returns failure | 1 |
| `PredictionAccuracy` | /predict endpoint called | 0 or 1 |

---

## Testing Alerts (After Deployment)

### Test Email Alert

```bash
# SSH into EC2:
aws sns publish \
  --topic-arn arn:aws:sns:ap-south-1:ACCOUNT_ID:predictive-maintenance-device-alerts \
  --message "Test device failure alert" \
  --region ap-south-1
```

✅ You'll receive an email within 30 seconds

### Test Failure Prediction

```bash
curl -X POST "http://YOUR_EC2_IP:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{"sensor1": 95, "sensor2": 90, "sensor3": 88}'
```

Response: `{"failure": 0}` or `{"failure": 1, "alert": "⚠️ Failure likely!"}`

---

## Access Points After Deployment

| Service | URL |
|---------|-----|
| Frontend Dashboard | `http://YOUR_EC2_IP:8000/dashboard` |
| Equipment Data API | `http://YOUR_EC2_IP:8000/equipment` |
| Predictions API | `http://YOUR_EC2_IP:8000/predict` (POST) |
| Prometheus Metrics | `http://YOUR_EC2_IP:8000/metrics` |
| AWS CloudWatch | `AWS Console → CloudWatch → Dashboards` |

---

## AWS Console - What You'll See

### 1. Metrics in CloudWatch
- **CloudWatch** → **Metrics** → **PredictiveMaintenance**
- All 7 metrics listed with real-time data

### 2. Dashboard
- **CloudWatch** → **Dashboards** → **PredictiveMaintenanceDashboard**
- 3 charts showing health scores, usage hours, and alerts

### 3. Alarms
- **CloudWatch** → **Alarms**
- 2 alarms (both green when OK, red when triggered)

### 4. SNS Topic
- **SNS** → **Topics** → **predictive-maintenance-device-alerts**
- Subscription shows your email

---

## Logs & Debugging

### View App Logs (on EC2)

```bash
tail -f ~/predictive-maintenance/app.log
```

### Check Metrics Are Flowing

```bash
aws cloudwatch list-metrics \
  --namespace PredictiveMaintenance \
  --region ap-south-1
```

### Verify Equipment Data

```bash
curl http://localhost:8000/equipment | python -m json.tool
```

---

## Files Reference

- **AWS_SETUP_GUIDE.md** - Detailed step-by-step instructions  
- **TERRAFORM_SETUP.md** - Terraform configuration details  
- **deploy.sh** - Automatic EC2 deployment script  
- **devops/main.tf** - AWS infrastructure as code  
- **api/app.py** - FastAPI app with CloudWatch metrics  
- **data/hospital_equipment.csv** - Sample equipment data (20 devices)

---

## Summary - What Happens Automatically

1. **App loads** → Reads hospital_equipment.csv  
2. **Equipment data loaded** → Each device's metrics published to CloudWatch  
3. **Device with failure=1** → Alarm triggered → Email sent ✉️  
4. **Frontend opens** → Shows all equipment status in real-time  
5. **AWS Console** → CloudWatch displays all metrics graphically  

**No manual metric configuration needed - everything is automatic!**

---

## Next Steps After Deployment (Optional)

- Add more hospital devices to `data/hospital_equipment.csv`
- Set up SNS SMS for critical alerts
- Integrate with PagerDuty for on-call notifications
- Create custom CloudWatch dashboards
- Add Grafana for advanced alerting

---

## Support Checklist

- [ ] Terraform applied successfully with email confirmed
- [ ] App deployed to EC2 and running
- [ ] Frontend dashboard loads
- [ ] Metrics visible in CloudWatch (1-2 minute delay)
- [ ] Test alert email received
- [ ] Alarms visible in CloudWatch console

If any step fails, check **AWS_SETUP_GUIDE.md** troubleshooting section.

📧 **Everything is live and monitoring your hospital equipment!** 🏥
