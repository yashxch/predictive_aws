# TERRAFORM SETUP - Quick Checklist

## Before Running Terraform

### 1. Update Your Email for Alerts
Edit this file: `devops/main.tf`

Find this line (around line 30):
```hcl
variable "alert_email" {
  description = "Email for device failure alerts"
  type        = string
  default     = "admin@example.com"  # ← CHANGE THIS
}
```

Replace `"admin@example.com"` with YOUR email:
```hcl
default     = "your-email@company.com"
```

---

## Running Terraform (One-Time Setup)

### On Your Local Machine:

```bash
# 1. Navigate to devops folder
cd devops

# 2. Initialize Terraform
terraform init

# 3. Review what will be created
terraform plan

# 4. Create AWS resources (IAM, SNS, CloudWatch, Dashboard, Alarms)
terraform apply

# Type: yes
# Wait 2-3 minutes...
```

### What Terraform Creates:

✅ **IAM Role** - Allows your EC2 to send metrics to CloudWatch  
✅ **SNS Topic** - Receives device failure notifications  
✅ **SNS Subscription** - Sends alerts to your email  
✅ **CloudWatch Dashboard** - Visual monitoring  
✅ **CloudWatch Alarms** - Triggers alerts when problems occur  

---

## After Terraform Completes

### Step 1: Check Email
- AWS SNS will send you a **Confirm Subscription** email
- **Click the confirmation link** (usually takes 1-2 minutes)
- ✅ Subscription confirmed!

### Step 2: Note Your Outputs
Terraform will print outputs like:
```
ec2_public_ip = "43.205.126.47"
sns_topic_arn = "arn:aws:sns:ap-south-1:123456..."
```

Copy these for reference.

### Step 3: Deploy App to EC2
SSH into your EC2 instance:
```bash
ssh -i predictive-maintenance.pem ec2-user@<YOUR_EC2_IP>

# Then run:
bash ~ec2-user/deploy.sh
# or
cd ~/predictive-maintenance && bash deploy.sh
```

---

## Verify Setup in AWS Console

### 1. CloudWatch Dashboard
- AWS Console → **CloudWatch** → **Dashboards**
- Click **"PredictiveMaintenanceDashboard"**
- Should show empty charts (will fill once app sends data)

### 2. SNS Topic
- AWS Console → **SNS** → **Topics**
- Check: **"predictive-maintenance-device-alerts"** exists
- Check Subscriptions tab: shows your email

### 3. CloudWatch Alarms
- AWS Console → **CloudWatch** → **Alarms**
- Should see 2 alarms:
  - `PredictiveMaintenance-DeviceFailureAlert`
  - `PredictiveMaintenance-LowHealthScore`

### 4. App Running
- Open browser: `http://<YOUR_EC2_IP>:8000/dashboard`
- Should see equipment table with data

---

## Troubleshooting

### Terraform Error: "Permission Denied"
- Ensure AWS credentials are configured locally
- Run: `aws sts get-caller-identity`
- Should show your AWS account ID

### Terraform Error: "IAM Role Already Exists"
- Role already created by previous run
- Run: `terraform destroy` then `terraform apply` again
- Or manually delete role in AWS console

### No Email Confirmation?
- Check spam folder
- Resend: AWS Console → SNS → Subscriptions → right-click → Resend confirmation

---

## Destroy Resources (Cleanup)

To delete everything and stop charges:

```bash
cd devops
terraform destroy
# Type: yes
```

This will:
- Delete EC2 security group configuration
- Delete IAM role and policy
- Delete SNS topic and subscriptions
- Delete CloudWatch dashboard and alarms

⚠️ **Note:** Does NOT delete your EC2 instance itself (you must terminate separately)

---

For more details, see: **AWS_SETUP_GUIDE.md**
