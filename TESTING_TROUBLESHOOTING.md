# Testing & Troubleshooting Guide - Predictive Maintenance System

## 🧪 Testing Strategy

### Unit Testing
```bash
# Install test dependencies
pip install pytest pytest-cov

# Run unit tests
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=api --cov-report=html
```

### Integration Testing
```bash
# Test API endpoints
python test_api.py

# Test model predictions
python test_model.py

# Test Docker container
docker run --rm predictive-maintenance python -m pytest tests/
```

### Load Testing
```bash
# Apache Bench
ab -n 1000 -c 10 http://localhost:8000/

# Siege
siege -c 10 -t 30s http://localhost:8000/

# Locust (distributed)
locust -f locustfile.py
```

## 🔍 Troubleshooting Guide

### Infrastructure Issues

#### Terraform Problems
```bash
# Check state
terraform show

# Refresh state
terraform refresh

# Fix state issues
terraform state list
terraform state rm <resource>

# Debug mode
TF_LOG=DEBUG terraform apply
```

#### AWS Issues
```bash
# Check instance status
aws ec2 describe-instances --instance-ids i-xxxxx

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check key pairs
aws ec2 describe-key-pairs --key-names predictive-maintenance
```

### Configuration Issues

#### Ansible Problems
```bash
# Test connectivity
ansible -i inventory.ini -m ping servers

# Run with verbose output
ansible-playbook -i inventory.ini setup.yml -vvv

# Check facts
ansible -i inventory.ini -m setup servers

# Debug variables
ansible -i inventory.ini -m debug -a "var=hostvars[inventory_hostname]" servers
```

#### SSH Issues
```bash
# Test SSH connection
ssh -i ~/predictive-maintenance.pem ec2-user@IP -v

# Check key permissions
ls -la ~/predictive-maintenance.pem

# Fix permissions
chmod 600 ~/predictive-maintenance.pem

# Test from WSL
wsl ssh -i ~/predictive-maintenance.pem ec2-user@IP
```

### Application Issues

#### FastAPI Problems
```bash
# Check if app starts
python -c "from api.app import app; print('App imports OK')"

# Test model loading
python -c "import joblib; model = joblib.load('models/model.pkl'); print('Model loaded')"

# Check dependencies
python -c "import fastapi, uvicorn, sklearn, pandas; print('All imports OK')"
```

#### Docker Issues
```bash
# Check Docker status
sudo systemctl status docker

# View logs
docker logs <container_id>

# Debug container
docker run -it --entrypoint /bin/bash predictive-maintenance

# Check image
docker images
docker inspect predictive-maintenance

# Clean up
docker system prune -a
```

### Network Issues

#### Port Problems
```bash
# Check if port is open
netstat -tlnp | grep 8000

# Test local connection
curl http://localhost:8000/

# Check firewall
sudo firewall-cmd --list-all
sudo ufw status
```

#### Security Group Issues
```bash
# Check AWS security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Update security group (if needed)
aws ec2 authorize-security-group-ingress --group-id sg-xxxxx --protocol tcp --port 8000 --cidr 0.0.0.0/0
```

## 🐛 Common Issues & Solutions

### Issue 1: SSH Connection Failed
```
Error: Permission denied (publickey)
```
**Solutions:**
1. Check key permissions: `chmod 600 key.pem`
2. Verify key path in inventory.ini
3. Ensure correct username (ec2-user for Amazon Linux)
4. Test from WSL if using Windows

### Issue 2: Ansible Playbook Fails
```
Error: dnf: command not found
```
**Solutions:**
1. Verify OS (Amazon Linux uses dnf, Ubuntu uses apt)
2. Update inventory.ini with correct ansible_python_interpreter
3. Check SSH connectivity first

### Issue 3: Docker Not Running
```
Error: Cannot connect to Docker daemon
```
**Solutions:**
1. Start Docker: `sudo systemctl start docker`
2. Add user to docker group: `sudo usermod -aG docker $USER`
3. Restart session: `newgrp docker`

### Issue 4: Application Won't Start
```
ModuleNotFoundError: No module named 'fastapi'
```
**Solutions:**
1. Install dependencies: `pip install -r requirements.txt`
2. Check Python path
3. Verify virtual environment

### Issue 5: Model Loading Fails
```
FileNotFoundError: models/model.pkl
```
**Solutions:**
1. Check file exists: `ls -la models/`
2. Verify correct path in code
3. Check file permissions

### Issue 6: Port Already in Use
```
Error: [Errno 48] Address already in use
```
**Solutions:**
1. Kill existing process: `pkill -f uvicorn`
2. Find process: `lsof -i :8000`
3. Use different port

## 📊 Performance Testing

### Benchmarking
```bash
# API response time
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/

# Memory usage
python -c "import psutil; print(f'Memory: {psutil.virtual_memory().percent}%')"

# CPU usage
python -c "import psutil; print(f'CPU: {psutil.cpu_percent()}%')"
```

### Profiling
```bash
# Profile application
python -m cProfile -s time api/app.py

# Memory profiling
python -m memory_profiler api/app.py

# Line profiling
kernprof -l api/app.py
```

## 🔧 Debugging Tools

### Python Debugging
```python
# Add to code for debugging
import pdb; pdb.set_trace()

# Or use IPython
from IPython import embed; embed()
```

### Network Debugging
```bash
# TCP dump
sudo tcpdump -i eth0 port 8000

# Netcat testing
echo "test" | nc localhost 8000

# Telnet testing
telnet localhost 8000
```

### Log Analysis
```bash
# Application logs
tail -f /var/log/application.log

# System logs
journalctl -u predictive-maintenance -f

# Docker logs
docker logs -f <container_name>
```

## 🚨 Emergency Procedures

### Application Down
```bash
# Quick restart
sudo systemctl restart predictive-maintenance

# Manual start
cd /path/to/app
python -m uvicorn api.app:app --host 0.0.0.0 --port 8000 &

# Docker restart
docker restart <container_id>
```

### Server Unresponsive
```bash
# SSH access
ssh -i key.pem ec2-user@IP

# Reboot instance
aws ec2 reboot-instances --instance-ids i-xxxxx

# Force stop/start
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 start-instances --instance-ids i-xxxxx
```

### Data Loss
```bash
# Check backups
ls -la /backups/

# Restore from snapshot
aws ec2 create-instance --image-id ami-xxxxx --instance-type t3.micro

# Database recovery (if applicable)
pg_restore -d dbname /backups/db.dump
```

## 📈 Monitoring Setup

### Basic Monitoring
```bash
# System stats
top
htop
iostat -x 1
free -h

# Network stats
iftop
nload
```

### Advanced Monitoring
```bash
# Install monitoring tools
sudo dnf install htop iotop sysstat

# Set up log rotation
sudo dnf install logrotate
sudo logrotate /etc/logrotate.conf

# Configure CloudWatch agent
sudo dnf install amazon-cloudwatch-agent
```

## 📞 Support Checklist

Before contacting support, please provide:
- [ ] Terraform version: `terraform version`
- [ ] Ansible version: `ansible --version`
- [ ] Docker version: `docker --version`
- [ ] Python version: `python --version`
- [ ] OS version: `cat /etc/os-release`
- [ ] Error logs
- [ ] Steps to reproduce
- [ ] Current configuration files

## 🔗 Useful Links

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Docker Documentation](https://docs.docker.com)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2)

---
*Testing & Troubleshooting Guide - Predictive Maintenance System*