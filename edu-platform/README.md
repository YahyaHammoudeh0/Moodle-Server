# Educational Platform

A production-ready Docker Compose setup for a self-hosted educational platform featuring Moodle LMS, JupyterHub, scientific computing tools, and AI assistance.

## Architecture

```
                                    ┌─────────────────────────────────────────────────┐
                                    │                   Internet                       │
                                    └─────────────────────────────────────────────────┘
                                                           │
                                                           │ HTTPS (443)
                                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                      Caddy                                               │
│                          (Reverse Proxy + Auto HTTPS)                                    │
│  learn.domain  │  jupyter.domain  │  code.domain  │  ai.domain                         │
└───────┬────────────────┬─────────────────┬────────────────┬─────────────────────────────┘
        │                │                 │                │
        ▼                ▼                 ▼                ▼
┌───────────────┐ ┌─────────────┐ ┌─────────────────┐ ┌─────────────────┐
│    Moodle     │ │ JupyterHub  │ │  Code Server    │ │ DeepSeek Proxy  │
│   (LMS)       │ │  (Notebooks)│ │  (VS Code)      │ │  (AI API)       │
│   :8080       │ │   :8000     │ │    :8080        │ │    :8000        │
└───────┬───────┘ └──────┬──────┘ └─────────────────┘ └─────────────────┘
        │                │
        │                │ Spawns containers
        │                ▼
        │         ┌─────────────────┐
        │         │ Jupyter Notebook│
        │         │ (Per-user)      │
        │         │ Python/R/Julia  │
        │         └─────────────────┘
        │
        ▼
┌───────────────┐
│    Maxima     │
│  (CAS Pool)   │
│   :8080       │
└───────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Backend Network                                         │
├─────────────────────────────────────────┬───────────────────────────────────────────────┤
│             PostgreSQL                   │                   Redis                       │
│         (moodle_db, jupyterhub_db)      │              (Session Cache)                  │
└─────────────────────────────────────────┴───────────────────────────────────────────────┘
```

## Features

### Learning Management
- **Moodle LMS**: Full-featured learning management system
- **STACK Plugin**: Computer-aided assessment for STEM subjects
- **Maxima CAS**: Computer algebra system for mathematical calculations

### Scientific Computing
- **JupyterHub**: Multi-user Jupyter notebook server
- **Python**: NumPy, SciPy, Pandas, Matplotlib, Scikit-learn, PyTorch, TensorFlow
- **R**: Tidyverse, ggplot2, Shiny, Caret
- **Julia**: Plots, DataFrames, DifferentialEquations, Flux
- **Octave**: MATLAB-compatible numerical computing

### Development Tools
- **Code Server**: VS Code in the browser
- **LaTeX**: Full TeX Live installation for document preparation
- **Git**: Version control integration

### AI Assistance
- **DeepSeek Proxy**: AI-powered tutoring with rate limiting and logging

## Prerequisites

- **Server**: Hetzner CCX13 or equivalent (2 dedicated vCPU, 8GB RAM, 80GB SSD)
- **OS**: Ubuntu 24.04 LTS
- **Domain**: With DNS A records pointing to server IP
- **SSL**: Automatic via Let's Encrypt (handled by Caddy)

### DNS Configuration

Create A records for:
- `learn.yourdomain.com` → Server IP
- `jupyter.yourdomain.com` → Server IP
- `code.yourdomain.com` → Server IP
- `ai.yourdomain.com` → Server IP

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/edu-platform.git
cd edu-platform

# 2. Run the setup script (as root)
sudo ./scripts/setup.sh

# 3. Edit configuration
nano .env

# 4. Start services
docker compose up -d

# 5. Check status
docker compose ps
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
nano .env
```

Key settings:

| Variable | Description |
|----------|-------------|
| `DOMAIN` | Your domain name (e.g., `example.com`) |
| `MOODLE_PASSWORD` | Moodle admin password |
| `POSTGRES_PASSWORD` | Database password |
| `JUPYTERHUB_ADMIN_PASSWORD` | JupyterHub admin password |
| `CODE_SERVER_PASSWORD` | VS Code access password |
| `DEEPSEEK_API_KEY` | Your DeepSeek API key |

## Post-Installation

### 1. Install STACK Plugin

See [docs/STACK_SETUP.md](docs/STACK_SETUP.md) for detailed instructions.

Quick steps:
1. Log into Moodle as admin
2. Go to Site Administration → Plugins → Install plugins
3. Upload STACK plugin zip
4. Configure Maxima connection: `http://maxima:8080`

### 2. Create JupyterHub Users

See [docs/JUPYTER_USAGE.md](docs/JUPYTER_USAGE.md) for detailed instructions.

Quick steps:
1. Log into JupyterHub as admin
2. Go to Admin panel
3. Add new users

### 3. Test Services

Run through the testing checklist:

- [ ] Moodle login works at `https://learn.DOMAIN`
- [ ] Can create a course and enroll students
- [ ] STACK plugin installed and Maxima connected
- [ ] JupyterHub login works at `https://jupyter.DOMAIN`
- [ ] Python, R, Julia kernels work
- [ ] Code Server accessible at `https://code.DOMAIN`
- [ ] AI proxy responds at `https://ai.DOMAIN/health`

## Memory Budget

The platform is optimized for 8GB RAM:

| Service | Memory Limit | Notes |
|---------|--------------|-------|
| PostgreSQL | 1.5GB | Shared buffers: 1GB |
| Moodle | 1.5GB | PHP memory: 512MB |
| Redis | 256MB | Cache only |
| Maxima (x3) | 1GB total | 3 pool processes |
| JupyterHub | 512MB | Hub process only |
| Jupyter Users | 1GB each | 2 concurrent heavy users |
| Code Server | 512MB | Shared instance |
| DeepSeek Proxy | 128MB | FastAPI |
| Caddy | 128MB | Reverse proxy |
| **System** | ~500MB | Buffer |

**Note**: 4GB swap is configured for memory spikes.

## Backup & Restore

### Create Backup

```bash
./scripts/backup.sh

# With remote upload
./scripts/backup.sh --remote
```

### Restore from Backup

```bash
./scripts/restore.sh backups/edu-platform-backup-YYYYMMDD_HHMMSS.tar.gz
```

### Automated Backups

Add to crontab for daily backups:

```bash
crontab -e

# Add this line for daily backup at 2 AM
0 2 * * * /opt/edu-platform/scripts/backup.sh >> /var/log/edu-backup.log 2>&1
```

## Updates

```bash
./scripts/update.sh
```

The update script:
1. Creates a backup
2. Pulls latest images
3. Rebuilds custom images
4. Restarts services
5. Verifies health

## Monitoring

### Service Status

```bash
docker compose ps
```

### Resource Usage

```bash
docker stats
```

### Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f moodle
```

### Caddy Access Logs

```bash
docker compose exec caddy cat /data/logs/moodle.log
```

## Scaling Guide

When to upgrade from CCX13:

| Symptom | Solution |
|---------|----------|
| Frequent OOM kills | Upgrade to 16GB RAM (CCX23) |
| Slow Jupyter spawns | Add CPU cores |
| Slow STACK questions | Increase Maxima pool |
| Disk space warnings | Add storage volume |

For 16GB RAM (CCX23), you can:
- Increase Jupyter memory limit to 2GB
- Increase Maxima pool to 5
- Add SageMath container
- Enable more concurrent Jupyter users

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

### Quick Fixes

**Services not starting:**
```bash
docker compose logs | grep -i error
docker compose restart
```

**Out of memory:**
```bash
docker stats
# Restart memory-heavy services
docker compose restart moodle jupyterhub
```

**SSL certificate issues:**
```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Security

- All services run on internal Docker network
- Only ports 80/443 exposed publicly
- Automatic HTTPS via Let's Encrypt
- Fail2ban for SSH brute-force protection
- Rate limiting on AI proxy
- Non-root containers where possible

## Uninstall

```bash
# Stop and remove containers
docker compose down

# Remove volumes (WARNING: deletes all data!)
docker compose down -v

# Remove images
docker rmi $(docker images -q 'edu-platform-*')

# Remove platform directory
rm -rf /opt/edu-platform
```

## Support

- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [STACK Setup Guide](docs/STACK_SETUP.md)
- [JupyterHub Usage Guide](docs/JUPYTER_USAGE.md)

## License

MIT License - See LICENSE file for details.
