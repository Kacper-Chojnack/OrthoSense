# OrthoSense 🏥

> **🇵🇱 [Wersja polska poniżej](#-orthosense---wersja-polska)**

---

## 🇬🇧 English Version

**Mobile telerehabilitation app** that uses on-device AI to analyze patient movements in real-time, helping them perform exercises correctly — all while keeping video data private on the device.

[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Kacper-Chojnack_OrthoSense&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Kacper-Chojnack_OrthoSense)
[![Backend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/Kacper-Chojnack/OrthoSense/actions)
[![Frontend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/frontend-ci.yml/badge.svg?branch=main)](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/frontend-ci.yml)

### 🎓 About

This project is an **Engineering Thesis** developed at **Polish-Japanese Academy of Information Technology (PJATK), Gdańsk**.

> ⚠️ **Note:** The application interface is available **only in English**.

### 🔧 Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.24 + Riverpod |
| Backend | FastAPI + SQLModel |
| AI (Edge) | MediaPipe + TFLite (Bi-LSTM) |
| Database | PostgreSQL / SQLite |

### 🚀 Quick Start

```bash
# Clone & setup
git clone https://github.com/Kacper-Chojnack/OrthoSense.git
cd OrthoSense

# Backend
./scripts/docker-dev.sh

# Frontend (new terminal)
flutter pub get && flutter run
```

### 📁 Structure

```
OrthoSense/
├── lib/          # Flutter app
├── backend/      # FastAPI server
├── config/       # Docker configs
├── docs/         # Documentation
└── scripts/      # Build scripts
```

---

## 🇵🇱 OrthoSense — Wersja Polska

**Mobilna aplikacja do telerehablitacji**, która wykorzystuje AI działające na urządzeniu do analizy ruchów pacjenta w czasie rzeczywistym, pomagając mu poprawnie wykonywać ćwiczenia — przy pełnej prywatności, bez wysyłania nagrań do chmury.

### 🎓 O Projekcie

Projekt jest **pracą inżynierską** realizowaną na **Polsko-Japońskiej Akademii Technik Komputerowych (PJATK), Gdańsk**.

> ⚠️ **Uwaga:** Interfejs aplikacji jest dostępny **wyłącznie w języku angielskim**.

### 🔧 Technologie

| Warstwa | Technologia |
|---------|-------------|
| Mobilna | Flutter 3.24 + Riverpod |
| Backend | FastAPI + SQLModel |
| AI (Edge) | MediaPipe + TFLite (Bi-LSTM) |
| Baza danych | PostgreSQL / SQLite |

### 🚀 Szybki Start

```bash
# Klonowanie i konfiguracja
git clone https://github.com/Kacper-Chojnack/OrthoSense.git
cd OrthoSense

# Backend
./scripts/docker-dev.sh

# Frontend (nowy terminal)
flutter pub get && flutter run
```

---

## 📄 License / Licencja

Proprietary - All Rights Reserved © 2025

**Authors / Autorzy:**
- Kacper Chojnacki
- Zofia Dekowska
