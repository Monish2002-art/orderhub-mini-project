FROM python:3.11-slim-buster

# Create a secure non-root user
RUN useradd -u 10001 orderhub

WORKDIR /app

# Install dependencies efficiently using caching layers
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ app/

# Switch to non-root user
USER orderhub

EXPOSE 8080

# Environment placeholders
ENV APP_VERSION=1.0.0 BUILD_NUMBER=unknown GIT_COMMIT=unknown

HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

CMD ["python", "app/app.py"]