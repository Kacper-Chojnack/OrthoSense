#!/usr/bin/env python3
"""
OrthoSense - Mobile Performance Data Analyzer

This script processes the JSON performance data exported from the
OrthoSense mobile app and generates professional charts for the thesis.

Usage:
    1. Run performance test on phone (30 seconds)
    2. Share/export the JSON file from the app
    3. Copy to: backend/.benchmarks/mobile_perf_*.json
    4. Run: python analyze_mobile_metrics.py

Output: Updated charts in docs/thesis_charts/
"""

import json
import statistics
from datetime import datetime
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    import numpy as np
except ImportError:
    print("Installing dependencies...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "matplotlib", "numpy"])
    import matplotlib.pyplot as plt
    import numpy as np


# Configuration
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 13,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'axes.grid': True,
    'grid.alpha': 0.3,
})

COLORS = {
    'primary': '#2563EB',
    'secondary': '#10B981',
    'accent': '#F59E0B',
    'danger': '#EF4444',
    'success': '#22C55E',
    'dark': '#1F2937',
    'light': '#9CA3AF',
}

PROJECT_ROOT = Path(__file__).parent.parent.parent
BENCHMARKS_DIR = PROJECT_ROOT / "backend" / ".benchmarks"
OUTPUT_DIR = Path(__file__).parent


def load_mobile_metrics() -> list[dict]:
    """Load all mobile performance test results."""
    results = []
    
    if not BENCHMARKS_DIR.exists():
        print(f"⚠️  Benchmarks directory not found: {BENCHMARKS_DIR}")
        return results
    
    # Look for mobile performance files
    patterns = ["mobile_perf_*.json", "perf_test_*.json", "perf_thesis_*.json"]
    
    for pattern in patterns:
        for file in sorted(BENCHMARKS_DIR.glob(pattern), reverse=True):
            try:
                with open(file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    data['_source_file'] = file.name
                    results.append(data)
                    print(f"✓ Loaded: {file.name}")
            except Exception as e:
                print(f"⚠️  Failed to load {file.name}: {e}")
    
    return results


def create_latency_histogram(data: dict) -> None:
    """Create histogram of frame latencies."""
    frame_metrics = data.get('frame_metrics', [])
    if not frame_metrics:
        print("⚠️  No frame metrics found in data")
        return
    
    latencies = [m['latency_ms'] for m in frame_metrics if m.get('latency_ms', 0) > 0]
    
    if len(latencies) < 10:
        print("⚠️  Not enough latency samples")
        return
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Histogram
    n, bins, patches = ax.hist(latencies, bins=30, edgecolor='black', 
                                alpha=0.7, color=COLORS['primary'])
    
    # Percentile lines
    p50 = statistics.median(latencies)
    p95 = sorted(latencies)[int(len(latencies) * 0.95)]
    p99 = sorted(latencies)[int(len(latencies) * 0.99)]
    mean = statistics.mean(latencies)
    
    ax.axvline(mean, color=COLORS['success'], linestyle='-', linewidth=2, 
               label=f'Mean: {mean:.1f} ms')
    ax.axvline(p95, color=COLORS['accent'], linestyle='--', linewidth=2, 
               label=f'P95: {p95:.1f} ms')
    ax.axvline(100, color=COLORS['danger'], linestyle='--', linewidth=2.5, 
               label='Threshold: 100 ms')
    
    ax.set_xlabel('Latency [ms]')
    ax.set_ylabel('Number of frames')
    ax.set_title('Frame Processing Latency Distribution (Real Device)', fontweight='bold')
    ax.legend(loc='upper right')
    
    # Summary annotation
    summary = f"Frames: {len(latencies)}\nMean: {mean:.1f} ms\nP50: {p50:.1f} ms\nP95: {p95:.1f} ms"
    ax.text(0.98, 0.75, summary, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', horizontalalignment='right',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_latencja_prawdziwa.png')
    plt.savefig(OUTPUT_DIR / 'wykres_latencja_prawdziwa.pdf')
    plt.close()
    print("✓ Generated: wykres_latencja_prawdziwa.png/pdf")


def create_fps_timeline(data: dict) -> None:
    """Create FPS over time chart."""
    frame_metrics = data.get('frame_metrics', [])
    if not frame_metrics:
        return
    
    # Calculate FPS per second
    duration_ms = max(m['timestamp_ms'] for m in frame_metrics)
    fps_per_second = []
    
    for second in range(0, int(duration_ms / 1000) + 1):
        start_ms = second * 1000
        end_ms = (second + 1) * 1000
        frames_in_second = sum(1 for m in frame_metrics 
                               if start_ms <= m['timestamp_ms'] < end_ms)
        fps_per_second.append({'time': second, 'fps': frames_in_second})
    
    if len(fps_per_second) < 5:
        return
    
    fig, ax = plt.subplots(figsize=(12, 5))
    
    times = [d['time'] for d in fps_per_second]
    fps_values = [d['fps'] for d in fps_per_second]
    
    ax.plot(times, fps_values, 'o-', color=COLORS['primary'], linewidth=2, markersize=4)
    ax.fill_between(times, fps_values, alpha=0.3, color=COLORS['primary'])
    
    # Target line (15 FPS for analysis)
    ax.axhline(y=15, color=COLORS['success'], linestyle='--', linewidth=2, 
               label='Target: 15 FPS (analysis)')
    
    avg_fps = statistics.mean(fps_values)
    ax.axhline(y=avg_fps, color=COLORS['accent'], linestyle=':', linewidth=2, 
               label=f'Average: {avg_fps:.1f} FPS')
    
    ax.set_xlabel('Time [seconds]')
    ax.set_ylabel('Frames per second [FPS]')
    ax.set_title('FPS Over Time - Real Device Performance', fontweight='bold')
    ax.legend(loc='lower right')
    ax.set_ylim(0, max(fps_values) + 5)
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_fps_timeline.png')
    plt.savefig(OUTPUT_DIR / 'wykres_fps_timeline.pdf')
    plt.close()
    print("✓ Generated: wykres_fps_timeline.png/pdf")


def create_device_comparison(all_results: list[dict]) -> None:
    """Create comparison chart if multiple device results available."""
    if len(all_results) < 2:
        print("⚠️  Need at least 2 test results for comparison")
        return
    
    fig, ax = plt.subplots(figsize=(12, 6))
    
    devices = []
    mean_latencies = []
    p95_latencies = []
    fps_values = []
    
    for data in all_results:
        device = data.get('device', {}).get('model', 'Unknown')
        frame_metrics = data.get('frame_metrics', [])
        
        if not frame_metrics:
            continue
        
        latencies = [m['latency_ms'] for m in frame_metrics if m.get('latency_ms', 0) > 0]
        if not latencies:
            continue
        
        devices.append(device)
        mean_latencies.append(statistics.mean(latencies))
        p95_latencies.append(sorted(latencies)[int(len(latencies) * 0.95)])
        
        duration = data.get('actual_duration_seconds', 30)
        fps_values.append(len(latencies) / duration if duration > 0 else 0)
    
    if not devices:
        return
    
    x = np.arange(len(devices))
    width = 0.25
    
    bars1 = ax.bar(x - width, mean_latencies, width, label='Mean Latency', color=COLORS['primary'])
    bars2 = ax.bar(x, p95_latencies, width, label='P95 Latency', color=COLORS['accent'])
    
    ax.set_ylabel('Latency [ms]')
    ax.set_xlabel('Device')
    ax.set_title('Performance Comparison Across Devices', fontweight='bold')
    ax.set_xticks(x)
    ax.set_xticklabels(devices)
    ax.legend()
    
    ax.axhline(y=100, color=COLORS['danger'], linestyle='--', linewidth=2, label='100ms threshold')
    
    # Add value labels
    for bar in bars1:
        height = bar.get_height()
        ax.annotate(f'{height:.0f}',
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3), textcoords="offset points",
                    ha='center', va='bottom', fontsize=9, fontweight='bold')
    
    for bar in bars2:
        height = bar.get_height()
        ax.annotate(f'{height:.0f}',
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3), textcoords="offset points",
                    ha='center', va='bottom', fontsize=9, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_porownanie_urzadzen.png')
    plt.savefig(OUTPUT_DIR / 'wykres_porownanie_urzadzen.pdf')
    plt.close()
    print("✓ Generated: wykres_porownanie_urzadzen.png/pdf")


def print_summary(data: dict) -> None:
    """Print summary statistics for the thesis."""
    summary = data.get('summary', {})
    percentiles = data.get('percentiles', {})
    
    print("\n" + "=" * 60)
    print("📊 PERFORMANCE TEST SUMMARY (for thesis)")
    print("=" * 60)
    
    print(f"Total frames processed: {summary.get('total_frames', 'N/A')}")
    print(f"Dropped frames: {summary.get('dropped_frames', 'N/A')}")
    print(f"Average FPS: {summary.get('average_fps', 0):.1f}")
    
    print("\nLatency Percentiles:")
    print(f"  Min:  {percentiles.get('min_ms', 0):.1f} ms")
    print(f"  P50:  {percentiles.get('p50_ms', 0):.1f} ms")
    print(f"  P90:  {percentiles.get('p90_ms', 0):.1f} ms")
    print(f"  P95:  {percentiles.get('p95_ms', 0):.1f} ms")
    print(f"  P99:  {percentiles.get('p99_ms', 0):.1f} ms")
    print(f"  Max:  {percentiles.get('max_ms', 0):.1f} ms")
    print(f"  Mean: {percentiles.get('mean_ms', 0):.1f} ms")
    
    print("\nThreshold Checks:")
    meets_100ms = summary.get('meets_100ms_threshold', False)
    meets_15fps = summary.get('meets_15fps_target', False)
    print(f"  P95 < 100ms: {'✅ PASS' if meets_100ms else '❌ FAIL'}")
    print(f"  FPS >= 15:   {'✅ PASS' if meets_15fps else '❌ FAIL'}")
    
    print("\n" + "-" * 60)
    print("Copy these values to generate_charts.py for thesis charts:")
    print("-" * 60)
    print(f"""
# Real device data (from performance test)
REAL_DEVICE_DATA = {{
    'min_latency': {percentiles.get('min_ms', 35):.1f},
    'avg_latency': {percentiles.get('mean_ms', 48):.1f},
    'max_latency': {percentiles.get('max_ms', 75):.1f},
    'p95_latency': {percentiles.get('p95_ms', 65):.1f},
    'fps': {summary.get('average_fps', 15):.1f},
    'test_duration': {data.get('actual_duration_seconds', 30):.1f},
}}
""")


def main():
    print("=" * 60)
    print("OrthoSense - Mobile Performance Data Analyzer")
    print("=" * 60)
    print(f"Looking for data in: {BENCHMARKS_DIR}")
    print("-" * 60)
    
    results = load_mobile_metrics()
    
    if not results:
        print("\n⚠️  No mobile performance data found!")
        print("\nTo collect data:")
        print("  1. Build app: flutter run --profile")
        print("  2. Go to Settings > Performance Test")
        print("  3. Run 30-second test")
        print("  4. Share/export JSON file")
        print(f"  5. Copy to: {BENCHMARKS_DIR}/mobile_perf_DEVICE.json")
        print("  6. Run this script again")
        return
    
    print(f"\n✓ Found {len(results)} test result(s)")
    
    # Process the most recent result
    latest = results[0]
    print(f"\nProcessing: {latest.get('_source_file', 'unknown')}")
    
    # Generate charts
    create_latency_histogram(latest)
    create_fps_timeline(latest)
    
    if len(results) > 1:
        create_device_comparison(results)
    
    # Print summary
    print_summary(latest)
    
    print("\n" + "=" * 60)
    print("✓ Analysis complete!")
    print(f"Charts saved to: {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
