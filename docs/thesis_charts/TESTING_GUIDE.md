# OrthoSense - Instrukcja testowania i generowania wykresów dla pracy dyplomowej

> **Autor:** OrthoSense Team  
> **Data aktualizacji:** Styczeń 2026  
> **Status:** Gotowe do użycia

## Szybki start (TL;DR)

```powershell
# 1. Wygeneruj 3 kluczowe wykresy
cd docs\thesis_charts
python generate_3_charts.py

# Wykresy zostaną automatycznie skopiowane do grafiki/

# 2. (Opcjonalnie) Uruchom testy na prawdziwym AWS
$env:ORTHOSENSE_API_URL = "https://xpcua8sib3.eu-central-1.awsapprunner.com"
python real_api_load_test.py
python generate_3_charts.py  # Wygeneruje wykres z prawdziwych danych
```

**Wynikowe 3 wykresy znajdziesz w:** `grafiki/`
- `wykres_latencja_wydajnosc.pdf` - Latencja ML + API (Sekcja 10.3.1)
- `wykres_testy_obciazeniowe.pdf` - Testy obciążeniowe (Sekcja 10.3.2)
- `wykres_jakosc_testow.pdf` - Jakość kodu i testy (Sekcja 10.2)

---

## Struktura plików

```
OrthoSense/
├── docs/thesis_charts/
│   ├── generate_3_charts.py       # Generator 3 kluczowych wykresów
│   ├── real_api_load_test.py      # Testy na prawdziwym AWS API
│   ├── analyze_mobile_metrics.py  # Analiza JSONów z telefonu
│   └── TESTING_GUIDE.md           # Ten plik
├── lib/features/exercise/presentation/screens/
│   └── performance_test_screen.dart  # Ekran testu wydajności (telefon)
├── backend/.benchmarks/           # Wyniki testów JSON
└── grafiki/                       # Wynikowe wykresy PDF
```

---

## Testowanie na telefonie (WALIDACJA PROGU <100ms)

### 1. Wbudowany ekran Performance Test

Aplikacja ma ekran `PerformanceTestScreen` który:
- ✅ Mierzy latencję każdej klatki i weryfikuje próg <100ms
- ✅ Monitoruje zużycie baterii podczas testu
- ✅ Śledzi zużycie pamięci RAM
- ✅ Oblicza FPS i porównuje z targetem ≥15 FPS
- ✅ Eksportuje szczegółowy JSON do analizy

**Dostępne czasy testu:** 30s, 1 min, 2 min, 5 min (test baterii)

### 2. Jak użyć

1. **Dodaj routing do ekranu** (jeśli jeszcze nie dodany):
```dart
import 'package:orthosense/features/exercise/presentation/screens/performance_test_screen.dart';

// W navigation routes:
GoRoute(
  path: '/performance-test',
  builder: (_, __) => const PerformanceTestScreen(),
),
```

2. **Zbuduj aplikację w trybie Profile:**
```bash
flutter run --profile
```

3. **Przeprowadź test:**
   - Przejdź do ekranu Performance Test
   - Wybierz czas testu (30s dla szybkiego testu, 5 min dla baterii)
   - Kliknij "Start Test"
   - Po zakończeniu - "Share JSON"

4. **Prześlij JSON na komputer** (AirDrop/email/cloud)

5. **Analizuj wyniki:**
```powershell
# Skopiuj JSON do backend/.benchmarks/
Copy-Item "ścieżka_do_json\perf_test_*.json" -Destination backend\.benchmarks\

# Uruchom analizę
cd docs\thesis_charts
python analyze_mobile_metrics.py
```

### 3. Co mierzy test

| Metryka | Opis | Próg dla pracy |
|---------|------|----------------|
| **Latencja P95** | 95. percentyl czasu przetwarzania klatki | <100ms (NF01) |
| **FPS** | Klatki na sekundę dla analizy ML | ≥15 FPS |
| **Threshold Compliance** | % klatek poniżej 100ms | >95% |
| **Zużycie baterii** | Spadek % baterii podczas testu | ~8-12% / 30 min |
| **Peak RAM** | Szczytowe zużycie pamięci | <320 MB |

### 4. Przykładowy wynik JSON

```json
{
  "thesis_validation": {
    "NF01_latency_under_100ms": true,
    "NF01_p95_latency_ms": 52.3,
    "meets_15fps_target": true,
    "actual_fps": 18.2,
    "threshold_compliance_percent": 98.7,
    "validation_passed": true
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

## Testowanie na prawdziwym API AWS

### 1. Konfiguracja

```powershell
# Użyj produkcyjnego URL (już zweryfikowany)
$env:ORTHOSENSE_API_URL = "https://xpcua8sib3.eu-central-1.awsapprunner.com"

# Sprawdź połączenie
curl "$env:ORTHOSENSE_API_URL/health"
```

### 2. Uruchomienie testów

```powershell
cd docs\thesis_charts
python real_api_load_test.py
```

### 3. Co testuje skrypt

1. **Health endpoint** (100 żądań) → p50, p95, p99
2. **Concurrent load** (5-50 równoczesnych) → throughput, success rate
3. **Sustained load** (30s) → time series

---

## Generowanie wykresów

### 1. Generator 3 kluczowych wykresów

```powershell
cd docs\thesis_charts
pip install matplotlib numpy  # Jeśli nie zainstalowane
python generate_3_charts.py
```

### 2. Wygenerowane wykresy

| Plik | Sekcja | Opis |
|------|--------|------|
| `wykres_latencja_wydajnosc.pdf` | 10.3.1 | Latencja ML na urządzeniach + histogram API |
| `wykres_testy_obciazeniowe.pdf` | 10.3.2 | Response time + throughput vs concurrent users |
| `wykres_jakosc_testow.pdf` | 10.2 | Code coverage + piramida testów |

### 3. Użycie w LaTeX

```latex
\begin{figure}[H]
    \centering
    \includegraphics[width=\textwidth]{grafiki/wykres_latencja_wydajnosc.pdf}
    \caption{Latencja przetwarzania ML na urządzeniach mobilnych oraz histogram czasów odpowiedzi API}
    \label{fig:latencja_wydajnosc}
\end{figure}
```

---

## Checklist przed oddaniem pracy

### Minimum (wykresy z przykładowych danych):
- [ ] `python generate_3_charts.py`
- [ ] Wykresy PDF w `grafiki/`
- [ ] `\includegraphics` działają w LaTeX

### Zalecane (prawdziwe dane):
- [ ] Test API: `python real_api_load_test.py`
- [ ] Test na telefonie: PerformanceTestScreen (30s-5min)
- [ ] Skopiuj JSONy do `backend/.benchmarks/`
- [ ] `python analyze_mobile_metrics.py`
- [ ] Ponownie `python generate_3_charts.py`
- [ ] Zaktualizuj wartości w tekście (latencja, FPS, bateria)

---

## Rozwiązywanie problemów

### API niedostępne
```powershell
# Sprawdź status w AWS Console lub użyj:
aws apprunner list-services --region eu-central-1
```

### Brak bibliotek Python
```powershell
pip install matplotlib numpy aiohttp
```

### DevTools nie łączy
```bash
flutter clean && flutter run --profile
```
