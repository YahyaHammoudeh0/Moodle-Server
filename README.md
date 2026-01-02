# 🎓 Educational Platform

> **A complete educational stack that just works** - Clone, run, and start learning!

Includes **Moodle LMS**, **JupyterHub** (Python/R/Julia), **VS Code** in browser, **AI Assistant**, and more - all fully containerized and ready to run on any system with Docker.

**🆕 NEW:** Interactive setup wizard with RAM-based profiles! Choose from **MINIMAL** (4GB), **STANDARD** (8GB), **ENHANCED** (16GB), or **FULL** (32GB) configurations. See **[Setup Wizard Guide](SETUP_WIZARD.md)**.

---

## ⚡ Quick Start

### Prerequisites
- **Docker** installed ([Get Docker](https://www.docker.com/products/docker-desktop))
- That's it! No other dependencies needed.

### 🧙 Option 1: Setup Wizard (Recommended)

**Let the wizard configure based on your RAM:**

```bash
git clone <your-repo-url>
cd Moodle-Server
./wizard.sh  # Interactive configuration
```

Choose from:
- **MINIMAL** (4GB) - Core Moodle
- **STANDARD** (8GB) - + JupyterHub, Code Server, AI
- **ENHANCED** (16GB) - + RStudio, SageMath, Monitoring
- **FULL** (32GB) - + Gitea, n8n, Portainer
- **CUSTOM** - Pick individual services

📖 **[Full Wizard Guide →](SETUP_WIZARD.md)**

### ⚡ Option 2: Standard Setup

**Skip wizard, use defaults:**

```bash
git clone <your-repo-url>
cd Moodle-Server
./start.sh    # Linux/macOS
start.bat     # Windows
```

The platform will:
1. ✅ Auto-generate secure passwords
2. ✅ Start core services
3. ✅ Give you access URLs and credentials

---

## 📍 Access Services

Once started, access your platform at:

| Service | URL | Description |
|---------|-----|-------------|
| 📚 **Moodle LMS** | http://localhost:8080 | Full learning management system with STACK |
| 🔬 **JupyterHub** | http://localhost:8000 | Multi-user notebooks (Python, R, Julia, Octave) |
| 💻 **VS Code** | http://localhost:8443 | Code Server - VS Code in your browser |
| 🤖 **AI Assistant** | http://localhost:8001/docs | AI-powered tutoring API |

🔐 **Credentials**: Auto-generated and saved to `edu-platform/CREDENTIALS.txt`

---

## 🎯 What's Included?

### Learning Management
- **Moodle LMS** - Complete course management with quizzes, assignments, grading
- **STACK Plugin** - Advanced mathematical assessment for STEM courses
- **Maxima CAS** - Computer algebra system for symbolic math

### Scientific Computing
- **JupyterHub** - Multi-user environment with resource limits
- **Python** - NumPy, Pandas, Matplotlib, Scikit-learn, PyTorch, TensorFlow
- **R** - Tidyverse, ggplot2, Shiny, Caret
- **Julia** - DataFrames, Plots, DifferentialEquations, Flux
- **GNU Octave** - MATLAB-compatible numerical computing

### Development
- **Code Server** - Full VS Code with extensions
- **LaTeX** - Complete TeX Live for document preparation
- **Git** - Version control built-in

### Infrastructure
- **PostgreSQL** - Reliable database for Moodle & JupyterHub
- **Redis** - Session caching for performance
- **Caddy** - Automatic HTTPS reverse proxy (in production)

---

## 📊 Useful Commands

```bash
# View live logs
./stop.sh logs              # Linux/macOS
docker compose -f edu-platform/docker-compose.yml logs -f  # Windows

# Stop the platform
./stop.sh                   # Linux/macOS
stop.bat                    # Windows

# Restart the platform
./start.sh                  # Linux/macOS
start.bat                   # Windows

# Check service status
docker compose -f edu-platform/docker-compose.yml ps

# Remove everything (including data!)
cd edu-platform && docker compose down -v
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│           Your Browser                      │
└─────────────────┬───────────────────────────┘
                  │
     ┌────────────┼─────────────┐
     │            │             │
  :8080        :8000        :8443
     │            │             │
┌────┴───┐  ┌────┴───┐  ┌──────┴──────┐
│ Moodle │  │Jupyter │  │ Code Server │
└────┬───┘  └────┬───┘  └─────────────┘
     │           │
     └─────┬─────┘
           │
    ┌──────┴──────┐
    │             │
┌───┴────┐  ┌────┴────┐
│Postgres│  │  Redis  │
└────────┘  └─────────┘
```

---

## 🔧 Configuration

### Using Default Settings
The platform works out of the box with auto-generated credentials. No configuration needed!

### Custom Configuration
Want to customize? Edit `edu-platform/.env`:

```bash
# Generate default .env first
./start.sh

# Then customize
nano edu-platform/.env

# Restart to apply changes
./stop.sh && ./start.sh
```

Key settings you might want to change:
- `MOODLE_PASSWORD` - Admin password
- `JUPYTER_MEMORY_LIMIT` - Memory per user (default: 1G)
- `DEEPSEEK_API_KEY` - For AI features (get from [DeepSeek](https://platform.deepseek.com))

---

## 🚀 Production Deployment

This repository is designed to work **anywhere**:

### Local Development (Default)
- Uses localhost
- No DNS required
- Auto-generated credentials
- Development ports (8080, 8000, etc.)

### Production Server
For production deployment with custom domain and SSL:

1. See **[edu-platform/README.md](edu-platform/README.md)** for detailed instructions
2. Configure your domain in `.env`
3. Set up DNS A records
4. Deploy with `docker compose -f docker-compose.yml up -d` (production mode)

The setup script handles:
- Ubuntu server preparation
- Firewall configuration
- Automatic HTTPS with Let's Encrypt
- Security hardening
- Automatic backups

---

## 📖 Documentation

- **[Production Deployment Guide](edu-platform/README.md)** - Deploy to a server with domain
- **[STACK Setup](edu-platform/docs/STACK_SETUP.md)** - Configure mathematical assessments
- **[JupyterHub Usage](edu-platform/docs/JUPYTER_USAGE.md)** - Managing users and notebooks
- **[Troubleshooting](edu-platform/docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## 💾 Resource Requirements

### Minimum (Local Testing)
- **RAM**: 4GB
- **Disk**: 20GB
- **CPU**: 2 cores

### Recommended (Development)
- **RAM**: 8GB
- **Disk**: 40GB
- **CPU**: 4 cores

### Production (50 concurrent users)
- **RAM**: 8GB + 4GB swap
- **Disk**: 80GB SSD
- **CPU**: 2 dedicated cores (e.g., Hetzner CCX13)

---

## 🛡️ Security

### Local Development
- Services exposed on localhost only
- Auto-generated random passwords
- Suitable for learning and testing

### Production
- HTTPS enabled automatically via Let's Encrypt
- All services behind reverse proxy
- Firewall configured (only ports 80/443 open)
- Fail2ban for SSH protection
- Rate limiting on AI endpoints
- Security updates automated

---

## 📦 What Makes This Special?

✅ **Zero Configuration** - Works immediately after clone
✅ **Cross-Platform** - Windows, macOS, Linux
✅ **Self-Contained** - Everything in Docker, no host dependencies
✅ **Production Ready** - Same codebase for dev and production
✅ **Secure by Default** - Random passwords, proper isolation
✅ **Educational Focus** - STEM tools (STACK, Maxima, scientific libs)
✅ **Resource Efficient** - Optimized for 8GB RAM
✅ **Documented** - Clear guides for every use case

---

## 🤝 Contributing

Issues and pull requests welcome! This is designed to be:
- Easy to clone and run
- Easy to understand and modify
- Easy to deploy anywhere

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

---

## ❓ FAQ

**Q: Do I need to install Python, Node.js, or anything else?**
A: No! Everything runs in Docker. Just install Docker and you're done.

**Q: Can I use this on Windows?**
A: Yes! Just run `start.bat` instead of `start.sh`.

**Q: Is this secure for production?**
A: For production, follow the [deployment guide](edu-platform/README.md). The default localhost setup is for development only.

**Q: How do I customize the ports?**
A: Edit `edu-platform/docker-compose.override.yml` to change the port mappings.

**Q: Can I run this on a Raspberry Pi?**
A: ARM support depends on image availability. Some images (like Bitnami Moodle) may need ARM builds.

**Q: How much does this cost to run?**
A: Locally: $0. In production: ~$10-30/month for a VPS like Hetzner CCX13.

---

<div align="center">

**Made with ❤️ for educators and learners**

[Report Bug](https://github.com/yourusername/repo/issues) · [Request Feature](https://github.com/yourusername/repo/issues)

</div>
