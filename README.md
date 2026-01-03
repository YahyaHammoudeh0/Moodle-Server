# Educational Platform

A complete, self-hosted educational platform with **zero configuration**. Perfect for schools, universities, or personal learning.

```
    ███████╗██████╗ ██╗   ██╗    ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
    ██╔════╝██╔══██╗██║   ██║    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
    █████╗  ██║  ██║██║   ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
    ██╔══╝  ██║  ██║██║   ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
    ███████╗██████╔╝╚██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
    ╚══════╝╚═════╝  ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
```

## Features

| Service | Description |
|---------|-------------|
| **Moodle** | Learning Management System with plugins (STACK, H5P, gamification) |
| **JupyterHub** | Multi-user Python/R/Julia notebooks |
| **Code Server** | VS Code in your browser |
| **Ollama** | Local AI assistant integrated with Moodle |
| **Maxima** | Computer algebra system for STACK math questions |
| **RStudio** | R IDE for statistics |
| **SageMath** | Advanced mathematical software |
| **Grafana** | Monitoring dashboards |

---

## Quick Start

### One-Command Install

```bash
# Linux/macOS
./wizard.sh

# Windows
wizard.bat
```

The wizard asks one simple question:

### Two Installation Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **Personal** | No passwords, instant access | Self-learners, students, developers |
| **School** | Full auth, domain, SSL, SSO | Universities, schools, institutions |

---

## Personal Mode

**Zero friction learning** - everything works immediately with no passwords.

```bash
./wizard.sh
# Choose: 1) Personal Learning
# Select services based on your RAM
# Done!
```

Access URLs:
| Service | URL |
|---------|-----|
| Dashboard | http://localhost:8080 |
| Moodle | http://localhost:8081 |
| JupyterHub | http://localhost:8000 |
| Code Server | http://localhost:8844 |
| RStudio | http://localhost:8787 |
| SageMath | http://localhost:8888 |

**No passwords required!** All services auto-login.

---

## School Mode

**Full authentication** with SSO, SSL certificates, and user management.

```bash
./wizard.sh
# Choose: 2) School / Institution
# Enter your domain (e.g., myschool.edu)
# Enter admin email
# Enter school name
# Select services
# Done!
```

Features:
- Custom domain with automatic Let's Encrypt SSL
- OAuth2 SSO (Google, Microsoft, GitHub)
- Moodle user management
- Secure credential storage
- Production-ready configuration

Access URLs:
| Service | URL |
|---------|-----|
| Moodle | https://learn.yourdomain.edu |
| JupyterHub | https://jupyter.yourdomain.edu |
| Code Server | https://code.yourdomain.edu |

Credentials saved to: `edu-platform/CREDENTIALS.txt`

---

## System Requirements

| Profile | RAM | Users | Services |
|---------|-----|-------|----------|
| Minimal | 4GB | 20 | Moodle only |
| Standard | 8GB | 50 | + Jupyter, Code Server, AI |
| Enhanced | 16GB | 100 | + RStudio, SageMath, Monitoring |
| Full | 32GB | 500+ | Everything |

---

## Moodle Plugins

The platform includes these plugins:

- **STACK** - Math questions with computer algebra (Maxima backend)
- **H5P** - Interactive content (videos, quizzes, presentations)
- **Level Up!** - Gamification with XP and levels
- **Attendance** - Track student presence
- **Custom Certificate** - Generate course certificates
- **Tiles/Board** - Modern course formats

Install plugins after Moodle starts:
```bash
./edu-platform/scripts/setup-moodle-plugins.sh
```

### Sample STACK Courses

The repo includes sample courses to test STACK math questions:

| File | Description |
|------|-------------|
| `STACK-demo.mbz` | Full demo with hundreds of STACK questions |
| `STACK-syntax-quiz.mbz` | Tutorial for learning STACK syntax |
| `HELM-questions.mbz` | Engineering math questions |

**To import a sample course:**
1. Log into Moodle as admin
2. Go to **Site Administration > Courses > Restore**
3. Upload a `.mbz` file from `edu-platform/moodle/sample-courses/`
4. Follow the restore wizard

These courses include graph plotting, randomized variables, and step-by-step feedback.

---

## AI Integration

The platform includes **Ollama** for local AI:

```bash
# Pull a model
docker exec ollama ollama pull llama3.2
```

Configure in Moodle:
1. Go to Site Administration > AI
2. Add Ollama provider: `http://ollama:11434`

AI features:
- Generate quiz questions
- Summarize course content
- Writing assistance

---

## Architecture

```
                    ┌──────────────┐
                    │    Caddy     │  (Reverse Proxy + SSL)
                    └──────┬───────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
┌──────▼──────┐    ┌───────▼───────┐    ┌──────▼──────┐
│   Moodle    │    │  JupyterHub   │    │ Code Server │
└──────┬──────┘    └───────┬───────┘    └─────────────┘
       │                   │
       │          ┌────────▼────────┐
       │          │ Jupyter Notebooks│ (Docker spawned)
       │          └─────────────────┘
       │
┌──────▼──────┐    ┌───────────────┐    ┌─────────────┐
│  PostgreSQL │    │     Redis     │    │   Ollama    │
└─────────────┘    └───────────────┘    └─────────────┘
       │
┌──────▼──────┐
│   Maxima    │  (Math engine for STACK)
└─────────────┘
```

---

## Manual Setup

```bash
# Personal mode (no passwords)
cd edu-platform
cp templates/.env.personal .env
docker compose -f docker-compose.yml -f docker-compose.personal.yml up -d

# School mode (with authentication)
cd edu-platform
cp templates/.env.school .env
# Edit .env with your domain and settings
docker compose -f docker-compose.yml -f docker-compose.school.yml up -d
```

---

## Management

```bash
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Status
docker compose ps

# Update
docker compose pull && docker compose up -d
```

---

## Troubleshooting

### Moodle won't start
```bash
# Check logs
docker logs moodle

# SELinux fix (Fedora/RHEL)
sudo chcon -Rt svirt_sandbox_file_t edu-platform/
```

### JupyterHub can't spawn notebooks
```bash
# Build the notebook image first
cd edu-platform/jupyterhub
docker build -t edu-platform-notebook:latest -f Dockerfile.notebook .
```

### Out of memory
Reduce services or switch to a smaller profile.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `cd edu-platform/tests && npm test`
4. Submit a pull request

---

## License

MIT License - Use freely for education!

---

**Made for educators and learners**
