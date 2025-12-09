#!/usr/bin/env python3
"""
Batch Simulation Example for NS-3 Docker

This script runs multiple simulations with different parameters
and collects results in CSV files.
"""

import subprocess
import sys
from datetime import datetime
import os

def log(message):
    """Print log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {message}")

def run_simulation(distance, run_number, total_runs):
    """Run a single simulation with specified distance"""
    log(f"Running simulation {run_number}/{total_runs} - Distance: {distance}m")

    # This should call the NS-3 Python wrapper inside the container
    # The compiled binary is in /ns3/build/wifi-simple-batch
    cmd = [
        "/ns3/build/wifi-simple-batch", # Chamando o executável compilado diretamente
        f"--distance={distance}",
        "--time=10"
    ]

    try:
        # Execute the command from the /ns3 directory (where the build outputs are often found or linked)
        result = subprocess.run(cmd, check=True, capture_output=True, text=True, cwd="/ns3")
        log(f"  ✓ Completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        log(f"  ✗ Failed with error: {e}")
        log(f"  Stdout: {e.stdout}")
        log(f"  Stderr: {e.stderr}")
        return False
    except FileNotFoundError as e:
        log(f"  ✗ Failed: NS3 compiled executable not found: {e}")
        return False

def main():
    """Main batch execution"""
    log("Starting batch simulation")
    log("=" * 50)

    # Define distances to test (in meters)
    distances = [10, 20, 30, 50, 75, 100, 150, 200]

    total_sims = len(distances)
    successful = 0
    failed = 0

    log(f"Total simulations to run: {total_sims}")
    print()

    # Clear previous results before starting batch
    try:
        results_file = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../results/wifi-simple-results.csv'))
        if os.path.exists(results_file):
            os.remove(results_file)
            log(f"Cleaned up old results file: {results_file}")
    except Exception as e:
        log(f"Warning: Could not clean old results file: {e}")


    for idx, distance in enumerate(distances, 1):
        if run_simulation(distance, idx, total_sims):
            successful += 1
        else:
            failed += 1
        print()

    # Summary
    log("=" * 50)
    log("Batch simulation completed!")
    log(f"  Successful: {successful}/{total_sims}")
    log(f"  Failed: {failed}/{total_sims}")
    log(f"Results saved to: /ns3/results/wifi-simple-results.csv (relative to container)")
    log(f"Results can be found on host in: {os.path.abspath(os.path.join(os.path.dirname(__file__), '../../results'))}")
    log("=" * 50)

    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
