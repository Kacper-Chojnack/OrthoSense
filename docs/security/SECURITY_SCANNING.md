# Security Scanning Documentation

## Overview

OrthoSense implements automated security scanning aligned with **OWASP Top 10 2021** requirements as part of the Engineering Thesis (Section 10.4.1).

## Implemented Tools

### 1. Dependency Scanning (A06:2021 - Vulnerable Components)

| Tool | Purpose | Target |
|------|---------|--------|
| **Safety** | Python vulnerability database check | Backend dependencies |
| **pip-audit** | PyPI vulnerability scanning | Backend dependencies |
| **Flutter pub outdated** | Dart package audit | Frontend dependencies |

### 2. Static Application Security Testing (SAST)

| Tool | Purpose | Coverage |
|------|---------|----------|
| **Bandit** | Python security linter | A02, A03, A07 |
| **Semgrep** | Multi-language SAST | A03, A05, A10 |

**Bandit detects:**
- Hardcoded passwords and secrets (A07)
- SQL injection patterns (A03)
- Insecure cryptographic usage (A02)
- Shell injection vulnerabilities (A03)

**Semgrep rules applied:**
- `p/owasp-top-ten` - Full OWASP coverage
- `p/python` - Python-specific rules
- `p/security-audit` - General security audit

### 3. Secret Detection (A07:2021 - Authentication Failures)

**Gitleaks** scans git history for:
- API keys (AWS, GCP, Azure)
- Database credentials
- JWT secrets
- Private keys

### 4. API Security Analysis (A01:2021 - Broken Access Control)

- OpenAPI schema validation
- Endpoint authentication verification
- Authorization testing

## Running Security Scans

### Locally

```bash
# Backend security scan
cd backend
bandit -r app -ll
safety check
pip-audit

# Secret scanning (from project root)
gitleaks detect --source .

# Run OWASP security tests
pytest tests/test_security_owasp.py -v
```

### CI/CD

Security scans run automatically on:
- ✅ Every push to `main` and `develop`
- ✅ Every pull request to `main`
- ✅ Weekly scheduled scan (Sundays 2 AM UTC)

## OWASP Top 10 Coverage Matrix

| ID | Category | Tool(s) | Automation |
|----|----------|---------|------------|
| A01 | Broken Access Control | API Lint, Unit Tests | ✅ Automated |
| A02 | Cryptographic Failures | Bandit, Code Review | ✅ Automated |
| A03 | Injection | Semgrep, Bandit, Unit Tests | ✅ Automated |
| A04 | Insecure Design | Manual Review | 📋 Manual |
| A05 | Security Misconfiguration | Semgrep, Unit Tests | ✅ Automated |
| A06 | Vulnerable Components | Safety, pip-audit | ✅ Automated |
| A07 | Auth Failures | Gitleaks, Bandit, Unit Tests | ✅ Automated |
| A08 | Software Integrity | Dependency Check | ✅ Automated |
| A09 | Logging Failures | Unit Tests, Code Review | ⚠️ Partial |
| A10 | SSRF | Semgrep, Unit Tests | ✅ Automated |

## Report Artifacts

All security scan reports are uploaded as GitHub Actions artifacts:

| Artifact | Content |
|----------|---------|
| `safety-report.json` | Python vulnerability report |
| `pip-audit-report.json` | pip-audit findings |
| `bandit-report.json` | SAST findings |
| `gitleaks-report.json` | Secret detection results |
| `openapi-schema.json` | API specification for review |
| `semgrep.sarif` | Semgrep results (GitHub Security tab) |

## Remediation Process

| Severity | Action | SLA |
|----------|--------|-----|
| **Critical/High** | Block PR merge, fix immediately | Same day |
| **Medium** | Create issue, fix within sprint | 1 week |
| **Low** | Add to backlog | Next release |

## Configuration Files

| File | Purpose |
|------|---------|
| `.github/workflows/security-scan.yml` | CI/CD workflow |
| `.gitleaks.toml` | Secret detection rules |
| `backend/.bandit` | Bandit configuration |
| `backend/tests/test_security_owasp.py` | Security unit tests |

## Pre-commit Hooks

Security checks run locally before each commit:

```yaml
# In .pre-commit-config.yaml
- repo: https://github.com/PyCQA/bandit
  hooks:
    - id: bandit

- repo: https://github.com/gitleaks/gitleaks
  hooks:
    - id: gitleaks
```

## References

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [Bandit Documentation](https://bandit.readthedocs.io/)
- [Semgrep Rules](https://semgrep.dev/r)
- [Gitleaks](https://github.com/gitleaks/gitleaks)
- [Safety](https://pyup.io/safety/)
