#!/bin/bash
# Setup AWS integration for nvim-secscan

echo "Setting up AWS integration for nvim-secscan..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Installing..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

echo "✅ AWS CLI configured"

# Create S3 bucket for reports
read -p "Enter S3 bucket name for security reports: " BUCKET_NAME
if [ ! -z "$BUCKET_NAME" ]; then
    aws s3 mb s3://$BUCKET_NAME 2>/dev/null || echo "Bucket may already exist"
    echo "✅ S3 bucket: $BUCKET_NAME"
fi

# Create Lambda function
read -p "Enter Lambda function name for alerts: " LAMBDA_NAME
if [ ! -z "$LAMBDA_NAME" ]; then
    cat > /tmp/lambda-function.py << 'EOF'
import json
import boto3

def lambda_handler(event, context):
    print(f"Security Alert: {event['total_issues']} HIGH severity issues found")
    print(f"Project: {event['project']}")
    print(f"Timestamp: {event['timestamp']}")
    
    # Add your notification logic here
    # e.g., send to SNS, Slack, email, etc.
    
    return {
        'statusCode': 200,
        'body': json.dumps('Alert processed successfully')
    }
EOF

    zip /tmp/lambda-function.zip /tmp/lambda-function.py
    
    aws lambda create-function \
        --function-name $LAMBDA_NAME \
        --runtime python3.9 \
        --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
        --handler lambda_function.lambda_handler \
        --zip-file fileb:///tmp/lambda-function.zip \
        2>/dev/null || echo "Lambda function may already exist"
    
    rm /tmp/lambda-function.py /tmp/lambda-function.zip
    echo "✅ Lambda function: $LAMBDA_NAME"
fi

# Generate Neovim configuration
cat << EOF

📝 Add this to your Neovim configuration:

require("nvim-secscan").setup({
  s3_bucket = "$BUCKET_NAME",
  lambda_function = "$LAMBDA_NAME",
  -- other config options...
})

🚀 Usage:
  :SecScanReport    # Generate report
  :SecScanUpload    # Upload to S3 and trigger Lambda

EOF

echo "✅ AWS integration setup complete!"