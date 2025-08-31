#!/bin/bash
# Quick deployment script for testing nvim-secscan in cloud

set -e

echo "🚀 Quick Deploy nvim-secscan to AWS EC2"
echo "======================================"

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install: https://aws.amazon.com/cli/"
    exit 1
fi

if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS not configured. Run: aws configure"
    exit 1
fi

# Get user inputs
read -p "Enter your EC2 Key Pair name: " KEY_PAIR
read -p "Enter AWS region (us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

echo "✅ Using Key Pair: $KEY_PAIR"
echo "✅ Using Region: $AWS_REGION"

# Deploy using CloudFormation
STACK_NAME="nvim-secscan-test-$(date +%s)"
echo "📦 Deploying stack: $STACK_NAME"

aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://cloudformation/nvim-secscan-ec2.yaml \
    --parameters \
        ParameterKey=KeyPairName,ParameterValue="$KEY_PAIR" \
        ParameterKey=InstanceType,ParameterValue=t3.micro \
    --capabilities CAPABILITY_IAM \
    --region "$AWS_REGION"

echo "⏳ Waiting for stack creation..."
aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

# Get outputs
echo "📋 Getting connection details..."
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs')

PUBLIC_IP=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="PublicIP") | .OutputValue')
S3_BUCKET=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="S3Bucket") | .OutputValue')

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "Public IP: $PUBLIC_IP"
echo "S3 Bucket: $S3_BUCKET"
echo ""
echo "📝 Next Steps:"
echo "1. SSH: ssh -i $KEY_PAIR.pem ec2-user@$PUBLIC_IP"
echo "2. Run: ./setup-nvim-secscan.sh"
echo "3. Test: nvim-secscan --help"
echo ""
echo "🗑️  To cleanup: aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION"