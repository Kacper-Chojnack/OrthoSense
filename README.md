# OrthoSense 🏥

**Digital Health Telerehabilitation Platform** — AI-powered exercise monitoring with clinical precision.

[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Kacper-Chojnack_OrthoSense&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Kacper-Chojnack_OrthoSense)
[![Backend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/Kacper-Chojnack/OrthoSense/actions)
[![Frontend CI](https://github.com/Kacper-Chojnack/OrthoSense/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/Kacper-Chojnack/OrthoSense/actions)

---

## 🚀 Quick Start

### Prerequisites

- Flutter 3.24+
- Python 3.13+
- Docker & Docker Compose

### Development Setup

```bash
# Clone repository
git clone https://github.com/Kacper-Chojnack/OrthoSense.git
cd OrthoSense

# Setup environment
./scripts/docker-setup.sh

# Start backend (Docker)
./scripts/docker-dev.sh

# In another terminal - run Flutter app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📁 Project Structure

```
OrthoSense/
├── lib/                 # Flutter mobile app (Dart)
├── backend/             # FastAPI backend (Python)
├── config/              # Docker & SonarQube configs
│   ├── docker/
│   └── sonar/
├── scripts/             # Build/deploy scripts
├── docs/                # Documentation
│   └── setup/
├── test/                # Flutter tests
└── assets/              # Images, fonts
```

---

## 🔧 Tech Stack

| Layer      | Technology                     |
|------------|--------------------------------|
| Mobile     | Flutter 3.24 + Riverpod        |
| Backend    | FastAPI + SQLModel             |
| AI (Edge)  | MediaPipe + TFLite (Bi-LSTM)   |
| Database   | PostgreSQL (prod) / SQLite (dev) |
| Cache      | Redis                          |

---

## 🔒 Privacy First

Video streams **never leave the device**. Only anonymized pose metadata JSON is synced to the cloud.

---

## 📖 Documentation

- [Docker Setup](docs/setup/DOCKER_SETUP.md)
- [CI/CD Pipeline](docs/CI_CD.md)
- [SonarQube Integration](docs/setup/SONARQUBE_SETUP.md)

---

## 🧑‍💻 Development

### Frontend (Flutter)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
flutter test
```

### Backend (Python)

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload
pytest
```

---

## 📄 License

Proprietary — All Rights Reserved © 2025 Kacper Chojnacki
