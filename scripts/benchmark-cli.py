#!/usr/bin/env python3
"""
Hyperfine-style benchmarking for nvim-secscan
"""

import argparse
import json
import subprocess
import time
import statistics
import sys
from pathlib import Path

class Benchmark:
    def __init__(self, warmup=3, runs=10, timeout=30):
        self.warmup = warmup
        self.runs = runs
        self.timeout = timeout
    
    def run_command(self, cmd, shell=True):
        """Run a command and measure execution time"""
        try:
            start_time = time.perf_counter()
            result = subprocess.run(
                cmd, 
                shell=shell, 
                capture_output=True, 
                text=True, 
                timeout=self.timeout
            )
            end_time = time.perf_counter()
            
            return {
                'duration': end_time - start_time,
                'exit_code': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr
            }
        except subprocess.TimeoutExpired:
            return {
                'duration': self.timeout,
                'exit_code': -1,
                'error': 'timeout'
            }
        except Exception as e:
            return {
                'duration': 0,
                'exit_code': -1,
                'error': str(e)
            }
    
    def benchmark_command(self, cmd, name=None):
        """Benchmark a command with warmup and multiple runs"""
        name = name or cmd
        print(f"Benchmarking: {name}")
        
        # Warmup runs
        print(f"  Warmup ({self.warmup} runs)...")
        for i in range(self.warmup):
            self.run_command(cmd)
        
        # Actual benchmark runs
        print(f"  Benchmark ({self.runs} runs)...")
        times = []
        successful_runs = 0
        
        for i in range(self.runs):
            result = self.run_command(cmd)
            if result['exit_code'] == 0:
                times.append(result['duration'])
                successful_runs += 1
            print(f"    Run {i+1}/{self.runs}: {result['duration']:.3f}s", end="")
            if result['exit_code'] != 0:
                print(f" (failed: {result.get('error', 'exit code ' + str(result['exit_code']))})")
            else:
                print()
        
        if not times:
            return {
                'name': name,
                'error': 'All runs failed',
                'successful_runs': 0,
                'total_runs': self.runs
            }
        
        return {
            'name': name,
            'successful_runs': successful_runs,
            'total_runs': self.runs,
            'mean': statistics.mean(times),
            'median': statistics.median(times),
            'min': min(times),
            'max': max(times),
            'std_dev': statistics.stdev(times) if len(times) > 1 else 0,
            'times': times
        }
    
    def compare_scanners(self, filepath):
        """Compare different security scanners"""
        scanners = [
            {
                'name': 'nvim-secscan',
                'cmd': f'python scripts/secscan-cli.py "{filepath}"',
                'check': lambda: Path('scripts/secscan-cli.py').exists()
            },
            {
                'name': 'bandit',
                'cmd': f'bandit -f json "{filepath}"',
                'check': lambda: self.check_command_exists('bandit')
            },
            {
                'name': 'trivy',
                'cmd': f'trivy fs --format json "{Path(filepath).parent}"',
                'check': lambda: self.check_command_exists('trivy')
            }
        ]
        
        results = []
        available_scanners = []
        
        # Check which scanners are available
        for scanner in scanners:
            if scanner['check']():
                available_scanners.append(scanner)
            else:
                print(f"Skipping {scanner['name']} (not available)")
        
        if not available_scanners:
            print("No scanners available for benchmarking")
            return []
        
        # Benchmark each available scanner
        for scanner in available_scanners:
            result = self.benchmark_command(scanner['cmd'], scanner['name'])
            results.append(result)
        
        return results
    
    def check_command_exists(self, command):
        """Check if a command exists (cross-platform)"""
        try:
            # Try to run the command with --version or --help
            result = subprocess.run(
                [command, '--version'], 
                capture_output=True, 
                text=True, 
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
            try:
                # Fallback: try with --help
                result = subprocess.run(
                    [command, '--help'], 
                    capture_output=True, 
                    text=True, 
                    timeout=5
                )
                return result.returncode == 0
            except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
                return False
    
    def benchmark_code_execution(self, filepath):
        """Benchmark code execution"""
        file_path = Path(filepath)
        
        if file_path.suffix == '.py':
            cmd = f'python "{filepath}"'
        elif file_path.suffix == '.js':
            cmd = f'node "{filepath}"'
        elif file_path.suffix == '.lua':
            cmd = f'lua "{filepath}"'
        else:
            return {'error': f'Unsupported file type: {file_path.suffix}'}
        
        return self.benchmark_command(cmd, f'Execute {file_path.name}')
    
    def format_results(self, results):
        """Format benchmark results for display"""
        if isinstance(results, dict) and 'error' in results:
            return f"Error: {results['error']}"
        
        if isinstance(results, list):
            return self.format_comparison(results)
        
        # Single result
        if 'error' in results:
            return f"Error: {results['error']}"
        
        output = []
        output.append(f"Benchmark: {results['name']}")
        output.append(f"  Successful runs: {results['successful_runs']}/{results['total_runs']}")
        output.append(f"  Mean:   {results['mean']*1000:.3f} ms")
        output.append(f"  Median: {results['median']*1000:.3f} ms")
        output.append(f"  Min:    {results['min']*1000:.3f} ms")
        output.append(f"  Max:    {results['max']*1000:.3f} ms")
        output.append(f"  StdDev: {results['std_dev']*1000:.3f} ms")
        
        return '\n'.join(output)
    
    def format_comparison(self, results_list):
        """Format comparison of multiple benchmark results"""
        if not results_list:
            return "No results to compare"
        
        # Filter out failed results and sort by mean time
        valid_results = [r for r in results_list if 'error' not in r and r['successful_runs'] > 0]
        valid_results.sort(key=lambda x: x['mean'])
        
        if not valid_results:
            return "All benchmarks failed"
        
        output = []
        output.append("Scanner Performance Comparison:")
        output.append("-" * 50)
        
        fastest = valid_results[0]
        
        for i, result in enumerate(valid_results):
            relative_speed = result['mean'] / fastest['mean']
            status = "FASTEST" if i == 0 else f"{relative_speed:.2f}x slower"
            
            output.append(f"{i+1}. {result['name']}: {result['mean']*1000:.3f} ms ± {result['std_dev']*1000:.3f} ms ({status})")
        
        # Show failed results
        failed_results = [r for r in results_list if 'error' in r or r['successful_runs'] == 0]
        if failed_results:
            output.append("")
            output.append("Failed benchmarks:")
            for result in failed_results:
                error_msg = result.get('error', 'All runs failed')
                output.append(f"  {result['name']}: {error_msg}")
        
        return '\n'.join(output)

def main():
    parser = argparse.ArgumentParser(description='Benchmark security scanners and code execution')
    parser.add_argument('file', help='File to benchmark')
    parser.add_argument('--warmup', type=int, default=3, help='Number of warmup runs')
    parser.add_argument('--runs', type=int, default=10, help='Number of benchmark runs')
    parser.add_argument('--timeout', type=int, default=30, help='Timeout per run in seconds')
    parser.add_argument('--scanners', action='store_true', help='Benchmark security scanners')
    parser.add_argument('--execution', action='store_true', help='Benchmark code execution')
    parser.add_argument('--json', action='store_true', help='Output results as JSON')
    
    args = parser.parse_args()
    
    if not Path(args.file).exists():
        print(f"Error: File '{args.file}' not found")
        sys.exit(1)
    
    benchmark = Benchmark(warmup=args.warmup, runs=args.runs, timeout=args.timeout)
    
    if args.scanners:
        print("[SCAN] Benchmarking Security Scanners")
        print("=" * 40)
        results = benchmark.compare_scanners(args.file)
    elif args.execution:
        print("[EXEC] Benchmarking Code Execution")
        print("=" * 40)
        results = benchmark.benchmark_code_execution(args.file)
    else:
        # Default: benchmark both
        print("[SCAN] Benchmarking Security Scanners")
        print("=" * 40)
        scanner_results = benchmark.compare_scanners(args.file)
        
        print("\n[EXEC] Benchmarking Code Execution")
        print("=" * 40)
        exec_results = benchmark.benchmark_code_execution(args.file)
        
        results = {
            'scanners': scanner_results,
            'execution': exec_results
        }
    
    if args.json:
        print(json.dumps(results, indent=2))
    else:
        if isinstance(results, dict) and 'scanners' in results:
            print("\n[RESULTS] Scanner Results:")
            print(benchmark.format_results(results['scanners']))
            print("\n[RESULTS] Execution Results:")
            print(benchmark.format_results(results['execution']))
        else:
            print("\n[RESULTS] Results:")
            print(benchmark.format_results(results))

if __name__ == '__main__':
    main()