# 🚀 Cloud Deployment Guide for nvim-secscan

## Prerequisites

1. **AWS Account** with CLI configured
2. **EC2 Key Pair** created in your region
3. **Basic AWS permissions** (EC2, S3, Lambda, IAM)

## Quick Start (5 minutes)

### Option 1: CloudFormation (Recommended)

```bash
# 1. Navigate to deploy directory
cd deploy

# 2. Run quick deploy script
chmod +x quick-deploy.sh
./quick-deploy.sh

# 3. Enter your EC2 Key Pair name when prompted
# 4. Wait for deployment (2-3 minutes)
```

### Option 2: Manual CloudFormation

```bash
# 1. Create stack
aws cloudformation create-stack \
    --stack-name nvim-secscan-test \
    --template-body file://cloudformation/nvim-secscan-ec2.yaml \
    --parameters ParameterKey=KeyPairName,ParameterValue=YOUR_KEY_PAIR \
    --capabilities CAPABILITY_IAM

# 2. Wait for completion
aws cloudformation wait stack-create-complete --stack-name nvim-secscan-test

# 3. Get public IP
aws cloudformation describe-stacks \
    --stack-name nvim-secscan-test \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
    --output text
```

## Testing the Deployment

### 1. SSH to Instance

```bash
# Use the IP from deployment output
ssh -i YOUR_KEY_PAIR.pem ec2-user@PUBLIC_IP
```

### 2. Run Test Script

```bash
# On the EC2 instance
./test-nvim-secscan.sh
```

### 3. Manual Testing

```bash
# Test CLI directly
nvim-secscan --help
nvim-secscan --format text ~/test-project/app.py

# Check for vulnerabilities
cd ~/test-project
nvim-secscan app.py | jq '.vulnerabilities | length'
```

## Expected Results

✅ **CLI Scanner Working**
- Banner displays correctly
- Finds vulnerabilities in Flask 0.12.2
- JSON and text output formats work

✅ **Dependencies Detected**
- Parses requirements.txt
- Queries OSV.dev API successfully
- Returns vulnerability data

✅ **AWS Integration Ready**
- S3 bucket created
- Lambda function deployed
- IAM permissions configured

## Troubleshooting

### Common Issues

1. **"Key pair not found"**
   - Ensure key pair exists in the correct region
   - Check key pair name spelling

2. **"Permission denied"**
   - Verify AWS credentials: `aws sts get-caller-identity`
   - Check IAM permissions for EC2, S3, Lambda

3. **"Connection timeout"**
   - Check security group allows SSH (port 22)
   - Verify your IP is allowed

### Debug Commands

```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=nvim-secscan-instance"

# View user data logs
sudo tail -f /var/log/cloud-init-output.log

# Test network connectivity
curl -I https://api.osv.dev/v1/query
```

## Cleanup

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name nvim-secscan-test

# Or use the stack name from quick-deploy output
aws cloudformation delete-stack --stack-name nvim-secscan-test-TIMESTAMP
```

## Cost Estimate

- **EC2 t3.micro**: ~$0.0116/hour (~$8.50/month)
- **S3 storage**: ~$0.023/GB/month
- **Lambda**: Pay per invocation
- **Total for testing**: ~$0.50/day

## Next Steps

1. **Test Neovim Integration**: Open files with `nvim` and use `:SecScan`
2. **Test AWS Features**: Try `:SecScanUpload` to upload reports to S3
3. **Customize Configuration**: Modify scanner settings and thresholds
4. **Scale Up**: Use larger instance types for production workloads

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudFormation events in the console
3. SSH to the instance and check logs
4. Verify all prerequisites are met