#!/bin/bash
# Deploy nvim-secscan using Terraform

set -e

cd terraform

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform not installed"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS CLI not configured. Run 'aws configure'"
    exit 1
fi

# Get parameters
read -p "Enter EC2 Key Pair name: " KEY_PAIR
read -p "Enter AWS region (us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter instance type (t3.micro): " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.micro}

read -p "Enter GitHub token (optional): " GITHUB_TOKEN

# Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_region     = "$AWS_REGION"
key_pair_name  = "$KEY_PAIR"
instance_type  = "$INSTANCE_TYPE"
github_token   = "$GITHUB_TOKEN"
EOF

echo "Initializing Terraform..."
terraform init

echo "Planning deployment..."
terraform plan

echo "Applying deployment..."
terraform apply -auto-approve

echo ""
echo "Deployment complete!"
echo "SSH to instance and run: ./setup-nvim-secscan.sh"

# Show outputs
terraform output