# ⚡ Quick Start Guide

## For the Impatient (2 Steps!)

### Step 1: Install Docker
- **Windows/Mac**: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux**: [Install Docker Engine](https://docs.docker.com/engine/install/)

### Step 2: Run It

**Linux/macOS:**
```bash
git clone <your-repo-url>
cd Moodle-Server
./start.sh
```

**Windows:**
```cmd
git clone <your-repo-url>
cd Moodle-Server
start.bat
```

**That's it!** Open http://localhost:8080 when it's done. 🎉

---

## What Just Happened?

The startup script:
1. ✅ Checked Docker is installed
2. ✅ Generated random secure passwords
3. ✅ Saved credentials to `edu-platform/CREDENTIALS.txt`
4. ✅ Pulled Docker images
5. ✅ Started all services

---

## Access Your Platform

| Service | URL | Use Case |
|---------|-----|----------|
| Moodle | http://localhost:8080 | Create courses, assignments, quizzes |
| JupyterHub | http://localhost:8000 | Python/R/Julia notebooks |
| VS Code | http://localhost:8443 | Code in the browser |
| AI API | http://localhost:8001/docs | AI assistant (needs API key) |

**Login**: Use `admin` and the password from `CREDENTIALS.txt`

---

## Common Tasks

### View Logs
```bash
# Linux/macOS
./stop.sh logs

# Windows
docker compose -f edu-platform/docker-compose.yml logs -f
```

### Stop Platform
```bash
# Linux/macOS
./stop.sh

# Windows
stop.bat
```

### Restart
```bash
# Linux/macOS
./stop.sh && ./start.sh

# Windows
stop.bat then start.bat
```

### Change Passwords
1. Edit `edu-platform/.env`
2. Run `./stop.sh && ./start.sh`

### Remove Everything (Fresh Start)
```bash
cd edu-platform
docker compose down -v  # Deletes all data!
cd ..
./start.sh  # Start fresh
```

---

## Troubleshooting

### Services Not Starting?
```bash
# Check Docker is running
docker info

# Check service status
docker compose -f edu-platform/docker-compose.yml ps

# View errors
docker compose -f edu-platform/docker-compose.yml logs
```

### Port Already in Use?
Edit `edu-platform/docker-compose.override.yml` and change the ports:
```yaml
services:
  moodle:
    ports:
      - "9090:8080"  # Change 8080 to 9090
```

### Out of Memory?
Reduce memory limits in `edu-platform/.env`:
```bash
JUPYTER_MEMORY_LIMIT=512M  # Was 1G
```

### Need More Help?
See [README.md](README.md) or [edu-platform/docs/TROUBLESHOOTING.md](edu-platform/docs/TROUBLESHOOTING.md)

---

## Next Steps

1. **Create a Course in Moodle**
   - Login at http://localhost:8080
   - Site Administration → Courses → Add a new course

2. **Try JupyterHub**
   - Login at http://localhost:8000
   - Create a notebook → Select Python/R/Julia kernel

3. **Explore VS Code**
   - Open http://localhost:8443
   - Create a new file and start coding

4. **Enable AI Features** (Optional)
   - Get API key from [DeepSeek](https://platform.deepseek.com)
   - Edit `edu-platform/.env`
   - Set `DEEPSEEK_API_KEY=sk-your-key`
   - Restart platform

---

## Production Deployment

For deploying to a real server with HTTPS and custom domain:
👉 See [edu-platform/README.md](edu-platform/README.md)

---

**Ready to go deeper?** Check the [main README](README.md) for architecture details and advanced configuration.
