# ==============================================================================
# Base Image: Python 3.11 slim for minimal footprint and security
# ==============================================================================
FROM python:3.11-slim

# Prevent Python from writing .pyc files to disk and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8081

# Set standard working directory
WORKDIR /app

# Install curl for Docker healthcheck instruction
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency definition first to leverage Docker layer caching
COPY requirements.txt .

# Install dependencies without caching wheels to keep image size small
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Security Best Practice: Create and switch to a non-privileged user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Document that the container listens on port 8081 as per requirements
EXPOSE 8081

# Container healthcheck targeting the /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8081/health || exit 1

# Production WSGI server (Gunicorn) binding on 0.0.0.0:8081 with 2 workers
CMD ["gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "app:app"]
