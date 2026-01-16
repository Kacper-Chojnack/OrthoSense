<div align="center">

# 🏥 OrthoSense

### AI-Powered Mobile Telerehabilitation Platform

[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Kacper-Chojnack_OrthoSense&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Kacper-Chojnack_OrthoSense)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=Kacper-Chojnack_OrthoSense&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=Kacper-Chojnack_OrthoSense)
[![Backend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/Kacper-Chojnack/OrthoSense/actions)
[![Frontend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/frontend-ci.yml/badge.svg?branch=main)](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/frontend-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Real-time movement analysis • Privacy-first design • Edge AI processing**

[Features](#-key-features) • [Tech Stack](#-tech-stack) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Documentation](#-documentation) • [Polski](#-wersja-polska)

</div>

---

## 🎯 Overview

OrthoSense is a **mobile telerehabilitation platform** that leverages on-device AI to provide real-time movement analysis and feedback during physical therapy exercises. Built with privacy and accessibility in mind, it processes all video data locally - never sending sensitive recordings to the cloud.

### 🎓 Academic Context

**Engineering Thesis Project**  
Polish-Japanese Academy of Information Technology (PJATK), Gdańsk  
*Class of 2025*

> 💡 **Interface Language:** English only

---

## ✨ Key Features

### 🤖 AI-Powered Analysis
- **Real-time pose estimation** using MediaPipe
- **Movement classification** with Bi-LSTM neural networks
- **Instant feedback** on exercise form and technique
- **Progress tracking** with detailed analytics

### 🔒 Privacy & Security
- **100% on-device processing** - video never leaves your phone
- **End-to-end encryption** for user data
- **GDPR compliant** architecture
- **Security scanning** with Bandit & SonarQube

### 📱 Cross-Platform
- **iOS** (iPhone 8+ / iOS 12+)
- **Android** (API 21+)
- **Responsive UI** with Material Design 3
- **Offline-first** architecture with smart sync

### 🎯 Clinical Features
- **Exercise library** with video demonstrations
- **Session history** and progress reports
- **Performance metrics** and trend analysis
- **Customizable routines** for different rehabilitation needs

---

## 🔧 Tech Stack

<div align="center">

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | ![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter) | Cross-platform mobile development |
| **State Management** | ![Riverpod](https://img.shields.io/badge/Riverpod-2.5-blue) | Reactive state management |
| **Backend** | ![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi) | High-performance REST API |
| **Database** | ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql) | Production data storage |
| **Local DB** | ![SQLite](https://img.shields.io/badge/SQLite-Drift-003B57?logo=sqlite) | Offline-first persistence |
| **AI Framework** | ![MediaPipe](https://img.shields.io/badge/MediaPipe-Pose-orange) | Real-time pose estimation |
| **ML Model** | ![TensorFlow](https://img.shields.io/badge/TFLite-BiLSTM-FF6F00?logo=tensorflow) | Movement classification |
| **Infrastructure** | ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker) | Containerized deployment |
| **CI/CD** | ![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-2088FF?logo=github-actions) | Automated testing & deployment |

</div>

---

## 🚀 Quick Start

### Prerequisites

```bash
# Required
- Flutter SDK 3.24+
- Docker & Docker Compose
- Python 3.11+
- Xcode 15+ (iOS) / Android Studio (Android)

# Optional
- Terraform (infrastructure deployment)
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Kacper-Chojnack/OrthoSense.git
cd OrthoSense

# 2. iOS Setup (automatic Team ID detection)
chmod +x scripts/ios-setup.sh
./scripts/ios-setup.sh

# 3. Start Backend Services
chmod +x scripts/docker-dev.sh
./scripts/docker-dev.sh

# 4. Install Flutter Dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Run the App
flutter run
```

### Development Environment

```bash
# Backend only (with hot reload)
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
flutter test                          # Frontend tests
cd backend && pytest -v              # Backend tests

# Code generation
flutter pub run build_runner watch   # Watch mode
```

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile Application                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Camera Input │  │ MediaPipe AI │  │  TFLite ML  │     │
│  │   (Local)    │→ │ Pose Detector│→ │  Classifier  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│           ↓                ↓                  ↓             │
│  ┌─────────────────────────────────────────────────┐       │
│  │         Riverpod State Management               │       │
│  └─────────────────────────────────────────────────┘       │
│           ↓                                                 │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ SQLite (Drift)│         │  REST Client │                │
│  │ Offline Data │         │   (Dio)      │                │
│  └──────────────┘         └──────┬───────┘                │
└────────────────────────────────────┼──────────────────────┘
                                     │ HTTPS
                  ┌──────────────────▼──────────────────┐
                  │       FastAPI Backend               │
                  │  ┌────────────┐  ┌──────────────┐  │
                  │  │ Auth (JWT) │  │   Rate Limit │  │
                  │  └────────────┘  └──────────────┘  │
                  │  ┌──────────────────────────────┐  │
                  │  │   SQLModel + PostgreSQL      │  │
                  │  └──────────────────────────────┘  │
                  └─────────────────────────────────────┘
```

### Key Design Patterns

- **Clean Architecture** with feature-based organization
- **Repository Pattern** for data access abstraction
- **Provider Pattern** (Riverpod) for dependency injection
- **Offline-First** with background sync queue
- **Error Handling** with typed exceptions and retry logic

---

## 📁 Project Structure

```
OrthoSense/
├── lib/                          # Flutter application
│   ├── core/                     # Core functionality
│   │   ├── database/            # Drift SQLite setup
│   │   ├── providers/           # Riverpod providers
│   │   └── services/            # Business logic services
│   ├── features/                # Feature modules
│   │   ├── auth/               # Authentication & user management
│   │   ├── exercise/           # Exercise catalog & analysis
│   │   ├── dashboard/          # Analytics & statistics
│   │   └── settings/           # App configuration
│   └── infrastructure/         # External integrations
│       └── networking/         # API client (Dio)
├── backend/                     # FastAPI server
│   ├── app/
│   │   ├── ai/                 # AI/ML modules
│   │   ├── api/                # REST endpoints
│   │   ├── core/               # Configuration & utilities
│   │   ├── models/             # SQLModel schemas
│   │   └── services/           # Business logic
│   └── tests/                  # Backend test suite
│       ├── unit/               # Unit tests
│       ├── integration/        # Integration tests
│       └── e2e/                # End-to-end tests
├── test/                        # Frontend test suite
│   ├── unit/                   # Unit tests
│   ├── widget/                 # Widget tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # End-to-end tests
├── assets/                      # Static resources
│   ├── images/                 # App images
│   └── models/                 # TFLite models
├── config/                      # Docker configurations
│   └── docker/                 # Docker Compose files
├── terraform/                   # Infrastructure as Code
│   ├── modules/                # Reusable TF modules
│   └── environments/           # Environment configs
├── docs/                        # Documentation
│   ├── setup/                  # Setup guides
│   └── security/               # Security documentation
└── scripts/                     # Automation scripts
```

---

## 📚 Documentation

- **[Deployment Guide](DEPLOY.md)** - Production deployment with Terraform
- **[Docker Setup](docs/setup/DOCKER_SETUP.md)** - Containerization guide
- **[Security Scanning](docs/security/SECURITY_SCANNING.md)** - Security best practices
- **[iOS Code Signing Fix](docs/setup/FIX_IOS_CODESIGN_ERROR.md)** - Troubleshooting guide
- **[CI/CD Pipeline](docs/CI_CD.md)** - GitHub Actions workflows

---

## 🧪 Testing

### Test Coverage

- **Backend:** 85%+ coverage with pytest
- **Frontend:** 80%+ coverage with flutter_test
- **E2E:** Critical user flows automated

### Running Tests

```bash
# Frontend
flutter test --coverage
flutter test integration_test/

# Backend
cd backend
pytest --cov=app --cov-report=html

# Security Scan
cd backend
bandit -r app -ll
```

---

## 🔐 Security

- ✅ **Static analysis** with Bandit, SonarQube
- ✅ **Secrets scanning** with Gitleaks
- ✅ **Dependency scanning** with Dependabot
- ✅ **OWASP compliance** testing
- ✅ **Rate limiting** and DDoS protection
- ✅ **Input sanitization** and SQL injection prevention

See [Security Documentation](docs/security/SECURITY_SCANNING.md) for details.

---

## 🌐 API Documentation

Interactive API docs available when backend is running:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

---

## 🤝 Contributing

This is an academic project currently not accepting external contributions. However, feel free to:

- ⭐ Star the repository
- 🐛 Report bugs via Issues
- 💡 Suggest features via Discussions

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Copyright © 2025 Kacper Chojnacki**

---

## 👨‍💻 Authors

**Kacper Chojnacki**  
Engineering Student @ PJATK Gdańsk  
[GitHub](https://github.com/Kacper-Chojnack) • [LinkedIn](#)

**Zofia Dekowska**  
Engineering Student @ PJATK Gdańsk  
[GitHub](https://github.com/dekoska) • [LinkedIn](#)

---

## 🙏 Acknowledgments

- **PJATK** for academic support
- **MediaPipe** team for pose estimation framework
- **Flutter** & **FastAPI** communities
- All open-source contributors

---

<div align="center">

## 🇵🇱 Wersja Polska

</div>

### 📖 O Projekcie

**OrthoSense** to platforma mobilna do telerehablitacji wykorzystująca sztuczną inteligencję działającą lokalnie na urządzeniu. Umożliwia analizę ruchów w czasie rzeczywistym i przekazuje natychmiastowe informacje zwrotne podczas wykonywania ćwiczeń fizjoterapeutycznych.

**Praca inżynierska**  
Polsko-Japońska Akademia Technik Komputerowych (PJATK), Gdańsk  
*Rocznik 2025*

### 🎯 Główne Funkcje

- 🤖 **Analiza ruchu w czasie rzeczywistym** - MediaPipe + Bi-LSTM
- 🔒 **Przetwarzanie lokalne** - nagrania nie opuszczają urządzenia
- 📊 **Szczegółowa analityka** - śledzenie postępów i statystyki
- 📱 **Wieloplatformowość** - iOS i Android
- 🌐 **Tryb offline** - pełna funkcjonalność bez internetu
- 🔐 **Bezpieczeństwo** - szyfrowanie end-to-end, zgodność z RODO

### 🔧 Stack Technologiczny

| Warstwa | Technologia | Zastosowanie |
|---------|-------------|--------------|
| **Frontend** | Flutter 3.24 | Rozwój aplikacji mobilnej |
| **Zarządzanie stanem** | Riverpod 2.5 | Reaktywne zarządzanie stanem |
| **Backend** | FastAPI 0.115 | REST API wysokiej wydajności |
| **Baza danych** | PostgreSQL 16 | Przechowywanie danych produkcyjnych |
| **Baza lokalna** | SQLite (Drift) | Tryb offline |
| **AI** | MediaPipe Pose | Estymacja pozy w czasie rzeczywistym |
| **Model ML** | TFLite Bi-LSTM | Klasyfikacja ruchów |
| **Infrastruktura** | Docker + Terraform | Wdrożenie i orkiestracja |

### 🚀 Szybki Start

```bash
# 1. Klonowanie repozytorium
git clone https://github.com/Kacper-Chojnack/OrthoSense.git
cd OrthoSense

# 2. Konfiguracja iOS (automatyczna detekcja Team ID)
chmod +x scripts/ios-setup.sh
./scripts/ios-setup.sh

# 3. Uruchomienie backendu
chmod +x scripts/docker-dev.sh
./scripts/docker-dev.sh

# 4. Instalacja zależności Flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Uruchomienie aplikacji
flutter run
```

### 📚 Dokumentacja

- **[Przewodnik wdrożenia](DEPLOY.md)** - Wdrożenie produkcyjne
- **[Konfiguracja Dockera](docs/setup/DOCKER_SETUP.md)** - Przewodnik konteneryzacji
- **[Bezpieczeństwo](docs/security/SECURITY_SCANNING.md)** - Najlepsze praktyki
- **[CI/CD](docs/CI_CD.md)** - Pipeline automatyzacji

### 🧪 Testowanie

```bash
# Testy frontend
flutter test --coverage

# Testy backend
cd backend && pytest --cov=app

# Skanowanie bezpieczeństwa
cd backend && bandit -r app -ll
```

### 📄 Licencja

Projekt objęty licencją **MIT** - szczegóły w pliku [LICENSE](LICENSE).

### 👨‍💻 Autorzy

**Kacper Chojnacki**  
Student Inżynierii @ PJATK Gdańsk

**Zofia Dekowska**  
Studentka Inżynierii @ PJATK Gdańsk


---

<div align="center">

**Made with ❤️ for better rehabilitation**

⭐ Star this project if you find it useful!

</div>

**Authors / Autorzy:**
- Kacper Chojnacki
- Zofia Dekowska
