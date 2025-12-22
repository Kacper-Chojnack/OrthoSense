# Stage 1: Builder
FROM python:3.13-slim as builder

WORKDIR /app

# Install system dependencies required for building and OpenCV
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Install CPU-only PyTorch first to save space (Crucial for CI/CD & App Runner)
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Copy dependency definition
COPY pyproject.toml .

# Install dependencies
# We install with [ai-full] to ensure all AI capabilities are present
RUN pip install --no-cache-dir ".[ai-full]"

# Stage 2: Runtime
FROM python:3.13-slim

WORKDIR /app

# Install runtime system dependencies (OpenCV requires these)
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Create a non-root user for security
RUN useradd -m -u 1000 orthosense && \
    chown -R orthosense:orthosense /app

USER orthosense

# Expose the port
EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Run the application
# Using --proxy-headers for running behind Nginx/AWS App Runner
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
