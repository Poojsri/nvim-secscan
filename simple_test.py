#!/usr/bin/env python3
"""Simple test without emojis for Windows compatibility"""

import os
import json
from pathlib import Path

def test_suggestions():
    """Test security suggestions feature"""
    print("Testing Security Suggestions")
    print("-" * 30)
    
    patterns = {
        "eval(": "Use ast.literal_eval() for safe evaluation",
        "pickle.loads(": "Use json.loads() for safer serialization", 
        "os.system(": "Use subprocess.run() with shell=False",
        "shell=True": "Set shell=False for security"
    }
    
    test_file = "test/demo_vulnerable.py"
    if os.path.exists(test_file):
        with open(test_file, 'r') as f:
            lines = f.readlines()
        
        suggestions_found = []
        for i, line in enumerate(lines, 1):
            for pattern, suggestion in patterns.items():
                if pattern in line:
                    suggestions_found.append({
                        "line": i,
                        "code": line.strip(),
                        "pattern": pattern,
                        "suggestion": suggestion
                    })
        
        for sugg in suggestions_found:
            print(f"Line {sugg['line']}: {sugg['pattern']}")
            print(f"   Code: {sugg['code']}")
            print(f"   Suggestion: {sugg['suggestion']}")
            print()
    
    return len(suggestions_found)

def test_dependency_parsing():
    """Test requirements.txt parsing"""
    print("Testing Dependency Parsing")
    print("-" * 30)
    
    req_file = "test/requirements.txt"
    if os.path.exists(req_file):
        packages = []
        with open(req_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.replace('>=', '==').split('==')
                    pkg = parts[0].strip()
                    version = parts[1].strip() if len(parts) > 1 else "latest"
                    packages.append((pkg, version))
        
        print("Found packages:")
        for pkg, version in packages:
            print(f"  {pkg} == {version}")
        
        return len(packages)
    
    return 0

def test_dashboard_simulation():
    """Simulate security dashboard"""
    print("Security Dashboard Simulation")
    print("-" * 30)
    
    # Mock results
    mock_results = {
        "critical": 1,
        "high": 3,
        "medium": 2,
        "low": 1,
        "cves": 4,
        "bandit_issues": 3
    }
    
    total = mock_results["critical"] + mock_results["high"] + mock_results["medium"] + mock_results["low"]
    
    print("Security Scan Summary")
    print("=" * 25)
    print()
    
    if mock_results["critical"] > 0:
        print(f"CRITICAL: {mock_results['critical']}")
    if mock_results["high"] > 0:
        print(f"HIGH:     {mock_results['high']}")
    if mock_results["medium"] > 0:
        print(f"MEDIUM:   {mock_results['medium']}")
    if mock_results["low"] > 0:
        print(f"LOW:      {mock_results['low']}")
    
    print()
    print(f"Total Issues: {total}")
    print("Issue Sources:")
    print(f"   CVEs: {mock_results['cves']}")
    print(f"   Code Issues: {mock_results['bandit_issues']}")
    
    if total > 0:
        print("\nCritical issues found!")
    else:
        print("\nNo security issues found!")
    
    return total

def main():
    print("nvim-secscan Virtual Test Environment")
    print("=" * 40)
    
    # Run tests
    suggestions_count = test_suggestions()
    print(f"Found {suggestions_count} security suggestions\n")
    
    packages_count = test_dependency_parsing()
    print(f"Parsed {packages_count} dependencies\n")
    
    issues_count = test_dashboard_simulation()
    print(f"Dashboard shows {issues_count} total issues\n")
    
    print("All tests completed!")
    print("\nTo test with real tools:")
    print("1. Install bandit: pip install bandit")
    print("2. Run: python test_runner.py")
    print("3. Or use in Neovim: :SecScan")

if __name__ == "__main__":
    main()