terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "github_token" {
  description = "GitHub token for Security Advisory API"
  type        = string
  sensitive   = true
  default     = ""
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group
resource "aws_security_group" "nvim_secscan" {
  name_prefix = "nvim-secscan-"
  description = "Security group for nvim-secscan EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nvim-secscan-sg"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "nvim-secscan-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "nvim-secscan-role"
  }
}

# IAM Policy for S3 and Lambda access
resource "aws_iam_role_policy" "ec2_policy" {
  name = "nvim-secscan-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.reports.arn,
          "${aws_s3_bucket.reports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.alert_handler.arn
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "nvim-secscan-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# S3 Bucket for Reports
resource "aws_s3_bucket" "reports" {
  bucket = "nvim-secscan-reports-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name = "nvim-secscan-reports"
  }
}

resource "aws_s3_bucket_versioning" "reports_versioning" {
  bucket = aws_s3_bucket.reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "reports_pab" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lambda Role
resource "aws_iam_role" "lambda_role" {
  name = "nvim-secscan-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "alert_handler" {
  filename         = "alert_handler.zip"
  function_name    = "nvim-secscan-alert-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    Name = "nvim-secscan-alert"
  }
}

# Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "alert_handler.zip"
  source {
    content = <<EOF
import json
import boto3

def lambda_handler(event, context):
    print(f"Security Alert: {event.get('total_issues', 0)} issues found")
    print(f"Project: {event.get('project', 'unknown')}")
    print(f"Severity: {event.get('severity', 'unknown')}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Alert processed successfully')
    }
EOF
    filename = "index.py"
  }
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    s3_bucket       = aws_s3_bucket.reports.bucket
    lambda_function = aws_lambda_function.alert_handler.function_name
    github_token    = var.github_token
  }))
}

# EC2 Instance
resource "aws_instance" "nvim_secscan" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.nvim_secscan.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  
  user_data = local.user_data

  tags = {
    Name = "nvim-secscan-instance"
  }
}

# Outputs
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.nvim_secscan.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_instance.nvim_secscan.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.nvim_secscan.public_ip}"
}

output "s3_bucket" {
  description = "S3 bucket for reports"
  value       = aws_s3_bucket.reports.bucket
}

output "lambda_function" {
  description = "Lambda function for alerts"
  value       = aws_lambda_function.alert_handler.function_name
}