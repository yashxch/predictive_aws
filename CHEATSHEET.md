# Predictive Maintenance - Quick Reference Cheatsheet

## 🚀 Quick Deployment Commands

### Infrastructure (Terraform)
```bash
cd devops
terraform init
terraform plan
terraform apply
terraform output ec2_public_ip
terraform destroy
```

### Configuration (Ansible)
```bash
ansible-playbook -i inventory.ini setup.yml -v
ansible -i inventory.ini -m ping servers
```

### Application Deployment
```bash
# Transfer files
scp -i ~/predictive-maintenance.pem -r . ec2-user@IP:~/app

# Install dependencies
pip3 install -r requirements.txt

# Run application
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000

# Docker deployment
docker build -t predictive-maintenance .
docker run -d -p 8000:8000 predictive-maintenance
```

## 🔧 Troubleshooting Commands

### SSH Issues
```bash
# Fix key permissions
chmod 600 ~/predictive-maintenance.pem

# Test connection
ssh -i ~/predictive-maintenance.pem ec2-user@IP -v

# Copy key to WSL
cp /mnt/c/Users/youruser/Downloads/predictive-maintenance.pem ~/predictive-maintenance.pem
chmod 600 ~/predictive-maintenance.pem
```

### Docker Issues
```bash
# Check Docker status
sudo systemctl status docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker ec2-user
newgrp docker

# Clean up
docker system prune -a
docker images
docker ps -a
```

### Network Issues
```bash
# Check ports
netstat -tlnp | grep 8000
curl http://localhost:8000/

# Firewall check
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=8000/tcp --permanent
sudo firewall-cmd --reload
```

### Application Issues
```bash
# Check Python packages
python3 -c "import fastapi, uvicorn, joblib, sklearn; print('All imports OK')"

# Test model loading
python3 -c "import joblib; model = joblib.load('models/model.pkl'); print('Model loaded')"

# Check logs
docker logs <container_id>
journalctl -u docker -f
```

## 📊 API Testing

### Health Check
```bash
curl http://IP:8000/
# Expected: {"message": "Predictive Maintenance API running"}
```

### Prediction Test
```bash
curl -X POST "http://IP:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}'
# Expected: {"failure": 0} or {"failure": 1, "alert": "⚠️ Failure likely!"}
```

### Load Testing
```bash
# Simple load test
for i in {1..10}; do
  curl -s "http://IP:8000/" > /dev/null && echo "Request $i: OK"
done
```

## 🏗️ Infrastructure Management

### AWS CLI Commands
```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-xxxxx

# Get public IP
aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].PublicIpAddress'

# Security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### Terraform Commands
```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Show state
terraform show

# Import existing resources
terraform import aws_instance.app_server i-xxxxx
```

## 📁 File Structure
```
predictive-maintenance/
├── api/
│   └── app.py                 # FastAPI application
├── models/
│   └── model.pkl             # Trained ML model
├── data/
│   └── data.csv              # Training data
├── preprocessing/
│   └── preprocess.py         # Data preprocessing
├── devops/
│   ├── main.tf               # Terraform config
│   ├── setup.yml             # Ansible playbook
│   └── inventory.ini         # Ansible inventory
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Docker config
└── docs/                     # Documentation
```

## 🔒 Security Checklist

- [ ] SSH key permissions: `chmod 600 key.pem`
- [ ] Security group restricts SSH to known IPs
- [ ] No sensitive data in code
- [ ] Environment variables for secrets
- [ ] Regular system updates
- [ ] Firewall configured
- [ ] SELinux/AppArmor enabled

## 📈 Monitoring Commands

### System Resources
```bash
# CPU/Memory usage
top
htop

# Disk usage
df -h
du -sh *

# Network connections
netstat -tlnp
ss -tlnp
```

### Application Monitoring
```bash
# Process check
ps aux | grep uvicorn
ps aux | grep docker

# Port check
lsof -i :8000

# Logs
tail -f /var/log/docker.log
docker logs -f <container_name>
```

## 🆘 Emergency Commands

### Stop Everything
```bash
# Stop application
pkill -f uvicorn
docker stop $(docker ps -q)

# Stop services
sudo systemctl stop docker

# Terminate instance
aws ec2 terminate-instances --instance-ids i-xxxxx
```

### Quick Recovery
```bash
# Restart services
sudo systemctl restart docker
cd predictive-maintenance
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000 &
```

## 📞 Support Information

**Current Setup:**
- EC2 IP: 43.205.126.47
- Region: ap-south-1 (Mumbai)
- AMI: Amazon Linux 2023
- Instance Type: t3.micro

**Key Files:**
- PEM Key: `~/predictive-maintenance.pem`
- Terraform State: `devops/terraform.tfstate`
- Ansible Inventory: `devops/inventory.ini`

---
*Quick Reference - Predictive Maintenance Deployment*