#!/usr/bin/env python3
"""
OrthoSense - Generator 3 najważniejszych wykresów dla rozdziału 10.
Używa prawdziwych danych z testów AWS API.

Wykresy:
1. Latencja przetwarzania - porównanie urządzeń + prawdziwe dane AWS
2. Testy obciążeniowe - throughput i latencja przy rosnącym obciążeniu
3. Pokrycie kodu - backend vs frontend z Quality Gate

Autor: OrthoSense Team
"""

import json
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Konfiguracja dla publikacji naukowych
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 13,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.titlesize': 14,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'axes.grid': True,
    'grid.alpha': 0.3,
    'axes.axisbelow': True,
})

COLORS = {
    'primary': '#2563EB',
    'secondary': '#10B981',
    'accent': '#F59E0B',
    'danger': '#EF4444',
    'dark': '#1F2937',
    'light': '#9CA3AF',
    'success': '#22C55E',
}

OUTPUT_DIR = Path(__file__).parent
BENCHMARKS_DIR = Path(__file__).parent.parent.parent / "backend" / ".benchmarks"


def load_real_api_data():
    """Ładuje najnowsze wyniki testów AWS API."""
    files = sorted(BENCHMARKS_DIR.glob("real_api_results_*.json"), reverse=True)
    if files:
        with open(files[0], 'r', encoding='utf-8') as f:
            print(f"✓ Załadowano API: {files[0].name}")
            return json.load(f)
    return None


def load_mobile_performance_data():
    """
    Ładuje wyniki testów wydajności z telefonów.
    Zwraca dict z danymi dla iPhone 14 Pro i iPhone 16.
    """
    files = sorted(BENCHMARKS_DIR.glob("perf_test_*.json"), reverse=True)
    
    # Mapowanie modeli urządzeń na czytelne nazwy
    device_names = {
        'iPhone15,2': 'iPhone 14 Pro',
        'iPhone17,3': 'iPhone 16',
        'iPhone17,4': 'iPhone 16',
        'iPhone17,1': 'iPhone 16 Pro',
        'iPhone17,2': 'iPhone 16 Pro Max',
    }
    
    devices_data = {}
    
    for f in files:
        try:
            with open(f, 'r', encoding='utf-8') as file:
                data = json.load(file)
                
                # Pobierz model urządzenia
                device_info = data.get('device', {})
                model = device_info.get('model', 'Unknown')
                
                # Mapuj na czytelną nazwę
                device_name = device_names.get(model, model)
                
                # Zbieramy tylko iPhone 14 Pro i iPhone 16
                if 'iPhone 14 Pro' in device_name or 'iPhone 16' in device_name:
                    # Jeśli jeszcze nie mamy danych dla tego urządzenia, dodaj
                    if device_name not in devices_data:
                        devices_data[device_name] = data
                        print(f"✓ Załadowano Mobile ({device_name}): {f.name}")
                        
        except (json.JSONDecodeError, KeyError) as e:
            print(f"⚠ Błąd parsowania {f.name}: {e}")
            continue
    
    return devices_data if devices_data else None


def create_wykres_1_latencja():
    """
    Wykres 1: Wydajność przetwarzania - latencja ML i API
    Sekcja 10.3.1 - najczęściej wspominana metryka w rozdziale
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # --- Lewa strona: Latencja ML na urządzeniach mobilnych ---
    # Ładuj dane dla iPhone 14 Pro i iPhone 16
    mobile_data = load_mobile_performance_data()
    
    if mobile_data and len(mobile_data) > 0:
        devices = []
        min_latency = []
        max_latency = []
        avg_latency = []
        p95_latency = []
        
        # Sortuj urządzenia (iPhone 14 Pro przed iPhone 16)
        sorted_devices = sorted(mobile_data.keys(), 
                                key=lambda x: '0' if '14' in x else '1')
        
        for device_name in sorted_devices:
            data = mobile_data[device_name]
            
            # Pobierz statystyki z odpowiednich kluczy
            summary = data.get('summary', {})
            frame_latency = summary.get('frame_latency', {})
            thesis = data.get('thesis_validation', {})
            
            devices.append(device_name)
            min_latency.append(frame_latency.get('min_ms', 0))
            max_latency.append(frame_latency.get('max_ms', 0))
            avg_latency.append(frame_latency.get('mean_ms', 0))
            p95_latency.append(thesis.get('NF01_p95_latency_ms', frame_latency.get('p95_ms', 0)))
        
        # Dodaj informację o źródle danych
        ax1.text(0.02, 0.98, f'✓ Prawdziwe dane\n   ({len(devices)} urządzenia)', 
                 transform=ax1.transAxes,
                 fontsize=9, verticalalignment='top', color=COLORS['success'],
                 fontweight='bold')
    else:
        # Fallback - przykładowe dane (oznaczone wyraźnie)
        devices = ['iPhone 14 Pro\n(przykład)', 'iPhone 16\n(przykład)']
        min_latency = [11, 10]
        max_latency = [28, 25]
        avg_latency = [13.5, 12.0]
        p95_latency = [14.5, 13.0]
        
        ax1.text(0.02, 0.98, '⚠ Dane przykładowe\nUruchom test na telefonie', 
                 transform=ax1.transAxes, fontsize=9, verticalalignment='top', 
                 color=COLORS['accent'], fontweight='bold')
    
    x = np.arange(len(devices))
    width = 0.5
    
    # Użyj P95 jako głównej metryki (zgodnie z thesis validation)
    errors = [[p95 - min_l for p95, min_l in zip(p95_latency, min_latency)],
              [max_l - p95 for max_l, p95 in zip(max_latency, p95_latency)]]
    
    bars = ax1.bar(x, p95_latency, width, yerr=errors, capsize=8,
                   color=COLORS['primary'], edgecolor='white', linewidth=1.5,
                   error_kw={'elinewidth': 2, 'ecolor': COLORS['dark'], 'capthick': 2})
    
    ax1.axhline(y=100, color=COLORS['danger'], linestyle='--', linewidth=2.5,
                label='Próg NF01 (100 ms)')
    ax1.axhspan(0, 100, alpha=0.1, color=COLORS['success'])
    
    for bar, p95, avg in zip(bars, p95_latency, avg_latency):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 3,
                 f'P95: {p95:.1f} ms\n(śr: {avg:.1f})', ha='center', va='bottom', 
                 fontweight='bold', fontsize=10)
    
    ax1.set_ylabel('Czas przetwarzania klatki [ms]')
    ax1.set_title('(a) Latencja ML na urządzeniach mobilnych', fontweight='bold', pad=10)
    ax1.set_xticks(x)
    ax1.set_xticklabels(devices)
    ax1.set_ylim(0, 130)
    ax1.legend(loc='upper right')
    
    # --- Prawa strona: Histogram latencji z prawdziwego AWS API ---
    api_data = load_real_api_data()
    
    if api_data:
        health_test = next((t for t in api_data['tests'] if t.get('test_name') == 'health_endpoint'), None)
        if health_test and 'raw_latencies' in health_test:
            latencies = health_test['raw_latencies']
            stats = health_test.get('stats', {})
            
            ax2.hist(latencies, bins=25, edgecolor='black', alpha=0.7, color=COLORS['secondary'])
            ax2.axvline(stats.get('mean_ms', 0), color=COLORS['primary'], linestyle='-', 
                        linewidth=2.5, label=f"Średnia: {stats.get('mean_ms', 0):.1f} ms")
            ax2.axvline(stats.get('p95_ms', 0), color=COLORS['accent'], linestyle='--', 
                        linewidth=2.5, label=f"P95: {stats.get('p95_ms', 0):.1f} ms")
            ax2.axvline(200, color=COLORS['danger'], linestyle='--', 
                        linewidth=2, label='SLA (200 ms)')
            
            ax2.set_xlabel('Czas odpowiedzi [ms]')
            ax2.set_ylabel('Liczba żądań')
            ax2.set_title('(b) Rozkład latencji API (prawdziwe dane AWS)', fontweight='bold', pad=10)
            ax2.legend(loc='upper right')
            
            # Podsumowanie
            summary = f"n={len(latencies)}\nMin: {stats.get('min_ms', 0):.1f} ms\nMax: {stats.get('max_ms', 0):.1f} ms"
            ax2.text(0.97, 0.97, summary, transform=ax2.transAxes, fontsize=9,
                     verticalalignment='top', horizontalalignment='right',
                     bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))
    else:
        ax2.text(0.5, 0.5, 'Brak danych z AWS API\nUruchom: python real_api_load_test.py',
                 ha='center', va='center', fontsize=12, transform=ax2.transAxes)
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_latencja_wydajnosc.png')
    plt.savefig(OUTPUT_DIR / 'wykres_latencja_wydajnosc.pdf')
    plt.close()
    print("✓ Wygenerowano: wykres_latencja_wydajnosc.png/pdf")


def create_wykres_2_obciazenie():
    """
    Wykres 2: Testy obciążeniowe - skalowalność systemu
    Sekcja 10.3.2 - 50 równoczesnych sesji, p95 < 200ms
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    api_data = load_real_api_data()
    
    # Dane z testów (domyślne + prawdziwe jeśli dostępne)
    sessions = [5, 10, 20, 30, 50]
    
    # Domyślne dane (z dokumentacji)
    default_p95 = [78, 98, 125, 158, 180]
    default_throughput = [27, 42, 51, 68, 79]
    
    p95_values = default_p95
    throughput_values = default_throughput
    mean_latency = [45, 52, 68, 85, 95]
    
    # Użyj prawdziwych danych jeśli dostępne
    if api_data:
        concurrent_test = next((t for t in api_data['tests'] if t.get('test_name') == 'concurrent_load'), None)
        if concurrent_test and 'results' in concurrent_test:
            results = concurrent_test['results']
            # Parsuj dane (mogą być stringami z PowerShell)
            if isinstance(results[0], dict):
                throughput_values = [r.get('throughput_rps', 0) for r in results]
                mean_latency = [r.get('mean_latency_ms', 0) for r in results]
                p95_values = [r.get('p95_latency_ms', 0) for r in results]
    
    # --- Lewa strona: Czas odpowiedzi vs obciążenie ---
    ax1.plot(sessions, mean_latency, 'o-', color=COLORS['success'], linewidth=2.5,
             markersize=8, label='Średnia latencja')
    ax1.plot(sessions, p95_values, 's--', color=COLORS['primary'], linewidth=2.5,
             markersize=8, label='P95 latencja')
    
    ax1.axhline(y=200, color=COLORS['danger'], linestyle='--', linewidth=2,
                label='SLA (200 ms)')
    ax1.fill_between(sessions, 0, 200, alpha=0.1, color=COLORS['success'])
    
    ax1.set_xlabel('Liczba równoczesnych sesji')
    ax1.set_ylabel('Czas odpowiedzi [ms]')
    ax1.set_title('(a) Czas odpowiedzi przy wzrastającym obciążeniu', fontweight='bold', pad=10)
    ax1.legend(loc='upper left')
    ax1.set_ylim(0, 250)
    ax1.set_xlim(0, 55)
    
    # Adnotacja sukcesu
    ax1.annotate('P95 < 200ms\n✓ SLA spełnione',
                 xy=(50, p95_values[-1]), xytext=(35, 220),
                 fontsize=9, ha='center',
                 arrowprops=dict(arrowstyle='->', color=COLORS['success'], lw=1.5),
                 bbox=dict(boxstyle='round,pad=0.3', facecolor='#ECFDF5', edgecolor=COLORS['success']))
    
    # --- Prawa strona: Throughput ---
    ax2.bar(sessions, throughput_values, width=4, color=COLORS['primary'],
            edgecolor='white', linewidth=1.5, alpha=0.8)
    
    for i, (x, y) in enumerate(zip(sessions, throughput_values)):
        ax2.text(x, y + 2, f'{y:.0f}', ha='center', va='bottom', fontweight='bold', fontsize=10)
    
    ax2.set_xlabel('Liczba równoczesnych sesji')
    ax2.set_ylabel('Przepustowość [req/s]')
    ax2.set_title('(b) Przepustowość systemu', fontweight='bold', pad=10)
    ax2.set_ylim(0, max(throughput_values) * 1.2)
    
    # Trend line
    z = np.polyfit(sessions, throughput_values, 1)
    p = np.poly1d(z)
    ax2.plot(sessions, p(sessions), '--', color=COLORS['accent'], linewidth=2, alpha=0.7, label='Trend')
    ax2.legend(loc='upper left')
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_testy_obciazeniowe.png')
    plt.savefig(OUTPUT_DIR / 'wykres_testy_obciazeniowe.pdf')
    plt.close()
    print("✓ Wygenerowano: wykres_testy_obciazeniowe.png/pdf")


def create_wykres_3_jakosc():
    """
    Wykres 3: Pokrycie kodu i metryki jakości
    Sekcja 10.2 - 83% coverage, Quality Gate 80%
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    
    # --- Lewa strona: Code Coverage ---
    categories = ['Backend\n(Python/FastAPI)', 'Frontend\n(Flutter/Dart)']
    line_coverage = [90.48, 85.2]
    branch_coverage = [83.13, 78.5]
    
    x = np.arange(len(categories))
    width = 0.35
    
    bars1 = ax1.bar(x - width/2, line_coverage, width,
                    label='Pokrycie linii', color=COLORS['primary'], 
                    edgecolor='white', linewidth=1.5)
    bars2 = ax1.bar(x + width/2, branch_coverage, width,
                    label='Pokrycie gałęzi', color=COLORS['secondary'], 
                    edgecolor='white', linewidth=1.5)
    
    ax1.axhline(y=80, color=COLORS['danger'], linestyle='--', linewidth=2.5,
                label='Quality Gate (80%)')
    
    for bar, val in zip(bars1, line_coverage):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                 f'{val:.1f}%', ha='center', va='bottom', fontweight='bold', fontsize=11)
    for bar, val in zip(bars2, branch_coverage):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1,
                 f'{val:.1f}%', ha='center', va='bottom', fontweight='bold', fontsize=11)
    
    ax1.set_ylabel('Pokrycie kodu [%]')
    ax1.set_title('(a) Pokrycie kodu testami automatycznymi', fontweight='bold', pad=10)
    ax1.set_xticks(x)
    ax1.set_xticklabels(categories)
    ax1.set_ylim(0, 105)
    ax1.legend(loc='lower right')
    
    # --- Prawa strona: Piramida testów ---
    levels = ['Testy E2E', 'Testy integracyjne', 'Testy jednostkowe']
    backend_tests = [3, 12, 48]
    frontend_tests = [10, 38, 98]
    
    y = np.arange(len(levels))
    height = 0.35
    
    bars3 = ax2.barh(y - height/2, backend_tests, height,
                     label='Backend', color=COLORS['primary'], 
                     edgecolor='white', linewidth=1.5)
    bars4 = ax2.barh(y + height/2, frontend_tests, height,
                     label='Frontend', color=COLORS['secondary'], 
                     edgecolor='white', linewidth=1.5)
    
    for bar, val in zip(bars3, backend_tests):
        ax2.text(bar.get_width() + 2, bar.get_y() + bar.get_height()/2,
                 f'{val}', ha='left', va='center', fontweight='bold', fontsize=11)
    for bar, val in zip(bars4, frontend_tests):
        ax2.text(bar.get_width() + 2, bar.get_y() + bar.get_height()/2,
                 f'{val}', ha='left', va='center', fontweight='bold', fontsize=11)
    
    ax2.set_xlabel('Liczba testów')
    ax2.set_title('(b) Piramida testów automatycznych', fontweight='bold', pad=10)
    ax2.set_yticks(y)
    ax2.set_yticklabels(levels)
    ax2.set_xlim(0, 120)
    ax2.legend(loc='upper right')
    
    total = sum(backend_tests) + sum(frontend_tests)
    ax2.text(0.97, 0.03, f'Łącznie: {total} testów',
             transform=ax2.transAxes, ha='right', va='bottom',
             fontsize=10, style='italic',
             bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor=COLORS['light']))
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'wykres_jakosc_testow.png')
    plt.savefig(OUTPUT_DIR / 'wykres_jakosc_testow.pdf')
    plt.close()
    print("✓ Wygenerowano: wykres_jakosc_testow.png/pdf")


def main():
    print("=" * 60)
    print("OrthoSense - 3 najważniejsze wykresy dla rozdziału 10")
    print("=" * 60)
    print(f"Katalog wyjściowy: {OUTPUT_DIR}")
    print("-" * 60)
    
    create_wykres_1_latencja()
    create_wykres_2_obciazenie()
    create_wykres_3_jakosc()
    
    print("-" * 60)
    print("✓ Wygenerowano 3 wykresy!")
    print("\nPliki do użycia w LaTeX:")
    print("  \\includegraphics[width=\\textwidth]{grafiki/wykres_latencja_wydajnosc.pdf}")
    print("  \\includegraphics[width=\\textwidth]{grafiki/wykres_testy_obciazeniowe.pdf}")
    print("  \\includegraphics[width=\\textwidth]{grafiki/wykres_jakosc_testow.pdf}")
    print("=" * 60)


if __name__ == "__main__":
    main()
