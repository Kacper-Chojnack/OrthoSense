# OrthoSense - Testing and Chart Generation Guide for Thesis

> **Author:** OrthoSense Team  
> **Last Updated:** January 2026  
> **Status:** Ready to use

## Quick Start (TL;DR)

```powershell
# 1. Generate 3 key charts
cd docs\thesis_charts
python generate_3_charts.py

# Charts will be automatically copied to grafiki/

# 2. (Optional) Run tests on real AWS
$env:ORTHOSENSE_API_URL = "https://xpcua8sib3.eu-central-1.awsapprunner.com"
python real_api_load_test.py
python generate_3_charts.py  # Will generate charts from real data
```

**Output charts can be found in:** `grafiki/`
- `wykres_latencja_wydajnosc.pdf` - ML + API Latency (Section 10.3.1)
- `wykres_testy_obciazeniowe.pdf` - Load Tests (Section 10.3.2)
- `wykres_jakosc_testow.pdf` - Code Quality & Tests (Section 10.2)

---

## File Structure

```
OrthoSense/
├── docs/thesis_charts/
│   ├── generate_3_charts.py       # Generator for 3 key charts
│   ├── real_api_load_test.py      # Tests on real AWS API
│   ├── analyze_mobile_metrics.py  # Analysis of phone JSON files
│   └── TESTING_GUIDE.md           # This file
├── lib/features/exercise/presentation/screens/
│   └── performance_test_screen.dart  # Performance test screen (phone)
├── backend/.benchmarks/           # Test results JSON
└── grafiki/                       # Output PDF charts
```

---

## Mobile Device Testing (VALIDATING <100ms THRESHOLD)

### 1. Built-in Performance Test Screen (FULL PIPELINE)

The app has a `PerformanceTestScreen` that tests the **FULL PIPELINE**:

```
Camera → MediaPipe (Pose) → Bi-LSTM (Classifier) → Diagnostics → UI
```

**What the test measures:**
- ✅ Full pipeline latency (from camera frame to UI update)
- ✅ Breakdown: MediaPipe, Bi-LSTM, Diagnostics separately
- ✅ Exercise classification (same as real analysis)
- ✅ Feedback/tips (same as real analysis)
- ✅ Battery consumption during test
- ✅ RAM memory usage
- ✅ FPS and comparison with ≥15 FPS target
- ✅ Detailed JSON export for analysis

**The test is identical to real analysis** - the only differences are:
- "🧪 FULL PIPELINE TEST (MOCK)" banner on screen
- Results are not saved to the database

**Available test durations:** 30s, 1 min, 2 min, 5 min (battery test)

### 2. How to Use

1. **Add routing to the screen** (if not already added):
```dart
import 'package:orthosense/features/exercise/presentation/screens/performance_test_screen.dart';

// In navigation routes:
GoRoute(
  path: '/performance-test',
  builder: (_, __) => const PerformanceTestScreen(),
),
```

2. **Build the app in Profile mode:**
```bash
flutter run --profile
```

3. **Run the test:**
   - Navigate to Performance Test screen
   - Select test duration (30s for quick test, 5 min for battery)
   - Click "Start Test"
   - After completion - "Share JSON"

4. **Transfer JSON to computer** (AirDrop/email/cloud)

5. **Analyze results:**
```powershell
# Copy JSON to backend/.benchmarks/
Copy-Item "path_to_json\perf_test_*.json" -Destination backend\.benchmarks\

# Run analysis
cd docs\thesis_charts
python analyze_mobile_metrics.py
```

### 3. What the Test Measures (FULL PIPELINE)

| Metric | Description | Thesis Threshold |
|--------|-------------|------------------|
| **Total Pipeline P95** | 95th percentile of full pipeline | <100ms (NF01) |
| **MediaPipe P95** | 95th percentile of pose detection | ~10-20ms |
| **Bi-LSTM P95** | 95th percentile of classifier | ~5-15ms |
| **Diagnostics P95** | 95th percentile of movement analysis | ~1-5ms |
| **FPS** | Frames per second for ML analysis | ≥15 FPS |
| **Threshold Compliance** | % of frames under 100ms | >95% |
| **Battery Consumption** | Battery % drop during test | ~8-12% / 30 min |
| **Peak RAM** | Peak memory usage | <320 MB |

### 4. Sample JSON Output (FULL PIPELINE)

```json
{
  "test_name": "thesis_performance_test",
  "test_type": "FULL_PIPELINE",
  "pipeline_description": "Camera → MediaPipe → Bi-LSTM → Diagnostics → UI",
  "thesis_validation": {
    "NF01_latency_under_100ms": true,
    "NF01_p95_latency_ms": 52.3,
    "meets_15fps_target": true,
    "actual_fps": 18.2,
    "threshold_compliance_percent": 98.7,
    "validation_passed": true,
    "pipeline_tested": "FULL (MediaPipe + Bi-LSTM + Diagnostics)"
  },
  "pipeline_breakdown": {
    "mediapipe_latency": {"p50_ms": 12.1, "p95_ms": 14.8, "p99_ms": 16.2},
    "classifier_latency": {"p50_ms": 8.5, "p95_ms": 12.3, "p99_ms": 15.1},
    "diagnostics_latency": {"p50_ms": 2.1, "p95_ms": 3.5, "p99_ms": 4.2},
    "total_pipeline_latency": {"p50_ms": 25.3, "p95_ms": 32.1, "p99_ms": 38.5},
    "classification_count": 450,
    "diagnostics_count": 420,
    "detected_exercise": "Deep Squat",
    "detected_variant": null
  },
  "battery": {
    "start_level_percent": 85,
    "end_level_percent": 83,
    "drain_percent": 2,
    "projected_30min_drain": 4.0
  }
}
```

---

## Testing on Real AWS API

### 1. Configuration

```powershell
# Use production URL (already verified)
$env:ORTHOSENSE_API_URL = "https://xpcua8sib3.eu-central-1.awsapprunner.com"

# Check connection
curl "$env:ORTHOSENSE_API_URL/health"
```

### 2. Running Tests

```powershell
cd docs\thesis_charts
python real_api_load_test.py
```

### 3. What the Script Tests

1. **Health endpoint** (100 requests) → p50, p95, p99
2. **Concurrent load** (5-50 concurrent) → throughput, success rate
3. **Sustained load** (30s) → time series

---

## Generating Charts

### 1. 3 Key Charts Generator

```powershell
cd docs\thesis_charts
pip install matplotlib numpy  # If not installed
python generate_3_charts.py
```

### 2. Generated Charts

| File | Section | Description |
|------|---------|-------------|
| `wykres_latencja_wydajnosc.pdf` | 10.3.1 | ML latency on devices + API histogram |
| `wykres_testy_obciazeniowe.pdf` | 10.3.2 | Response time + throughput vs concurrent users |
| `wykres_jakosc_testow.pdf` | 10.2 | Code coverage + test pyramid |

### 3. Using in LaTeX

```latex
\begin{figure}[H]
    \centering
    \includegraphics[width=\textwidth]{grafiki/wykres_latencja_wydajnosc.pdf}
    \caption{ML processing latency on mobile devices and API response time histogram}
    \label{fig:latency_performance}
\end{figure}
```

---

## Pre-Submission Checklist

### Minimum (charts from sample data):
- [ ] `python generate_3_charts.py`
- [ ] PDF charts in `grafiki/`
- [ ] `\includegraphics` works in LaTeX

### Recommended (real data):
- [ ] API test: `python real_api_load_test.py`
- [ ] Phone test: PerformanceTestScreen (30s-5min)
- [ ] Copy JSONs to `backend/.benchmarks/`
- [ ] `python analyze_mobile_metrics.py`
- [ ] Re-run `python generate_3_charts.py`
- [ ] Update values in thesis text (latency, FPS, battery)

---

## Troubleshooting

### API Unavailable
```powershell
# Check status in AWS Console or use:
aws apprunner list-services --region eu-central-1
```

### Missing Python Libraries
```powershell
pip install matplotlib numpy aiohttp
```

### DevTools Not Connecting
```bash
flutter clean && flutter run --profile
```
