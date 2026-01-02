# 🧙 Setup Wizard Guide

## Overview

The Educational Platform now includes an **interactive setup wizard** that helps you configure services based on your available system resources (RAM, CPU, disk space).

---

## 🚀 Quick Start

### First Time Setup

```bash
git clone <your-repo>
cd Moodle-Server
./wizard.sh
```

The wizard will:
1. ✅ Detect your system resources (RAM, CPU, disk)
2. ✅ Recommend a configuration profile
3. ✅ Let you choose services to enable
4. ✅ Generate configuration automatically
5. ✅ Optionally start the platform

---

## 📊 Configuration Profiles

### 1️⃣ MINIMAL (4GB RAM minimum)

**Services Included:**
- PostgreSQL Database
- Redis Cache
- Moodle LMS
- Caddy Reverse Proxy

**Best For:**
- Testing and development
- Small classes (<20 students)
- Limited resources
- Quick demos

**Resource Usage:** ~2.5GB RAM

---

### 2️⃣ STANDARD (8GB RAM recommended)

**All Minimal Services PLUS:**
- ✅ Maxima CAS (for STACK math questions)
- ✅ JupyterHub (Python, R, Julia, Octave notebooks)
- ✅ Code Server (VS Code in browser)
- ✅ AI Assistant (DeepSeek proxy)

**Best For:**
- Full educational platform
- 50 concurrent users
- Complete teaching environment
- STEM courses

**Resource Usage:** ~6GB RAM

---

### 3️⃣ ENHANCED (16GB RAM recommended)

**All Standard Services PLUS:**
- ✅ RStudio Server (R IDE with Shiny support)
- ✅ SageMath (Advanced mathematical software)
- ✅ Grafana (Monitoring dashboard)
- ✅ Prometheus (Metrics collection)

**Best For:**
- Advanced courses
- 100+ concurrent users
- Heavy computational work
- Production deployments
- Data science programs

**Resource Usage:** ~12GB RAM

---

### 4️⃣ FULL (32GB RAM recommended)

**All Enhanced Services PLUS:**
- ✅ Gitea (Lightweight Git server)
- ✅ n8n (Workflow automation)
- ✅ Portainer (Docker management UI)

**Best For:**
- Institution-wide deployment
- 500+ users
- Complete DevOps environment
- Advanced automation
- Full-featured platform

**Resource Usage:** ~20GB RAM

---

### 5️⃣ CUSTOM

**Pick and choose exactly what you need!**

The wizard will show you each optional service with its RAM requirements, allowing you to build a custom configuration.

---

## 🔧 Optional Services Detail

### RStudio Server
- **RAM:** 1GB
- **Port:** 8787
- **Features:**
  - Full RStudio IDE in browser
  - Shiny app development
  - R Markdown support
  - Package management
  - Git integration

### SageMath
- **RAM:** 2GB
- **Port:** 8888
- **Features:**
  - Advanced symbolic math
  - Jupyter interface
  - Number theory, algebra, calculus
  - Mathematical plotting
  - Computational research

### Grafana
- **RAM:** 256MB
- **Port:** 3000
- **Features:**
  - Real-time dashboards
  - Resource monitoring
  - User analytics
  - Custom visualizations
  - Alert notifications

### Prometheus
- **RAM:** 512MB
- **Port:** 9090
- **Features:**
  - Metrics collection
  - Time-series database
  - Query language (PromQL)
  - Service monitoring
  - 30-day retention

### Gitea
- **RAM:** 512MB
- **Ports:** 3001 (HTTP), 2222 (SSH)
- **Features:**
  - Lightweight Git server
  - Repository management
  - Issue tracking
  - Pull requests
  - Organizations & teams
  - CI/CD integration

### n8n
- **RAM:** 512MB
- **Port:** 5678
- **Features:**
  - Workflow automation
  - 200+ integrations
  - Visual workflow editor
  - Scheduled tasks
  - Webhook support
  - API connections

### Portainer
- **RAM:** 128MB
- **Ports:** 9000, 8000
- **Features:**
  - Docker management UI
  - Container control
  - Image management
  - Volume management
  - Network configuration
  - Stack deployment

---

## 🎯 Running the Wizard

### Interactive Mode

```bash
./wizard.sh
```

**The wizard will:**
1. Display your system resources
2. Show available profiles
3. Recommend a profile based on your RAM
4. Let you choose a profile (1-5)
5. If custom: let you select individual services
6. Generate configuration files
7. Ask if you want to start immediately

### Example Flow

```
╔═══════════════════════════════════════════════════════════════╗
║           🎓  Educational Platform Setup Wizard              ║
╚═══════════════════════════════════════════════════════════════╝

ℹ Detecting system resources...

  ✓ RAM:        16 GB
  ✓ CPU Cores:  8
  ✓ Disk Space: 200 GB

Available Configuration Profiles:

1) MINIMAL - 4GB RAM minimum
2) STANDARD - 8GB RAM recommended
3) ENHANCED - 16GB RAM recommended
4) FULL - 32GB RAM recommended
5) CUSTOM - Pick individual services

ℹ Based on 16GB RAM, we recommend: ENHANCED

Choose profile [1-5]: 3

ℹ Generating configuration...
✓ Configuration saved

═══════════════════════════════════════════════════════════════
  Configuration Summary
═══════════════════════════════════════════════════════════════

  Profile: enhanced
  System RAM: 16GB

  Core Services (Always Enabled):
    • PostgreSQL Database
    • Redis Cache
    • Moodle LMS
    • Caddy Reverse Proxy

  Optional Services (Enabled):
    • Maxima CAS (for STACK math)
    • JupyterHub (Python/R/Julia notebooks)
    • VS Code in Browser
    • AI Assistant API
    • RStudio Server (R IDE)
    • SageMath (Advanced Math)
    • Grafana (Monitoring Dashboard)
    • Prometheus (Metrics)

═══════════════════════════════════════════════════════════════

✓ Setup wizard complete!

Start platform now? [Y/n]
```

---

## 📝 Generated Files

After running the wizard, these files are created:

### `.wizard-config`
```bash
# Educational Platform Wizard Configuration
PROFILE=enhanced
TOTAL_RAM=16
TOTAL_CORES=8
ENABLED_SERVICES="maxima jupyterhub code-server deepseek-proxy rstudio sagemath grafana prometheus"
```

### `.env` (updated)
```bash
COMPOSE_PROFILES=maxima,jupyterhub,code-server,deepseek-proxy,rstudio,sagemath,grafana,prometheus
```

### `SERVICES.md`
A markdown file listing all enabled services with their access URLs.

---

## 🔄 Changing Configuration

### Re-run the Wizard

```bash
./wizard.sh
```

This will update your configuration. Stop and restart the platform:

```bash
./stop.sh
./start.sh
```

### Manual Configuration

Edit `.env` and change the `COMPOSE_PROFILES` line:

```bash
# Enable only JupyterHub and RStudio
COMPOSE_PROFILES=jupyterhub,rstudio

# Enable everything
COMPOSE_PROFILES=maxima,jupyterhub,code-server,deepseek-proxy,rstudio,sagemath,grafana,prometheus,gitea,n8n,portainer

# Disable all optional services
COMPOSE_PROFILES=
```

Then restart:

```bash
./stop.sh && ./start.sh
```

---

## 📊 Resource Planning

### How Much RAM Do I Need?

| Profile | Base RAM | + Users | Total | Concurrent Users |
|---------|----------|---------|-------|------------------|
| Minimal | 2.5GB | 1GB | 3.5GB | 20 |
| Standard | 4GB | 2GB | 6GB | 50 |
| Enhanced | 8GB | 4GB | 12GB | 100 |
| Full | 12GB | 8GB | 20GB | 200+ |

### Service RAM Breakdown

| Service | RAM Usage | Notes |
|---------|-----------|-------|
| PostgreSQL | 1.5GB | Shared database |
| Moodle | 1.5GB | PHP + web server |
| Redis | 256MB | Session cache |
| Maxima | 350MB | 3 worker pool |
| JupyterHub | 512MB | Hub only (notebooks separate) |
| Code Server | 512MB | Shared instance |
| AI Proxy | 128MB | FastAPI service |
| RStudio | 1GB | Per instance |
| SageMath | 2GB | Jupyter interface |
| Grafana | 256MB | Dashboard |
| Prometheus | 512MB | Metrics storage |
| Gitea | 512MB | Git server |
| n8n | 512MB | Workflow engine |
| Portainer | 128MB | UI only |

---

## 🎓 Recommended Profiles by Use Case

### Computer Science Department
**Profile:** ENHANCED
- Moodle for course management
- JupyterHub for Python/algorithms
- Code Server for projects
- Gitea for version control
- Grafana for resource monitoring

### Data Science Program
**Profile:** ENHANCED or FULL
- JupyterHub with Python, R, Julia
- RStudio for R-focused courses
- SageMath for advanced math
- Large RAM for student notebooks

### Mathematics Department
**Profile:** STANDARD or ENHANCED
- Moodle with STACK (Maxima)
- SageMath for advanced courses
- JupyterHub for computational math
- Symbolic computation tools

### General Education
**Profile:** MINIMAL or STANDARD
- Moodle for courses and quizzes
- Basic content delivery
- Assignments and grading
- Cost-effective deployment

### K-12 School
**Profile:** MINIMAL
- Moodle for lesson management
- Simple quizzes and assignments
- Parent communication
- Minimal resource requirements

### Research Lab
**Profile:** FULL
- JupyterHub for data analysis
- RStudio for statistical computing
- SageMath for theoretical work
- Gitea for collaboration
- n8n for automation
- Complete workflow tools

---

## 🚨 Troubleshooting

### Wizard Won't Start

**Check Docker:**
```bash
docker info
```

**Make executable:**
```bash
chmod +x wizard.sh
```

### Service Won't Start

**Check logs:**
```bash
./stop.sh logs
```

**Check RAM:**
```bash
docker stats
```

**Reduce services:**
```bash
./wizard.sh  # Choose a lighter profile
```

### Out of Memory

**Symptoms:**
- Containers restarting
- Services killed by OOM
- Slow performance

**Solutions:**
1. Run wizard and choose lighter profile
2. Add swap space (Linux)
3. Close other applications
4. Upgrade system RAM

### Port Conflicts

Edit `edu-platform/docker-compose.override.yml` to change ports.

---

## 💡 Tips

1. **Start small** - Use MINIMAL first, add services as needed
2. **Monitor resources** - Use Grafana/Prometheus if enabled
3. **Plan for growth** - Leave RAM headroom for user notebooks
4. **Test locally** - Try ENHANCED locally before production
5. **Use profiles** - Don't manually edit compose files

---

## 🔗 Next Steps

After wizard completes:
1. Check `CREDENTIALS.txt` for passwords
2. Read `SERVICES.md` for access URLs
3. Start platform with `./start.sh`
4. Configure each service (see main README)
5. Create test courses/users

---

## 📚 Additional Resources

- **Main README**: Overview and features
- **QUICKSTART.md**: 2-step getting started
- **edu-platform/README.md**: Production deployment
- **edu-platform/docs/**: Service-specific guides

---

**Questions?** The wizard is designed to be self-explanatory, but if you're unsure:
- Choose STANDARD for most use cases
- Use CUSTOM to optimize for your exact needs
- Start with fewer services, add more later
