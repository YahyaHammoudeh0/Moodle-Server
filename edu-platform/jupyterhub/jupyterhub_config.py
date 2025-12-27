"""
JupyterHub Configuration
========================
Multi-user Jupyter notebook server with Docker spawner
Target: 50 concurrent users on 8GB RAM
"""

import os
import sys

# ===========================================
# JupyterHub Core Configuration
# ===========================================
c = get_config()  # noqa

# Bind to all interfaces
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000

# Hub internal URL (for spawned containers to connect back)
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_connect_ip = 'jupyterhub'

# ===========================================
# Database Configuration (PostgreSQL)
# ===========================================
db_host = os.environ.get('POSTGRES_HOST', 'postgres')
db_name = os.environ.get('POSTGRES_DB', 'jupyterhub_db')
db_user = os.environ.get('POSTGRES_USER', 'jupyterhub')
db_pass = os.environ.get('POSTGRES_PASSWORD', '')

c.JupyterHub.db_url = f'postgresql://{db_user}:{db_pass}@{db_host}:5432/{db_name}'

# ===========================================
# Authentication - Native Authenticator
# ===========================================
from nativeauthenticator import NativeAuthenticator

c.JupyterHub.authenticator_class = NativeAuthenticator

# Admin user from environment
admin_user = os.environ.get('JUPYTERHUB_ADMIN', 'admin')
c.Authenticator.admin_users = {admin_user}

# Allow anyone to sign up (admin must approve)
c.NativeAuthenticator.open_signup = True

# Require admin approval for new users
c.NativeAuthenticator.ask_email_on_signup = True

# Minimum password length
c.NativeAuthenticator.minimum_password_length = 8

# Allow admins to create users
c.NativeAuthenticator.enable_signup = True

# ===========================================
# Spawner - DockerSpawner
# ===========================================
from dockerspawner import DockerSpawner

c.JupyterHub.spawner_class = DockerSpawner

# Use custom notebook image
c.DockerSpawner.image = 'edu-platform-notebook:latest'

# Network configuration
network_name = os.environ.get('DOCKER_NETWORK_NAME', 'edu-platform_backend')
c.DockerSpawner.network_name = network_name
c.DockerSpawner.use_internal_ip = True

# Remove containers when they stop
c.DockerSpawner.remove = True

# Spawner timeout (allow time for image pull on first run)
c.DockerSpawner.start_timeout = 120
c.DockerSpawner.http_timeout = 60

# ===========================================
# Resource Limits (Critical for 8GB RAM)
# ===========================================
memory_limit = os.environ.get('JUPYTER_MEMORY_LIMIT', '1G')
cpu_limit = float(os.environ.get('JUPYTER_CPU_LIMIT', '0.5'))

c.DockerSpawner.mem_limit = memory_limit
c.DockerSpawner.cpu_limit = cpu_limit

# Memory guarantee (minimum)
c.DockerSpawner.mem_guarantee = '256M'

# ===========================================
# Persistent Storage
# ===========================================
# Mount user home directories
c.DockerSpawner.volumes = {
    'jupyter-user-{username}': '/home/jovyan/work',
    'jupyter-shared': {'bind': '/home/jovyan/shared', 'mode': 'ro'},
}

# Notebook directory inside container
c.DockerSpawner.notebook_dir = '/home/jovyan'

# ===========================================
# Concurrent Spawn Limit
# ===========================================
# Limit concurrent spawns to prevent memory exhaustion
c.JupyterHub.concurrent_spawn_limit = 10

# Active server limit per user
c.JupyterHub.active_server_limit = 1

# ===========================================
# Idle Culler - Shut down inactive notebooks
# ===========================================
# Cull idle notebooks after 30 minutes
c.JupyterHub.services = [
    {
        'name': 'idle-culler',
        'command': [
            sys.executable,
            '-m', 'jupyterhub_idle_culler',
            '--timeout=1800',  # 30 minutes
            '--cull-every=300',  # Check every 5 minutes
            '--max-age=0',  # No maximum age
            '--concurrency=5',
        ],
        'admin': True,
    }
]

# ===========================================
# Security
# ===========================================
# Generate a secure cookie secret
c.JupyterHub.cookie_secret_file = '/data/jupyterhub_cookie_secret'

# Proxy auth token
c.ConfigurableHTTPProxy.auth_token = os.environ.get(
    'CONFIGPROXY_AUTH_TOKEN',
    os.urandom(32).hex()
)

# ===========================================
# Logging
# ===========================================
c.JupyterHub.log_level = 'INFO'

# Debug mode from environment
if os.environ.get('JUPYTERHUB_DEBUG', 'false').lower() == 'true':
    c.JupyterHub.log_level = 'DEBUG'

# ===========================================
# Custom Templates (Optional)
# ===========================================
# Uncomment to use custom templates
# c.JupyterHub.template_paths = ['/srv/jupyterhub/templates']

# ===========================================
# Post-Spawn Hooks (Optional)
# ===========================================
def pre_spawn_hook(spawner):
    """Hook called before spawning a user server."""
    username = spawner.user.name
    spawner.environment['NB_USER'] = username
    # Add any custom environment variables
    spawner.environment['JUPYTER_ENABLE_LAB'] = 'yes'

c.DockerSpawner.pre_spawn_hook = pre_spawn_hook

# ===========================================
# Admin Configuration
# ===========================================
# Allow admin to access user servers
c.JupyterHub.admin_access = True

# Shutdown on logout
c.JupyterHub.shutdown_on_logout = False

# ===========================================
# URL Configuration
# ===========================================
# Base URL (if behind reverse proxy with path prefix)
# c.JupyterHub.base_url = '/jupyter/'

# Trust X-Forwarded headers from reverse proxy
c.JupyterHub.trust_user_provided_tokens = False
