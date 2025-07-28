#!/usr/bin/env python3
"""CLI bridge for nvim-secscan"""
import json
import sys
import subprocess
import requests
from pathlib import Path

def scan_with_bandit(filepath):
    try:
        result = subprocess.run(["bandit", "-f", "json", filepath], capture_output=True, text=True, check=False)
        return json.loads(result.stdout) if result.stdout else None
    except:
        return None

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
    if len(sys.argv) < 2:
        print("Usage: python secscan-cli.py <file>")
        sys.exit(1)
    
    filepath = Path(sys.argv[1])
    results = {"vulnerabilities": [], "code_issues": []}
    
    if filepath.suffix == ".py":
        # Scan dependencies
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
        
        # Scan code
        bandit_data = scan_with_bandit(str(filepath))
        if bandit_data and bandit_data.get("results"):
            for issue in bandit_data["results"]:
                results["code_issues"].append({
                    "line": issue.get("line_number"),
                    "test_id": issue.get("test_id"),
                    "text": issue.get("issue_text")
                })
    
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()