@echo off
REM Predictive Maintenance System - Automated Deployment Script
REM For Windows systems

setlocal enabledelayedexpansion

REM Colors for output (Windows CMD)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

REM Configuration
set "PROJECT_DIR=%~dp0"
set "TERRAFORM_DIR=%PROJECT_DIR%devops"
set "INVENTORY_FILE=%TERRAFORM_DIR%\inventory.ini"
set "KEY_FILE=%USERPROFILE%\predictive-maintenance.pem"
set "EC2_USER=ec2-user"

REM Functions
:log_info
echo %BLUE%[INFO]%RESET% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%RESET% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%RESET% %~1
goto :eof

:log_error
echo %RED%[ERROR]%RESET% %~1
goto :eof

:check_dependencies
call :log_info "Checking dependencies..."

REM Check Terraform
terraform version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Terraform is not installed. Please install it first."
    exit /b 1
)

REM Check Ansible (via pip)
python -c "import ansible" >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Ansible is not installed. Please run: pip install ansible"
    exit /b 1
)

REM Check AWS CLI
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "AWS CLI is not installed. Please install it first."
    exit /b 1
)

call :log_success "All dependencies are installed."
goto :eof

:setup_aws
call :log_info "Checking AWS configuration..."

aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "AWS CLI is not configured. Please run 'aws configure' first."
    exit /b 1
)

call :log_success "AWS CLI is configured."
goto :eof

:setup_ssh_key
call :log_info "Checking SSH key..."

if not exist "%KEY_FILE%" (
    call :log_error "SSH key not found at %KEY_FILE%"
    call :log_info "Please ensure your predictive-maintenance.pem key is at %KEY_FILE%"
    exit /b 1
)

REM Note: Windows permissions are handled differently
call :log_success "SSH key found."
goto :eof

:terraform_deploy
call :log_info "Starting Terraform deployment..."

cd /d "%TERRAFORM_DIR%"

REM Initialize Terraform
call :log_info "Initializing Terraform..."
terraform init
if %errorlevel% neq 0 exit /b 1

REM Validate configuration
call :log_info "Validating Terraform configuration..."
terraform validate
if %errorlevel% neq 0 exit /b 1

REM Plan deployment
call :log_info "Planning deployment..."
terraform plan -out=tfplan
if %errorlevel% neq 0 exit /b 1

REM Apply deployment
call :log_info "Applying deployment..."
terraform apply tfplan
if %errorlevel% neq 0 exit /b 1

REM Get outputs
for /f "tokens=*" %%i in ('terraform output -raw ec2_public_ip') do set EC2_IP=%%i
call :log_success "EC2 instance created with IP: %EC2_IP%"

cd /d "%PROJECT_DIR%"
goto :eof

:update_inventory
call :log_info "Updating Ansible inventory..."

REM Update inventory.ini with the new EC2 IP
powershell -Command "(Get-Content '%INVENTORY_FILE%') -replace '43\.205\.126\.47', '%EC2_IP%' | Set-Content '%INVENTORY_FILE%'"
powershell -Command "(Get-Content '%INVENTORY_FILE%') -replace '~/predictive-maintenance.pem', '%KEY_FILE%' | Set-Content '%INVENTORY_FILE%'"

call :log_success "Inventory updated."
goto :eof

:ansible_deploy
call :log_info "Starting Ansible deployment..."

cd /d "%TERRAFORM_DIR%"

REM Test connectivity
call :log_info "Testing SSH connectivity..."
ansible -i inventory.ini -m ping servers
if %errorlevel% neq 0 (
    call :log_error "SSH connectivity test failed."
    exit /b 1
)

REM Run playbook
call :log_info "Running Ansible playbook..."
ansible-playbook -i inventory.ini setup.yml
if %errorlevel% neq 0 exit /b 1

call :log_success "Server configuration completed."

cd /d "%PROJECT_DIR%"
goto :eof

:transfer_files
call :log_info "Transferring project files to EC2..."

REM Create remote directory and transfer files
ssh -i "%KEY_FILE%" -o StrictHostKeyChecking=no "%EC2_USER%@%EC2_IP%" "mkdir -p predictive-maintenance"

if %errorlevel% neq 0 (
    call :log_error "Failed to create remote directory."
    exit /b 1
)

REM Use scp to transfer files (may need WSL or Git Bash)
where scp >nul 2>&1
if %errorlevel% equ 0 (
    scp -i "%KEY_FILE%" -o StrictHostKeyChecking=no -r . "%EC2_USER%@%EC2_IP%:~/predictive-maintenance/"
) else (
    call :log_warning "SCP not found. Please use WSL or Git Bash for file transfer."
    call :log_info "Manual command: scp -i '%KEY_FILE%' -o StrictHostKeyChecking=no -r . %EC2_USER%@%EC2_IP%:~/predictive-maintenance/"
    goto :eof
)

if %errorlevel% neq 0 (
    call :log_error "File transfer failed."
    exit /b 1
)

call :log_success "Files transferred successfully."
goto :eof

:deploy_application
call :log_info "Deploying application..."

REM Install dependencies
ssh -i "%KEY_FILE%" -o StrictHostKeyChecking=no "%EC2_USER%@%EC2_IP%" "cd predictive-maintenance && pip3 install -r requirements.txt"
if %errorlevel% neq 0 (
    call :log_error "Failed to install dependencies."
    exit /b 1
)

REM Run application
ssh -i "%KEY_FILE%" -o StrictHostKeyChecking=no "%EC2_USER%@%EC2_IP%" "cd predictive-maintenance && nohup python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &"
if %errorlevel% neq 0 (
    call :log_error "Failed to start application."
    exit /b 1
)

call :log_success "Application deployed and started."
goto :eof

:test_deployment
call :log_info "Testing deployment..."

REM Wait for application to start
timeout /t 10 /nobreak >nul

REM Test health endpoint
curl -s "http://%EC2_IP%:8000/" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Health check passed!"
) else (
    call :log_error "Health check failed!"
    exit /b 1
)

REM Test prediction endpoint
for /f "delims=" %%i in ('curl -s -X POST "http://%EC2_IP%:8000/predict" -H "Content-Type: application/json" -d "{\"sensor1\": 100, \"sensor2\": 200, \"sensor3\": 150}"') do set RESPONSE=%%i

echo %RESPONSE% | findstr "failure" >nul
if %errorlevel% equ 0 (
    call :log_success "Prediction API working!"
) else (
    call :log_error "Prediction API failed!"
    exit /b 1
)
goto :eof

:cleanup
call :log_info "Cleaning up temporary files..."
REM Add cleanup commands if needed
goto :eof

:main
echo %BLUE%========================================%RESET%
echo %BLUE%  Predictive Maintenance Deployment%RESET%
echo %BLUE%========================================%RESET%

REM Run deployment steps
call :check_dependencies
if %errorlevel% neq 0 exit /b 1

call :setup_aws
if %errorlevel% neq 0 exit /b 1

call :setup_ssh_key
if %errorlevel% neq 0 exit /b 1

call :terraform_deploy
if %errorlevel% neq 0 exit /b 1

call :update_inventory
if %errorlevel% neq 0 exit /b 1

call :ansible_deploy
if %errorlevel% neq 0 exit /b 1

call :transfer_files
if %errorlevel% neq 0 exit /b 1

call :deploy_application
if %errorlevel% neq 0 exit /b 1

call :test_deployment
if %errorlevel% neq 0 exit /b 1

call :cleanup

echo %GREEN%========================================%RESET%
echo %GREEN%  Deployment Completed Successfully!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo 🌐 API Endpoint: %BLUE%http://%EC2_IP%:8000/%RESET%
echo 🔑 SSH Access: %BLUE%ssh -i "%KEY_FILE%" %EC2_USER%@%EC2_IP%%RESET%
echo.
echo %YELLOW%Next steps:%RESET%
echo 1. Visit the API endpoint to test the application
echo 2. Check the deployment documentation for more details
echo 3. Monitor the application logs if needed
goto :eof

REM Handle command line arguments
if "%1"=="test" (
    if "%EC2_IP%"=="" (
        call :log_error "EC2_IP not set. Run full deployment first."
        exit /b 1
    )
    call :test_deployment
    goto :eof
)

if "%1"=="cleanup" (
    call :cleanup
    goto :eof
)

REM Default: run main deployment
call :main