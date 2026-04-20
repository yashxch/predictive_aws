# Predictive Maintenance System - Deployment Overview

## 🎯 Project Overview

A complete DevOps implementation of a Predictive Maintenance System using machine learning to predict equipment failures based on sensor data.

### Features
- **Machine Learning**: Scikit-learn model for failure prediction
- **Web API**: FastAPI-based REST API
- **Infrastructure as Code**: Terraform for AWS provisioning
- **Configuration Management**: Ansible for server setup
- **Containerization**: Docker for application deployment
- **Cloud Hosting**: AWS EC2 with security groups

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │ -> │    Ansible      │ -> │     Docker      │
│  (Infrastructure)│    │ (Configuration) │    │ (Containerization)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         v                       v                       v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     AWS EC2     │    │   Amazon Linux  │    │    FastAPI      │
│   (t3.micro)    │    │      2023       │    │      App        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- AWS Account
- Terraform installed
- Ansible installed
- AWS CLI configured
- SSH key pair

### One-Command Deployment
```bash
# 1. Provision infrastructure
cd devops && terraform init && terraform apply

# 2. Configure server
ansible-playbook -i inventory.ini setup.yml

# 3. Deploy application
scp -i ~/predictive-maintenance.pem -r . ec2-user@IP:~/app
ssh -i ~/predictive-maintenance.pem ec2-user@IP
pip3 install -r requirements.txt
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000
```

## 📋 API Endpoints

### Health Check
```
GET /
Response: {"message": "Predictive Maintenance API running"}
```

### Failure Prediction
```
POST /predict
Body: {"sensor1": 100, "sensor2": 200, "sensor3": 150}
Response: {"failure": 0} or {"failure": 1, "alert": "⚠️ Failure likely!"}
```

### Monitoring and Dashboard
```
GET /metrics      # Prometheus scrape endpoint
GET /dashboard    # Browser dashboard for hospital equipment metrics
GET /equipment    # JSON dataset for hospital equipment monitoring
```

The dashboard displays hospital device health scores, usage hours, and device status for equipment such as MRI, CT, X-Ray, ventilators, and more.

### AWS Console Monitoring
- ECS/EC2 instance will publish CloudWatch custom metrics for hospital equipment.
- `HospitalEquipmentHealthScore`, `HospitalEquipmentUsageHours`, `HospitalDeviceFailurePredicted`, and `HospitalDeviceAlerts` are published to CloudWatch.
- A CloudWatch dashboard named `PredictiveMaintenanceDashboard` is created by Terraform.

## 🔧 Configuration Files

### Terraform (`devops/main.tf`)
- EC2 instance provisioning
- Security group configuration
- Output variables

### Ansible (`devops/setup.yml`)
- Docker installation
- System configuration
- User permissions

### Application (`api/app.py`)
- FastAPI routes
- ML model integration
- Request/response handling

## 📊 Testing

### Manual Testing
```bash
# Health check
curl http://EC2_IP:8000/

# Prediction test
curl -X POST "http://EC2_IP:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}'
```

### Automated Testing
```bash
# Run unit tests
python3 -m pytest tests/

# Load testing
ab -n 1000 -c 10 http://EC2_IP:8000/
```

## 🔒 Security

### Network Security
- SSH access restricted (port 22)
- Application access on port 8000
- Security groups configured

### Application Security
- Input validation
- Error handling
- No sensitive data exposure

## 📈 Monitoring

### System Monitoring
- CloudWatch integration
- System resource monitoring
- Log aggregation

### Application Monitoring
- API response times
- Error rates
- Prediction accuracy

## 🛠️ Development

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python -m uvicorn api.app:app --reload

# Test endpoints
curl http://localhost:8000/
```

### Docker Development
```bash
# Build image
docker build -t predictive-maintenance .

# Run container
docker run -p 8000:8000 predictive-maintenance

# Debug container
docker run -it --entrypoint /bin/bash predictive-maintenance
```

## 📚 Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment instructions
- **[CHEATSHEET.md](CHEATSHEET.md)** - Quick reference commands
- **[TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md)** - Testing and debugging guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting guide
2. Review AWS console for instance status
3. Check application logs
4. Open an issue on GitHub

---

**Current Status**: ✅ Deployed and Running
**API Endpoint**: http://43.205.126.47:8000/
**Last Updated**: April 2024