#!/bin/bash
# Deploy nvim-secscan using CloudFormation

set -e

# Configuration
STACK_NAME="nvim-secscan-stack"
TEMPLATE_FILE="cloudformation/nvim-secscan-ec2.yaml"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS CLI not configured. Run 'aws configure'"
    exit 1
fi

# Get parameters
read -p "Enter EC2 Key Pair name: " KEY_PAIR
read -p "Enter instance type (t3.micro): " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.micro}

read -p "Enter GitHub token (optional): " GITHUB_TOKEN

echo "Deploying CloudFormation stack..."

# Deploy stack
aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        KeyPairName="$KEY_PAIR" \
        InstanceType="$INSTANCE_TYPE" \
        GitHubToken="$GITHUB_TOKEN" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION"

# Get outputs
echo "Getting stack outputs..."
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "Deployment complete!"
echo "SSH to instance and run: ./setup-nvim-secscan.sh"