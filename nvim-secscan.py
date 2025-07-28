#!/usr/bin/env python3
"""
nvim-secscan CLI - Standalone security scanner
"""

def show_banner():
    banner = """
    ███╗   ██╗██╗   ██╗██╗███╗   ███╗      ███████╗███████╗ ██████╗███████╗ ██████╗ █████╗ ███╗   ██╗
    ████╗  ██║██║   ██║██║████╗ ████║      ██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗████╗  ██║
    ██╔██╗ ██║██║   ██║██║██╔████╔██║█████╗███████╗█████╗  ██║     ███████╗██║     ███████║██╔██╗ ██║
    ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║╚════╝╚════██║██╔══╝  ██║     ╚════██║██║     ██╔══██║██║╚██╗██║
    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║      ███████║███████╗╚██████╗███████║╚██████╗██║  ██║██║ ╚████║
    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝      ╚══════╝╚══════╝ ╚═════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
    
    Security Scanner for Code & Dependencies | v1.0
    """
    try:
        print(banner)
    except UnicodeEncodeError:
        # Fallback for Windows
        print("=" * 60)
        print("    NVIM-SECSCAN - Security Scanner v1.0")
        print("    Code & Dependency Vulnerability Detection")
        print("=" * 60)

def main():
    import sys
    import os
    
    show_banner()
    
    if len(sys.argv) < 2:
        print("\nUsage: python nvim-secscan.py <file>")
        print("       python scripts/secscan-cli.py <file>")
        print("\nExample:")
        print("       python nvim-secscan.py test/vulnerable_app.py")
        sys.exit(1)
    
    # Delegate to the actual CLI script
    script_path = os.path.join(os.path.dirname(__file__), "scripts", "secscan-cli.py")
    if os.path.exists(script_path):
        os.system(f"python {script_path} {sys.argv[1]}")
    else:
        print("Error: secscan-cli.py not found")
        print("Please run from the nvim-secscan directory")
        sys.exit(1)

if __name__ == "__main__":
    main()