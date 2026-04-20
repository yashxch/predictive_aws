# AWS Console Operations Guide

## Simple AWS Console Steps - No Command Line Needed

After Terraform runs and your app is deployed, follow these steps in AWS console.

---

## 1️⃣ Verify Email Subscription (Do This First!)

**Location:** SNS → Topics

1. **AWS Console** → Type "SNS" in search box → Click **Simple Notification Service**
2. Click **Topics** (left sidebar)
3. Find **"predictive-maintenance-device-alerts"**
   - If not visible, Terraform failed - check local `terraform apply` output
4. Click on the topic name
5. Scroll to **Subscriptions** section
6. Check if status shows: **PendingConfirmation** or **Confirmed**

**If PendingConfirmation:**
- ❌ Email NOT yet confirmed
- Check spam folder for "AWS Notification"
- Click "Confirm subscription" link in email
- Refresh page → Status should change to **Confirmed** ✅

---

## 2️⃣ View Metrics Dashboard

**Location:** CloudWatch → Dashboards

1. **AWS Console** → Type "CloudWatch" → Click **CloudWatch**
2. Left sidebar → Click **Dashboards**
3. Look for **"PredictiveMaintenanceDashboard"** in the list
4. Click it to open
5. Should show 3 sections:
   - **Equipment Health Scores** (top left)
   - **Equipment Usage Hours** (top right)
   - **Device Failure Alerts** (bottom)

**First time:** Charts will be empty (metrics take 1-2 minutes after app starts)  
**After app runs:** Charts will show real-time data

---

## 3️⃣ Check Your Alarms

**Location:** CloudWatch → Alarms

1. **AWS Console** → **CloudWatch**
2. Left sidebar → Click **Alarms**
3. Should see **2 alarms**:
   - ✅ `PredictiveMaintenance-DeviceFailureAlert`
   - ✅ `PredictiveMaintenance-LowHealthScore`

4. Click each alarm to see:
   - Current state (OK = green light, ALARM = red light)
   - Threshold (>1 alert, or <0.80 health)
   - Action (sends to SNS topic)

**Normal state:** Both should show as **IN_SUFFICIENT_DATA** (becomes green/OK once metrics arrive)

---

## 4️⃣ View All Metrics

**Location:** CloudWatch → Metrics

1. **AWS Console** → **CloudWatch**
2. Left sidebar → Click **Metrics**
3. Click **Custom namespaces**
4. Find **"PredictiveMaintenance"**
5. Expand it → See all 7 metrics:
   - `HospitalEquipmentHealthScore`
   - `HospitalEquipmentUsageHours`
   - `HospitalEquipmentTemperature`
   - `HospitalEquipmentVibration`
   - `HospitalDeviceAlerts`
   - `HospitalDeviceFailurePredicted`
   - `PredictionAccuracy`

6. Click any metric to see **time series graph** of values over time

---

## 5️⃣ Test Alert System

### Make Email Alert Fire

**Without command line:** Just load your app's predict endpoint multiple times:

1. Open browser: `http://YOUR_EC2_IP:8000/predict` 
   - Error (expected, needs POST)

2. Open another browser tab: `http://YOUR_EC2_IP:8000/dashboard`
   - Look at table: Find any device with `failure=1`
   - (Pre-loaded in sample data: VENT-001, VENT-002, ANES-002)

3. When app loads, it publishes those alerts to CloudWatch
4. CloudWatch triggers alarm → SNS sends email ✉️

**Check email:** Within 1-2 minutes

---

## 6️⃣ Monitor in Real-Time

**Setup:** Open multiple AWS console tabs

**Tab 1 - Dashboard:**
- CloudWatch → Dashboards → PredictiveMaintenanceDashboard
- Refresh every 30 seconds to see new data

**Tab 2 - Metrics:**
- CloudWatch → Metrics → PredictiveMaintenance
- Click line chart to zoom into data

**Tab 3 - Alarms:**
- CloudWatch → Alarms
- Verify no alarms are firing (stay green)

---

## 7️⃣ Check Application Logs

**Location:** CloudWatch → Logs (if enabled)

*Note: Requires additional configuration to enable app logs*

For now, check logs on EC2 via SSH:
```bash
ssh -i key.pem ec2-user@IP
tail -f ~/predictive-maintenance/app.log
```

---

## 8️⃣ Toggle Notifications

**Stop Getting Alerts:**
1. **SNS** → **Topics** → **predictive-maintenance-device-alerts**
2. Click **Subscriptions**
3. Select your email subscription
4. Click **Delete** (red button)

**Re-Enable Alerts:**
1. **SNS** → **Topics** → **predictive-maintenance-device-alerts**
2. Click **Create subscription**
3. Protocol: **Email**
4. Endpoint: your email
5. **Create subscription**
6. Check email for confirmation link

---

## 9️⃣ Change Alert Email

**Edit Email Address:**

You need to update Terraform (command line):

```bash
# Local machine:
cd devops

# Edit main.tf - change this line:
default     = "newemail@company.com"

# Reapply:
terraform apply
```

Then confirm subscription in new email.

---

## 🔟 View EC2 Instance Status

**Location:** EC2 → Instances

1. **AWS Console** → Type "EC2" → **Elastic Compute Cloud**
2. Left sidebar → **Instances**
3. Find your instance
4. Check:
   - ✅ State: **Running** (green)
   - ✅ IAM role: **predictive-maintenance-instance-profile** (attached)
   - ✅ Security group: **predictive-maintenance-sg**
   - ✅ Public IP: Shows your IP address

---

## What Each Number Means

### Dashboard Metrics

- **Health Score 0.92** = Device is 92% healthy (good)
- **Usage Hours 1200** = Device has been running 1200 hours (3.3 days)
- **Temperature 72°C** = Operating temperature normal
- **Vibration 0.4** = Vibration levels normal (lower is better)

### Alarms

- **Green (OK)** = Everything normal
- **Red (ALARM)** = Problem detected, email sent
- **Gray (INSUFFICIENT_DATA)** = No metrics yet (wait 2-3 minutes)

---

## Troubleshooting in AWS Console

### Problem: No metrics showing
**Solution:**
1. Check EC2 instance is running (green status)
2. Verify app is running: Open `http://IP:8000/dashboard`
3. Wait 2-3 minutes (metrics have delay)
4. Refresh CloudWatch page (F5)

### Problem: Alarm is red  
**Solution:**
1. Check email - alert should have been sent
2. If no email, check SNS subscription status (must be "Confirmed")
3. Click alarm → View history to see what triggered it

### Problem: Email not received
**Solution:**
1. Go to **SNS** → **Topics** → Topic name
2. Check Subscriptions: Status should be "Confirmed"
3. If "PendingConfirmation", confirmation link didn't work
4. Re-send or create new subscription

### Problem: No EC2 instance
**Solution:**
1. Run `terraform apply` again (creates instance)
2. Wait 5 minutes for instance to start
3. Check State: Should be "Running"
4. Get Public IP from Instance details

---

## Quick Reference: AWS Console URLs

All links assume region: **ap-south-1**

- **Dashboards:** https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:
- **Alarms:** https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#alarmsV2:
- **Metrics:** https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#metricsV2:
- **SNS Topics:** https://ap-south-1.console.aws.amazon.com/sns/v3/home?region=ap-south-1#/topics
- **EC2 Instances:** https://ap-south-1.console.aws.amazon.com/ec2/v2/home?region=ap-south-1#Instances:

---

## One-Click Verification

✅ All metrics publishing → Check **Metrics** page (7 metrics visible)  
✅ Dashboard working → Check **Dashboards** page (charts populated)  
✅ Alarms working → Check **Alarms** page (2 alarms present)  
✅ Email working → Check **SNS Subscriptions** (shows "Confirmed")  

**If all 4 show ✅, everything is working!**
