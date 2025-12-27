# JupyterHub with DockerSpawner and Native Authenticator
FROM jupyterhub/jupyterhub:4

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Create directories
RUN mkdir -p /srv/jupyterhub /data

# Copy configuration
COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

WORKDIR /srv/jupyterhub

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/hub/health || exit 1

# Run JupyterHub
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
