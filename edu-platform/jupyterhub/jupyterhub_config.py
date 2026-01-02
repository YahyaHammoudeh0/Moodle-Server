"""
JupyterHub Configuration
========================
Multi-user Jupyter notebook server with Docker spawner
Supports both Personal (no-auth) and School (SSO) modes
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
# Authentication Mode Selection
# ===========================================
AUTH_MODE = os.environ.get('JUPYTERHUB_AUTH_MODE', 'native').lower()

if AUTH_MODE == 'dummy' or AUTH_MODE == 'none':
    # Personal Mode - No authentication required
    from jupyterhub.auth import DummyAuthenticator
    c.JupyterHub.authenticator_class = DummyAuthenticator
    c.DummyAuthenticator.password = None  # No password needed

    # Auto-login as default user
    default_user = os.environ.get('JUPYTERHUB_ADMIN', 'learner')
    c.Authenticator.admin_users = {default_user}
    c.Authenticator.allowed_users = {default_user}

elif AUTH_MODE == 'oauth' or AUTH_MODE == 'moodle':
    # School Mode - OAuth against Moodle
    try:
        from oauthenticator.generic import GenericOAuthenticator
        c.JupyterHub.authenticator_class = GenericOAuthenticator

        moodle_url = os.environ.get('MOODLE_URL', 'http://moodle:8080')
        c.GenericOAuthenticator.oauth_callback_url = f"{os.environ.get('JUPYTERHUB_URL', 'http://localhost:8000')}/hub/oauth_callback"
        c.GenericOAuthenticator.client_id = os.environ.get('OAUTH_CLIENT_ID', 'jupyterhub')
        c.GenericOAuthenticator.client_secret = os.environ.get('OAUTH_CLIENT_SECRET', '')
        c.GenericOAuthenticator.authorize_url = f"{moodle_url}/local/oauth/authorize.php"
        c.GenericOAuthenticator.token_url = f"{moodle_url}/local/oauth/token.php"
        c.GenericOAuthenticator.userdata_url = f"{moodle_url}/local/oauth/userinfo.php"
        c.GenericOAuthenticator.username_claim = 'username'
        c.GenericOAuthenticator.login_service = 'Moodle'

    except ImportError:
        # Fallback to native if oauth not installed
        AUTH_MODE = 'native'

if AUTH_MODE == 'native':
    # Default - Native Authenticator with signup
    from nativeauthenticator import NativeAuthenticator
    c.JupyterHub.authenticator_class = NativeAuthenticator

    admin_user = os.environ.get('JUPYTERHUB_ADMIN', 'admin')
    c.Authenticator.admin_users = {admin_user}

    c.NativeAuthenticator.open_signup = True
    c.NativeAuthenticator.ask_email_on_signup = True
    c.NativeAuthenticator.minimum_password_length = 8
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
# Resource Limits
# ===========================================
memory_limit = os.environ.get('JUPYTER_MEMORY_LIMIT', '1G')
cpu_limit = float(os.environ.get('JUPYTER_CPU_LIMIT', '0.5'))

c.DockerSpawner.mem_limit = memory_limit
c.DockerSpawner.cpu_limit = cpu_limit
c.DockerSpawner.mem_guarantee = '256M'

# ===========================================
# Persistent Storage
# ===========================================
c.DockerSpawner.volumes = {
    'jupyter-user-{username}': '/home/jovyan/work',
    'jupyter-shared': {'bind': '/home/jovyan/shared', 'mode': 'ro'},
}

c.DockerSpawner.notebook_dir = '/home/jovyan'

# ===========================================
# Concurrency Limits
# ===========================================
c.JupyterHub.concurrent_spawn_limit = 10
c.JupyterHub.active_server_limit = 1

# ===========================================
# Idle Culler
# ===========================================
c.JupyterHub.services = [
    {
        'name': 'idle-culler',
        'command': [
            sys.executable,
            '-m', 'jupyterhub_idle_culler',
            '--timeout=1800',
            '--cull-every=300',
            '--max-age=0',
            '--concurrency=5',
        ],
        'admin': True,
    }
]

# ===========================================
# Security
# ===========================================
c.JupyterHub.cookie_secret_file = '/data/jupyterhub_cookie_secret'
c.ConfigurableHTTPProxy.auth_token = os.environ.get(
    'CONFIGPROXY_AUTH_TOKEN',
    os.urandom(32).hex()
)

# ===========================================
# Logging
# ===========================================
c.JupyterHub.log_level = 'INFO'
if os.environ.get('JUPYTERHUB_DEBUG', 'false').lower() == 'true':
    c.JupyterHub.log_level = 'DEBUG'

# ===========================================
# Hooks
# ===========================================
def pre_spawn_hook(spawner):
    username = spawner.user.name
    spawner.environment['NB_USER'] = username
    spawner.environment['JUPYTER_ENABLE_LAB'] = 'yes'

c.DockerSpawner.pre_spawn_hook = pre_spawn_hook

# Admin access
c.JupyterHub.admin_access = True
c.JupyterHub.shutdown_on_logout = False
