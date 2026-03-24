# FROM python:3.13
# WORKDIR /app
# COPY . .
# RUN pip install gunicorn
# RUN pip install -r requirements.txt
# ENV PORT=80  ## ChatGPT: Overriding PORT to 80 breaks GCP routing
# CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 main:app

# Use a stable, lightweight Python image
FROM python:3.11-slim
# Prevent Python from writing .pyc files and buffering stdout
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# Set working directory
WORKDIR /app
# Install system dependencies (optional, but common)
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
# Copy dependency file first (better caching)
COPY requirements.txt .
# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt gunicorn
# Copy the rest of the app
COPY . .
# Use PORT from environment (Cloud Run injects it)
CMD exec gunicorn --bind :${PORT:-8080} --workers 1 --threads 8 main:app
