#!/usr/bin/env python3
"""
nvim-secscan CLI - Standalone security scanner
Usage: nvim-secscan [OPTIONS] <file>
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

def show_help():
    print("\nUsage: nvim-secscan [OPTIONS] <file>")
    print("\nSecurity scanner for code files and dependencies")
    print("\nArguments:")
    print("  <file>                 File to scan for security vulnerabilities")
    print("\nOptions:")
    print("  -h, --help            Show this help message")
    print("  -v, --version         Show version information")
    print("  --format FORMAT       Output format (json, text) [default: json]")
    print("  --deps-only           Only scan dependencies, skip code analysis")
    print("\nExamples:")
    print("  nvim-secscan app.py")
    print("  nvim-secscan --format text app.py")
    print("  nvim-secscan --deps-only requirements.txt")
    print("")

def main():
    import sys
    import os
    
    # Parse arguments
    if len(sys.argv) < 2 or sys.argv[1] in ['-h', '--help']:
        show_banner()
        show_help()
        sys.exit(0)
    
    if sys.argv[1] in ['-v', '--version']:
        show_banner()
        print("nvim-secscan version 1.0")
        sys.exit(0)
    
    show_banner()
    
    # Find the file argument (last non-option argument)
    file_arg = None
    for arg in reversed(sys.argv[1:]):
        if not arg.startswith('-'):
            file_arg = arg
            break
    
    if not file_arg:
        print("Error: No file specified")
        show_help()
        sys.exit(1)
    
    # Delegate to the actual CLI script
    script_path = os.path.join(os.path.dirname(__file__), "scripts", "secscan-cli.py")
    if os.path.exists(script_path):
        # Pass all arguments to the CLI script
        args = ' '.join(sys.argv[1:])
        os.system(f"python {script_path} {args}")
    else:
        print("Error: secscan-cli.py not found")
        print("Please run from the nvim-secscan directory")
        sys.exit(1)

if __name__ == "__main__":
    main()