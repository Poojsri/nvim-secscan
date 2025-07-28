#!/usr/bin/env python3
"""
Standalone test runner for nvim-secscan plugin
Simulates plugin functionality without Neovim
"""

import json
import os
import subprocess
import requests
from pathlib import Path

class MockNvimSecscan:
    def __init__(self):
        self.config = {
            "scanner": "osv",
            "enable_suggestions": True,
            "hide_low": False
        }
        self.suggestions_db = {
            "python": {
                "eval(": "Use ast.literal_eval() for safe evaluation",
                "pickle.loads(": "Use json.loads() for safer serialization",
                "os.system(": "Use subprocess.run() with shell=False",
                "shell=True": "Set shell=False for security"
            }
        }
    
    def scan_file(self, filepath):
        """Main scan function"""
        print(f"🔍 Scanning {filepath}...")
        
        results = {
            "vulnerabilities": [],
            "code_issues": [],
            "suggestions": []
        }
        
        # Dependency scanning
        if filepath.endswith('.py'):
            deps = self.scan_python_deps(filepath)
            results["vulnerabilities"].extend(deps)
            
            # Code pattern scanning
            bandit = self.run_bandit(filepath)
            results["code_issues"].extend(bandit)
            
            # Suggestions
            suggestions = self.get_suggestions(filepath)
            results["suggestions"].extend(suggestions)
        
        return results
    
    def scan_python_deps(self, filepath):
        """Scan Python dependencies via OSV.dev"""
        dir_path = Path(filepath).parent
        req_file = dir_path / "requirements.txt"
        
        if not req_file.exists():
            return []
        
        vulnerabilities = []
        packages = self.parse_requirements(req_file)
        
        for pkg, version in packages:
            vulns = self.query_osv(pkg, version)
            vulnerabilities.extend(vulns)
        
        return vulnerabilities
    
    def parse_requirements(self, req_file):
        """Parse requirements.txt"""
        packages = []
        with open(req_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.replace('>=', '==').replace('>', '==').split('==')
                    pkg = parts[0].strip()
                    version = parts[1].strip() if len(parts) > 1 else None
                    packages.append((pkg, version))
        return packages
    
    def query_osv(self, package, version=None):
        """Query OSV.dev API"""
        query = {"package": {"name": package, "ecosystem": "PyPI"}}
        if version:
            query["version"] = version
        
        try:
            response = requests.post("https://api.osv.dev/v1/query", json=query, timeout=5)
            data = response.json()
            
            vulnerabilities = []
            if data.get("vulns"):
                for vuln in data["vulns"]:
                    vulnerabilities.append({
                        "package": package,
                        "version": version,
                        "cve_id": vuln.get("id"),
                        "summary": vuln.get("summary", "Security vulnerability"),
                        "severity": "HIGH"
                    })
            
            return vulnerabilities
        except:
            return []
    
    def run_bandit(self, filepath):
        """Run Bandit scan"""
        try:
            result = subprocess.run(
                ["bandit", "-f", "json", filepath],
                capture_output=True, text=True, check=False
            )
            
            if result.stdout:
                data = json.loads(result.stdout)
                issues = []
                
                if data.get("results"):
                    for issue in data["results"]:
                        issues.append({
                            "line": issue.get("line_number"),
                            "test_id": issue.get("test_id"),
                            "severity": issue.get("issue_severity"),
                            "text": issue.get("issue_text")
                        })
                
                return issues
        except:
            pass
        
        return []
    
    def get_suggestions(self, filepath):
        """Get security suggestions"""
        suggestions = []
        
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines, 1):
            for pattern, suggestion in self.suggestions_db["python"].items():
                if pattern in line:
                    suggestions.append({
                        "line": i,
                        "pattern": pattern,
                        "suggestion": suggestion,
                        "code": line.strip()
                    })
        
        return suggestions
    
    def generate_dashboard(self, results):
        """Generate security dashboard"""
        total_vulns = len(results["vulnerabilities"])
        total_issues = len(results["code_issues"])
        total_suggestions = len(results["suggestions"])
        
        print("\n🛡️  Security Scan Summary")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if total_vulns > 0:
            print(f"🔴 VULNERABILITIES: {total_vulns}")
        if total_issues > 0:
            print(f"🟠 CODE ISSUES: {total_issues}")
        if total_suggestions > 0:
            print(f"💡 SUGGESTIONS: {total_suggestions}")
        
        print(f"\n📊 Total Issues: {total_vulns + total_issues}")
        
        if total_vulns + total_issues == 0:
            print("✅ No security issues found!")
        else:
            print("⚠️  Security issues detected")
    
    def show_detailed_results(self, results):
        """Show detailed scan results"""
        print("\n📋 Detailed Results:")
        print("=" * 50)
        
        # Vulnerabilities
        if results["vulnerabilities"]:
            print("\n🔴 DEPENDENCY VULNERABILITIES:")
            for vuln in results["vulnerabilities"]:
                print(f"  • {vuln['package']} {vuln['version']} - {vuln['cve_id']}")
                print(f"    {vuln['summary']}")
        
        # Code Issues
        if results["code_issues"]:
            print("\n🟠 CODE SECURITY ISSUES:")
            for issue in results["code_issues"]:
                print(f"  • Line {issue['line']}: {issue['text']}")
                print(f"    Severity: {issue['severity']}, Test: {issue['test_id']}")
        
        # Suggestions
        if results["suggestions"]:
            print("\n💡 SECURITY SUGGESTIONS:")
            for sugg in results["suggestions"]:
                print(f"  • Line {sugg['line']}: {sugg['pattern']}")
                print(f"    Code: {sugg['code']}")
                print(f"    💡 {sugg['suggestion']}")

def main():
    print("🚀 nvim-secscan Virtual Test Environment")
    print("=" * 50)
    
    scanner = MockNvimSecscan()
    test_files = [
        "test/vulnerable_app.py",
        "test/test_suggestions.py"
    ]
    
    for test_file in test_files:
        if os.path.exists(test_file):
            print(f"\n📁 Testing: {test_file}")
            results = scanner.scan_file(test_file)
            
            scanner.generate_dashboard(results)
            scanner.show_detailed_results(results)
            
            print("\n" + "─" * 50)
        else:
            print(f"❌ Test file not found: {test_file}")

if __name__ == "__main__":
    main()