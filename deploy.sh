#!/bin/bash
# Predictive Maintenance System - EC2 Quick Start Deployment

set -e

echo "==================================="
echo "Predictive Maintenance EC2 Deployment"
echo "==================================="
echo ""

# Update system
echo "📦 Step 1: Installing system packages..."
sudo yum update -y > /dev/null 2>&1
sudo yum install python3-pip git -y > /dev/null 2>&1
echo "✅ System packages installed"

# Install Python dependencies
echo ""
echo "📦 Step 2: Installing Python dependencies..."
pip3 install --upgrade pip > /dev/null 2>&1
cd ~/predictive-maintenance || cd ~/app || exit 1
pip3 install -r requirements.txt > /dev/null 2>&1
echo "✅ Python dependencies installed"

# Train model if needed
echo ""
echo "🤖 Step 3: Checking ML model..."
if [ ! -f "models/model.pkl" ]; then
  echo "   Training model (first time)..."
  python3 models/train.py
  echo "✅ Model trained successfully"
else
  echo "✅ Model already exists"
fi

# Start FastAPI app
echo ""
echo "🚀 Step 4: Starting FastAPI application..."
nohup python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &
sleep 2

# Verify app is running
if curl -s http://localhost:8000/ > /dev/null; then
  echo "✅ Application is running!"
else
  echo "❌ Application failed to start. Check app.log"
  cat app.log
  exit 1
fi

echo ""
echo "==================================="
echo "✅ DEPLOYMENT COMPLETE"
echo "==================================="
echo ""
echo "Your application is now live! 🎉"
echo ""
echo "📊 Access Points:"
echo "   Frontend Dashboard: http://<YOUR_EC2_IP>:8000/dashboard"
echo "   API Endpoint:       http://<YOUR_EC2_IP>:8000/predict"
echo "   Metrics:            http://<YOUR_EC2_IP>:8000/metrics"
echo "   Equipment Data:     http://<YOUR_EC2_IP>:8000/equipment"
echo ""
echo "📋 Next Steps:"
echo "   1. Note your EC2 public IP address"
echo "   2. Open frontend dashboard in browser"
echo "   3. Check CloudWatch console for metrics"
echo "   4. Follow AWS_SETUP_GUIDE.md for full setup"
echo ""
echo "📝 View logs:"
echo "   tail -f ~/predictive-maintenance/app.log"


log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi

    # Check Ansible
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install it first."
        exit 1
    fi

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    log_success "All dependencies are installed."
}

setup_aws() {
    log_info "Checking AWS configuration..."

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    log_success "AWS CLI is configured."
}

setup_ssh_key() {
    log_info "Checking SSH key..."

    if [ ! -f "$KEY_FILE" ]; then
        log_error "SSH key not found at $KEY_FILE"
        log_info "Please ensure your predictive-maintenance.pem key is at $KEY_FILE"
        exit 1
    fi

    chmod 600 "$KEY_FILE"
    log_success "SSH key configured."
}

terraform_deploy() {
    log_info "Starting Terraform deployment..."

    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init

    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate

    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -out=tfplan

    # Apply deployment
    log_info "Applying deployment..."
    terraform apply tfplan

    # Get outputs
    EC2_IP=$(terraform output -raw ec2_public_ip)
    log_success "EC2 instance created with IP: $EC2_IP"

    cd "$PROJECT_DIR"
}

update_inventory() {
    log_info "Updating Ansible inventory..."

    # Update inventory.ini with the new EC2 IP
    sed -i.bak "s/43\.205\.126\.47/$EC2_IP/g" "$INVENTORY_FILE"
    sed -i.bak "s|~/predictive-maintenance.pem|$KEY_FILE|g" "$INVENTORY_FILE"

    log_success "Inventory updated."
}

ansible_deploy() {
    log_info "Starting Ansible deployment..."

    cd "$TERRAFORM_DIR"

    # Test connectivity
    log_info "Testing SSH connectivity..."
    ansible -i inventory.ini -m ping servers

    # Run playbook
    log_info "Running Ansible playbook..."
    ansible-playbook -i inventory.ini setup.yml

    log_success "Server configuration completed."

    cd "$PROJECT_DIR"
}

transfer_files() {
    log_info "Transferring project files to EC2..."

    # Create remote directory and transfer files
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "mkdir -p predictive-maintenance"

    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r . "$EC2_USER@$EC2_IP:~/predictive-maintenance/"

    log_success "Files transferred successfully."
}

deploy_application() {
    log_info "Deploying application..."

    # Install dependencies
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "cd predictive-maintenance && pip3 install -r requirements.txt"

    # Run application
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "cd predictive-maintenance && nohup python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &"

    log_success "Application deployed and started."
}

test_deployment() {
    log_info "Testing deployment..."

    # Wait for application to start
    sleep 10

    # Test health endpoint
    if curl -s "http://$EC2_IP:8000/" > /dev/null; then
        log_success "Health check passed!"
    else
        log_error "Health check failed!"
        exit 1
    fi

    # Test prediction endpoint
    RESPONSE=$(curl -s -X POST "http://$EC2_IP:8000/predict" \
        -H "Content-Type: application/json" \
        -d '{"sensor1": 100, "sensor2": 200, "sensor3": 150}')

    if echo "$RESPONSE" | grep -q "failure"; then
        log_success "Prediction API working!"
    else
        log_error "Prediction API failed!"
        exit 1
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    # Add cleanup commands if needed
}

main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Predictive Maintenance Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"

    # Run deployment steps
    check_dependencies
    setup_aws
    setup_ssh_key
    terraform_deploy
    update_inventory
    ansible_deploy
    transfer_files
    deploy_application
    test_deployment
    cleanup

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Completed Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "🌐 API Endpoint: ${BLUE}http://$EC2_IP:8000/${NC}"
    echo -e "🔑 SSH Access: ${BLUE}ssh -i $KEY_FILE $EC2_USER@$EC2_IP${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Visit the API endpoint to test the application"
    echo "2. Check the deployment documentation for more details"
    echo "3. Monitor the application logs if needed"
}

# Handle command line arguments
case "${1:-}" in
    "test")
        if [ -z "$EC2_IP" ]; then
            log_error "EC2_IP not set. Run full deployment first."
            exit 1
        fi
        test_deployment
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        main
        ;;
esac