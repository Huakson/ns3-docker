#!/usr/bin/env python3
"""
Batch Simulation Example for NS-3 Docker

This script runs multiple simulations with different parameters
and collects results in CSV files.
"""

import subprocess
import sys
from datetime import datetime

def log(message):
    """Print log message with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {message}")

def run_simulation(distance, run_number, total_runs):
    """Run a single simulation with specified distance"""
    log(f"Running simulation {run_number}/{total_runs} - Distance: {distance}m")

    cmd = [
        "./ns3", "run",
        f"wifi-simple --distance={distance} --time=10"
    ]

    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        log(f"  ✓ Completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        log(f"  ✗ Failed with error: {e}")
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
    log(f"Results saved to: /ns3/results/wifi-simple-results.csv")
    log("=" * 50)

    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
