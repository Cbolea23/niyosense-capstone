# Production Dockerfile for NiyoSense Backend (Django + DRF)
FROM python:3.12-slim

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies for PostgreSQL (libpq-dev) and C-extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /app/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application source code
COPY . /app/

# Create persistent storage directories for static and media files
RUN mkdir -p /app/media /app/static

# Normalize line endings and make entrypoint script executable
RUN sed -i -e 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

EXPOSE 8000

# Default entrypoint runs database migrations, collects static assets, and launches Gunicorn
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
