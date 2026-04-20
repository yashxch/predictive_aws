# Predictive Maintenance System - Complete Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Predictive Maintenance System using Terraform, Ansible, Docker, and AWS EC2.

## Architecture
- **Infrastructure**: AWS EC2 t3.micro instance (Amazon Linux 2023)
- **Configuration Management**: Ansible
- **Containerization**: Docker
- **Application**: FastAPI with scikit-learn ML model
- **Region**: Asia Pacific (Mumbai) - ap-south-1

## Prerequisites
- AWS Account with EC2 permissions
- Terraform installed
- Ansible installed
- AWS CLI configured
- SSH key pair created in AWS

## Step 1: Infrastructure Provisioning (Terraform)

### 1.1 Initialize Terraform
```bash
cd devops
terraform init
```

### 1.2 Plan the Deployment
```bash
terraform plan
```

### 1.3 Apply the Configuration
```bash
terraform apply
```

### 1.4 Get Instance Details
```bash
terraform output ec2_public_ip
terraform output ssh_command
```

## Step 2: Server Configuration (Ansible)

### 2.1 Update Inventory File
Edit `devops/inventory.ini`:
```ini
[servers]
43.205.126.47 ansible_user=ec2-user ansible_ssh_private_key_file=~/predictive-maintenance.pem

[servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### 2.2 Run Ansible Playbook
```bash
ansible-playbook -i inventory.ini setup.yml
```

## Step 3: Application Deployment

### 3.1 Transfer Project Files
```bash
scp -i ~/predictive-maintenance.pem -r . ec2-user@EC2_IP:~/predictive-maintenance
```

### 3.2 Install Dependencies
```bash
# On EC2 instance
pip3 install -r requirements.txt
```

### 3.3 Run the Application
```bash
# Direct execution
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000

# Or using Docker
docker build -t predictive-maintenance .
docker run -d -p 8000:8000 predictive-maintenance
```

## Step 4: Testing and Verification

### 4.1 Health Check
```bash
curl http://EC2_IP:8000/
```

### 4.2 Prediction Test
```bash
curl -X POST "http://EC2_IP:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}'
```

## Security Configuration

### Security Groups
- SSH (22): Open to 0.0.0.0/0 (restrict in production)
- Application (8000): Open to 0.0.0.0/0

### SSH Access
```bash
ssh -i ~/predictive-maintenance.pem ec2-user@EC2_IP
```

## Troubleshooting

### Common Issues
1. **SSH Permission Denied**: Check key permissions (`chmod 600 key.pem`)
2. **Ansible Connection Failed**: Verify inventory.ini configuration
3. **Docker Not Running**: `sudo systemctl start docker`
4. **Port Not Accessible**: Check security groups

### Logs
```bash
# Application logs
docker logs <container_id>

# System logs
sudo journalctl -u docker
```

## Production Considerations

### Security Hardening
- Restrict SSH access to specific IPs
- Use IAM roles instead of access keys
- Implement SSL/TLS
- Regular security updates

### Monitoring
- CloudWatch for infrastructure monitoring
- Application performance monitoring
- Log aggregation

### Backup Strategy
- AMI snapshots for infrastructure
- Database backups (if applicable)
- Configuration backups

## Cost Optimization
- Use spot instances for development
- Auto-scaling groups for production
- Reserved instances for long-term usage

## Cleanup
```bash
# Destroy infrastructure
terraform destroy

# Remove Docker resources
docker system prune -a
```

## Support
For issues, check:
1. AWS Console for instance status
2. CloudWatch logs
3. Application logs
4. Network connectivity

---
*Last updated: April 2024*