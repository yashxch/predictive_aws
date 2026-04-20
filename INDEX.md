# Predictive Maintenance System - Master Index

## 📚 Documentation Overview

This index provides quick access to all documentation for the Predictive Maintenance System deployment.

## 🎯 Quick Start
- **[README_DEPLOYMENT.md](README_DEPLOYMENT.md)** - Project overview and quick start guide
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment instructions
- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick reference commands and troubleshooting

## 📋 Detailed Documentation

### Deployment & Setup
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Comprehensive deployment guide
- **[DEPLOYMENT_FLOW.md](DEPLOYMENT_FLOW.md)** - Visual deployment workflow and diagrams
- **[README_DEPLOYMENT.md](README_DEPLOYMENT.md)** - Project overview and architecture

### Testing & Troubleshooting
- **[TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md)** - Testing strategies and debugging guide
- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick commands and fixes

## 🏗️ Infrastructure Configuration

### Terraform
- **File**: `devops/main.tf`
- **Purpose**: AWS EC2 infrastructure provisioning
- **Resources**: EC2 instance, security groups, outputs

### Ansible
- **File**: `devops/setup.yml`
- **Purpose**: Server configuration and Docker installation
- **Target**: Amazon Linux 2023 (dnf-based)

### Inventory
- **File**: `devops/inventory.ini`
- **Purpose**: Ansible host configuration
- **Current IP**: 43.205.126.47 (ec2-user)

## 🐳 Application Configuration

### API Application
- **File**: `api/app.py`
- **Framework**: FastAPI
- **Endpoints**: `/` (health), `/predict` (predictions)

### Machine Learning
- **File**: `models/model.pkl`
- **Library**: scikit-learn
- **Purpose**: Equipment failure prediction

### Dependencies
- **File**: `requirements.txt`
- **Key Packages**: fastapi, uvicorn, scikit-learn, pandas, joblib

### Docker
- **File**: `Dockerfile`
- **Base Image**: python:3.10
- **Port**: 8000

## 🔧 Scripts & Automation

### Deployment Scripts
- **File**: `deploy.sh` - Linux/Mac deployment script
- **File**: `deploy.bat` - Windows deployment script
- **Purpose**: Automated deployment execution

## 📊 Current Status

### Infrastructure
- **Provider**: AWS EC2
- **Region**: Asia Pacific (Mumbai) - ap-south-1
- **Instance Type**: t3.micro
- **AMI**: Amazon Linux 2023 (ami-048f4445314bcaa09)
- **Public IP**: 43.205.126.47

### Application
- **Status**: Deployed and Running ✅
- **API Endpoint**: http://43.205.126.47:8000/
- **Health Check**: Available
- **Prediction API**: Functional

### Security
- **SSH Key**: predictive-maintenance.pem
- **Security Groups**: Configured (ports 22, 8000)
- **User**: ec2-user (Amazon Linux)

## 🚀 Quick Commands

### Infrastructure
```bash
cd devops
terraform init && terraform apply
terraform output ec2_public_ip
```

### Configuration
```bash
ansible-playbook -i inventory.ini setup.yml
```

### Deployment
```bash
scp -i ~/predictive-maintenance.pem -r . ec2-user@43.205.126.47:~/predictive-maintenance
ssh -i ~/predictive-maintenance.pem ec2-user@43.205.126.47
cd predictive-maintenance
pip3 install -r requirements.txt
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000
```

### Testing
```bash
curl http://43.205.126.47:8000/
curl -X POST "http://43.205.126.47:8000/predict" -H "Content-Type: application/json" -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}'
```

## 📁 Project Structure
```
predictive-maintenance/
├── 📄 DEPLOYMENT_GUIDE.md          # Complete deployment guide
├── 📄 CHEATSHEET.md                # Quick reference
├── 📄 README_DEPLOYMENT.md         # Project overview
├── 📄 DEPLOYMENT_FLOW.md           # Visual workflow
├── 📄 TESTING_TROUBLESHOOTING.md   # Testing & debugging
├── 📄 INDEX.md                     # This file
├── 📁 api/
│   └── 📄 app.py                   # FastAPI application
├── 📁 models/
│   └── 📄 model.pkl                # ML model
├── 📁 data/
│   └── 📄 data.csv                 # Training data
├── 📁 preprocessing/
│   └── 📄 preprocess.py            # Data processing
├── 📁 devops/
│   ├── 📄 main.tf                  # Terraform config
│   ├── 📄 setup.yml                # Ansible playbook
│   └── 📄 inventory.ini            # Ansible inventory
├── 📄 requirements.txt             # Python dependencies
├── 📄 Dockerfile                   # Docker config
├── 📄 deploy.sh                    # Linux deployment
└── 📄 deploy.bat                   # Windows deployment
```

## 🔍 Key Information

### API Endpoints
| Endpoint | Method | Description | Example |
|----------|--------|-------------|---------|
| `/` | GET | Health check | `{"message": "Predictive Maintenance API running"}` |
| `/predict` | POST | Failure prediction | `{"sensor1": 100, "sensor2": 200, "sensor3": 150}` |

### Response Formats
```json
// Health check response
{"message": "Predictive Maintenance API running"}

// Prediction response - No failure
{"failure": 0}

// Prediction response - Failure likely
{"failure": 1, "alert": "⚠️ Failure likely!"}
```

### Environment Variables
- None required (all configuration in code)

### Ports
- **22**: SSH access
- **8000**: FastAPI application

## 🆘 Troubleshooting Quick Reference

### Common Issues
1. **SSH Permission Denied** → Check key permissions: `chmod 600 key.pem`
2. **Ansible Fails** → Verify OS (Amazon Linux uses `dnf`, not `apt`)
3. **Docker Not Running** → Start service: `sudo systemctl start docker`
4. **Port Not Accessible** → Check security groups in AWS console
5. **Module Not Found** → Install dependencies: `pip3 install -r requirements.txt`

### Log Locations
- **Application**: Docker container logs
- **System**: `/var/log/messages`
- **Docker**: `journalctl -u docker`

## 📞 Support

### Current Configuration
- **EC2 Instance**: i-xxxxxxxxxxxxxxxxx
- **Region**: ap-south-1
- **Key Pair**: predictive-maintenance
- **Security Group**: predictive-maintenance-sg

### Contact Information
- **Status**: ✅ System Operational
- **Uptime**: Since deployment
- **Last Update**: April 9, 2024

---

*Master Index - Predictive Maintenance System Documentation*