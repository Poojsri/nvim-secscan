#!/bin/bash
yum update -y

# Install dependencies
yum install -y git curl python3 python3-pip nodejs npm unzip

# Install Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
mv nvim.appimage /usr/local/bin/nvim

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install security tools
pip3 install bandit requests

# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Set environment variables
echo "export S3_BUCKET=${s3_bucket}" >> /home/ec2-user/.bashrc
echo "export LAMBDA_FUNCTION=${lambda_function}" >> /home/ec2-user/.bashrc
echo "export GITHUB_TOKEN=${github_token}" >> /home/ec2-user/.bashrc

# Create nvim-secscan project directly
cd /home/ec2-user
mkdir -p nvim-secscan
cd nvim-secscan

# Create minimal working version
cat > nvim-secscan << 'NVIM_EOF'
#!/usr/bin/env python3
import json
import sys
import subprocess
import requests
from pathlib import Path

def show_banner():
    print("="*60)
    print("    NVIM-SECSCAN - Security Scanner v1.0")
    print("    Code & Dependency Vulnerability Detection")
    print("="*60)

def query_osv_api(package, version=None):
    query = {"package": {"name": package, "ecosystem": "PyPI"}}
    if version:
        query["version"] = version
    try:
        response = requests.post("https://api.osv.dev/v1/query", json=query, timeout=10)
        return response.json()
    except:
        return None

def parse_requirements(req_file):
    packages = []
    try:
        with open(req_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.replace('>=', '==').split('==')
                    pkg = parts[0].strip()
                    version = parts[1].strip() if len(parts) > 1 else None
                    packages.append((pkg, version))
    except:
        pass
    return packages

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ['-h', '--help']:
        show_banner()
        print("\nUsage: nvim-secscan <file>")
        print("Example: nvim-secscan app.py")
        return
    
    show_banner()
    filepath = Path(sys.argv[1])
    results = {"vulnerabilities": [], "code_issues": []}
    
    if filepath.suffix == ".py":
        req_file = filepath.parent / "requirements.txt"
        if req_file.exists():
            for pkg, version in parse_requirements(req_file):
                osv_data = query_osv_api(pkg, version)
                if osv_data and osv_data.get("vulns"):
                    for vuln in osv_data["vulns"]:
                        results["vulnerabilities"].append({
                            "package": pkg,
                            "id": vuln.get("id"),
                            "summary": vuln.get("summary")
                        })
    
    if "--format" in sys.argv and "text" in sys.argv:
        total = len(results["vulnerabilities"])
        print(f"\nFound {total} vulnerabilities:")
        for vuln in results["vulnerabilities"]:
            print(f"  - {vuln['package']}: {vuln['id']}")
            if vuln['summary']:
                print(f"    {vuln['summary']}")
    else:
        print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
NVIM_EOF

chmod +x nvim-secscan
cp nvim-secscan /usr/local/bin/

# Create test script
cat > /home/ec2-user/test-nvim-secscan.sh << 'TEST_EOF'
#!/bin/bash
echo "Testing nvim-secscan..."
mkdir -p ~/test-project
cd ~/test-project

cat > app.py << 'APP_EOF'
import os
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    os.system('ls')  # Security issue
    return "Hello"
APP_EOF

cat > requirements.txt << 'REQ_EOF'
flask==0.12.2
requests==2.6.0
REQ_EOF

echo "Testing CLI:"
nvim-secscan --format text app.py
TEST_EOF

chmod +x /home/ec2-user/test-nvim-secscan.sh
chown -R ec2-user:ec2-user /home/ec2-user/