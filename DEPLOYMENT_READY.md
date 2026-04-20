# Your Deployment Guide - Ready to Go! 🚀

**Email:** yc6155@srmist.edu.in  
**EC2 Instance IP:** 13.206.94.58  
**Region:** ap-south-1

---

## ✅ What's Already Set Up

Your Terraform configuration is ready with your email. Just 2 simple steps remaining.

---

## STEP 1: Deploy AWS Infrastructure (Local Machine)

Run from your project directory:

```bash
cd devops
terraform init
terraform apply
```

When prompted, type: `yes`

⏱️ Wait 3-5 minutes for infrastructure to be created

**Check Your Email:**
- 📧 You'll receive "AWS Notification - Subscription Confirmation"
- 🔗 Click the confirmation link (important!)
- Reply to AWS email to confirm subscription

---

## STEP 2: Deploy App to EC2

Open terminal and run:

```bash
ssh -i predictive-maintenance.pem ec2-user@13.206.94.58
```

Then on EC2, run:

```bash
cd ~/predictive-maintenance
bash deploy.sh
```

✅ App will start automatically and begin sending metrics to CloudWatch!

---

## 🎯 Access Your Dashboard

### Frontend Dashboard (Real-Time Equipment Status)
```
http://13.206.94.58:8000/dashboard
```

### AWS CloudWatch Dashboard
1. Open AWS Console
2. Go to **CloudWatch** → **Dashboards**
3. Click **"PredictiveMaintenanceDashboard"**
4. See your equipment health, usage hours, and alerts in real-time

### Test API

```bash
curl -X POST "http://13.206.94.58:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}'
```

Response:
```json
{"failure": 0}
```

---

## 📊 What You'll See in CloudWatch

### Metrics (Auto-Publishing)
- ✅ `HospitalEquipmentHealthScore` - Device health status
- ✅ `HospitalEquipmentUsageHours` - Device runtime
- ✅ `HospitalEquipmentTemperature` - Operating temperature
- ✅ `HospitalEquipmentVibration` - Vibration levels
- ✅ `HospitalDeviceAlerts` - Alert count (triggers emails!)
- ✅ `HospitalDeviceFailurePredicted` - Failure predictions
- ✅ `PredictionAccuracy` - Prediction correctness

### Alarms (Auto-Firing)
1. **PredictiveMaintenance-DeviceFailureAlert** - Emails you when device fails
2. **PredictiveMaintenance-LowHealthScore** - Emails you when health < 80%

---

## 📧 Email Alerts

**When you'll get emails:**
1. Device failure predicted
2. Equipment health drops below 80%
3. When you test the system

**All alerts go to:** yc6155@srmist.edu.in

---

## 🔍 Verify Everything is Working

### After app starts, check:

**1. Frontend Dashboard loads**
```
http://13.206.94.58:8000/dashboard
```
Should show table of 20 hospital devices

**2. CloudWatch Dashboard shows metrics**
- AWS Console → CloudWatch → Dashboards → PredictiveMaintenanceDashboard
- Should show 3 charts with data (wait 1-2 minutes after app starts)

**3. Alarms are active**
- AWS Console → CloudWatch → Alarms
- Should show 2 green alarms (OK status)

**4. Email subscription confirmed**
- AWS Console → SNS → Topics → predictive-maintenance-device-alerts
- Subscriptions tab should show your email with status "Confirmed" ✅

---

## 📋 Quick Troubleshooting

### Metrics not showing in CloudWatch?
```bash
# SSH to EC2 and check:
curl http://localhost:8000/equipment
# Should return JSON with 20 devices

# Check app is running:
ps aux | grep uvicorn
```

### Email not received?
- Check spam folder for "AWS Notification"
- Click confirmation link
- Wait 1-2 minutes for confirmation to process

### Can't SSH to instance?
```bash
# Verify security group allows SSH (port 22)
# Verify you have correct key file
# Check if instance is running (green status in EC2 console)
```

---

## 🎬 Demo Flow

1. **Open dashboard:** http://13.206.94.58:8000/dashboard
2. **See equipment table** - All 20 devices with their status
3. **Check AWS CloudWatch** - Real-time metrics
4. **Wait for email** - Alert notifications arrive automatically
5. **View alarms** - AWS console shows alarm status

---

## Key Information

| Item | Value |
|------|-------|
| Instance IP | 13.206.94.58 |
| Alert Email | yc6155@srmist.edu.in |
| Dashboard URL | http://13.206.94.58:8000/dashboard |
| Region | ap-south-1 |
| Namespace | PredictiveMaintenance |

---

## 🚀 You're Ready to Deploy!

### Complete Checklist:
- [ ] Run `terraform init && terraform apply` (local)
- [ ] Confirm email subscription (yc6155@srmist.edu.in)
- [ ] SSH to EC2 and run `bash deploy.sh`
- [ ] Wait 2-3 minutes for metrics to appear
- [ ] Open http://13.206.94.58:8000/dashboard
- [ ] Check AWS CloudWatch console
- [ ] Verify alarms are active

**Once all items are checked, your hospital equipment monitoring system is fully operational!**

📊 **The system is now monitoring 20 hospital devices in real-time**
📧 **You receive automatic email alerts for any device problems**
🔍 **All metrics visible in AWS CloudWatch dashboard**

Happy monitoring! 🏥
