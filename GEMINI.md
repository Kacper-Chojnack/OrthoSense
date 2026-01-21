# OrthoSense Project GEMINI.md

## Project Overview

OrthoSense is a full-stack telerehabilitation platform designed to help patients perform physical therapy exercises at home. It consists of a Flutter mobile application and a Python (FastAPI) backend. The platform uses a hybrid AI model, with real-time exercise analysis on the device and more complex analysis on the server. The mobile application is designed to be offline-first, allowing patients to perform exercises without an active internet connection.

The project is well-structured with a focus on modern development practices, including a robust CI/CD pipeline, Infrastructure as Code, and strong security measures.

## Technologies

### Frontend (Flutter)

*   **Framework:** Flutter
*   **State Management:** Riverpod
*   **Local Database:** Drift (SQLite wrapper)
*   **On-Device AI:** `google_mlkit_pose_detection` and a custom `tflite` model

### Backend (Python)

*   **Framework:** FastAPI
*   **Database:** PostgreSQL with `asyncpg`
*   **ORM:** SQLModel
*   **Server-Side AI:** `torch` and `mediapipe`
*   **Cloud:** AWS (inferred from `boto3` SDK and Terraform)

## Getting Started

### Building and Running

**Frontend (Flutter):**

```bash
# TODO: Add instructions for building and running the Flutter app.
# Example:
# flutter pub get
# flutter run
```

**Backend (Python):**

```bash
# TODO: Add instructions for building and running the FastAPI backend.
# Example:
# cd backend
# pip install -r requirements.txt
# uvicorn app.main:app --reload
```

### Testing

**Frontend (Flutter):**

```bash
# TODO: Add instructions for running Flutter tests.
# Example:
# flutter test
```

**Backend (Python):**

```bash
# TODO: Add instructions for running Python tests.
# Example:
# cd backend
# pytest
```

## Development Conventions

*   **CI/CD:** The project uses GitHub Actions for continuous integration and deployment. Workflows are defined in the `.github/workflows` directory.
*   **Infrastructure as Code:** Cloud infrastructure is managed with Terraform. Configuration files are in the `terraform` directory.
*   **Security:** The backend implements a strong security posture, including CORS, rate limiting, trusted host validation, and security headers. Security scanning is automated with SonarCloud and CodeQL.
*   **Code Style:** The project uses `pre-commit` hooks to enforce code style and quality. See `.pre-commit-config.yaml` for details.
