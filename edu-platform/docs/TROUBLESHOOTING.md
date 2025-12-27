# Troubleshooting Guide

Common issues and solutions for the Educational Platform.

## Quick Diagnostics

Run these commands first to gather information:

```bash
# Check all services
docker compose ps

# View recent logs
docker compose logs --tail=50

# Check resource usage
docker stats --no-stream

# Check disk space
df -h

# Check memory
free -m
```

## Service-Specific Issues

### Moodle

#### Moodle Won't Start

**Symptoms**: Container exits or restarts continuously

**Check logs:**
```bash
docker compose logs moodle
```

**Common causes and solutions:**

1. **Database connection failed**
   ```bash
   # Check if PostgreSQL is running
   docker compose ps postgres

   # Test database connection
   docker compose exec postgres pg_isready

   # Check database exists
   docker compose exec postgres psql -U postgres -l
   ```

2. **Insufficient memory**
   ```bash
   # Check memory usage
   docker stats --no-stream moodle

   # Increase limit in docker-compose.yml if needed
   ```

3. **File permission issues**
   ```bash
   # Check moodledata permissions
   docker compose exec moodle ls -la /bitnami/moodledata

   # Fix permissions
   docker compose exec moodle chown -R 1001:1001 /bitnami/moodledata
   ```

#### Moodle Slow Performance

**Solutions:**

1. **Enable Redis caching** (already configured)
   - Verify Redis is running: `docker compose ps redis`

2. **Increase PHP memory**
   - Edit `docker-compose.yml`, increase `PHP_MEMORY_LIMIT`

3. **Check for cron issues**
   ```bash
   # Run cron manually
   docker compose exec moodle php /bitnami/moodle/admin/cli/cron.php
   ```

#### Upload Errors

**"Maximum upload size exceeded"**

1. Check `.env` settings
2. Verify in Moodle: Site admin → Server → PHP info

**"Unable to save file"**

```bash
# Check disk space
docker compose exec moodle df -h /bitnami/moodledata

# Check permissions
docker compose exec moodle touch /bitnami/moodledata/test
```

### Maxima (STACK)

#### Maxima Connection Failed

**In Moodle STACK settings:**

1. **Verify container is running**
   ```bash
   docker compose ps maxima
   docker compose logs maxima
   ```

2. **Test Maxima endpoint**
   ```bash
   # From host
   docker compose exec maxima curl http://localhost:8080/health

   # From Moodle container
   docker compose exec moodle curl http://maxima:8080/health
   ```

3. **Check STACK settings in Moodle**
   - Platform type: Server
   - Server URL: `http://maxima:8080/`
   - Timeout: 30+ seconds

#### Maxima Timeout Errors

**"CAS timed out"**

1. **Increase timeout** in STACK settings (try 60 seconds)

2. **Simplify calculations**
   - Avoid complex symbolic operations
   - Use numerical methods when possible

3. **Check Maxima pool**
   ```bash
   # Restart Maxima
   docker compose restart maxima

   # Check pool status
   docker compose logs maxima | grep -i pool
   ```

4. **Increase pool size** (if memory allows)
   - Edit `.env`: `MAXIMA_POOL_SIZE=5`
   - Restart: `docker compose up -d maxima`

#### STACK Questions Not Evaluating

1. **Check Maxima syntax** in question variables
   - Test code directly:
     ```bash
     docker compose exec maxima maxima --batch-string="your_code_here$"
     ```

2. **Enable debugging** in STACK settings
   - Shows CAS errors in question preview

3. **Check Maxima libraries**
   - Required packages should be pre-installed

### JupyterHub

#### Users Can't Log In

1. **Check JupyterHub is running**
   ```bash
   docker compose ps jupyterhub
   docker compose logs jupyterhub | grep -i error
   ```

2. **Verify user exists**
   ```bash
   docker compose exec jupyterhub cat /srv/jupyterhub/jupyterhub_cookie_secret
   ```

3. **Reset user password** (Native Authenticator)
   - Admin must delete and re-create user

#### Notebook Server Won't Spawn

**"Spawn failed" or endless "pending" status**

1. **Check Docker socket access**
   ```bash
   docker compose exec jupyterhub docker ps
   ```

2. **Check notebook image exists**
   ```bash
   docker images | grep notebook

   # Rebuild if missing
   docker build -t edu-platform-notebook:latest ./jupyter-notebook/
   ```

3. **Check network**
   ```bash
   docker network ls | grep edu-platform
   ```

4. **Check resource limits**
   - Spawn may fail if no memory available
   ```bash
   docker stats --no-stream
   ```

5. **Clear stuck spawns**
   ```bash
   # Stop JupyterHub
   docker compose stop jupyterhub

   # Remove orphaned user containers
   docker ps -a | grep jupyter | awk '{print $1}' | xargs docker rm -f

   # Start JupyterHub
   docker compose start jupyterhub
   ```

#### Kernel Died

**In user notebook:**

1. **Memory exceeded**
   - Restart kernel
   - Reduce data size
   - Check `jupyter-resource-usage` extension

2. **Package conflict**
   - Restart kernel
   - Check import errors

3. **Timeout**
   - Increase kernel timeout in config

### Code Server

#### Can't Access Code Server

1. **Check container**
   ```bash
   docker compose ps code-server
   docker compose logs code-server
   ```

2. **Verify password**
   - Check `CODE_SERVER_PASSWORD` in `.env`

3. **Check Caddy routing**
   ```bash
   docker compose logs caddy | grep code
   ```

#### Extensions Not Loading

1. **Reinstall extension**
   - Extensions → Install from VSIX

2. **Check extension compatibility**
   - Some extensions don't work in web version

3. **Check resources**
   - Code Server may need more memory

### DeepSeek Proxy

#### API Errors

**"DeepSeek API error"**

1. **Check API key**
   ```bash
   # Test directly
   curl -X POST https://api.deepseek.com/v1/chat/completions \
     -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"Hello"}]}'
   ```

2. **Check proxy logs**
   ```bash
   docker compose logs deepseek-proxy
   ```

3. **Verify environment variables**
   ```bash
   docker compose exec deepseek-proxy env | grep DEEPSEEK
   ```

**"Rate limit exceeded"**

- Wait and retry
- Check rate limit settings in `main.py`

#### Connection Refused

1. **Check container**
   ```bash
   docker compose ps deepseek-proxy
   ```

2. **Test locally**
   ```bash
   docker compose exec deepseek-proxy curl http://localhost:8000/health
   ```

### PostgreSQL

#### Database Connection Failed

1. **Check container**
   ```bash
   docker compose ps postgres
   docker compose logs postgres
   ```

2. **Test connection**
   ```bash
   docker compose exec postgres psql -U postgres -c "SELECT 1"
   ```

3. **Check credentials**
   - Verify `POSTGRES_PASSWORD` in `.env`

#### Database Full

1. **Check disk usage**
   ```bash
   docker compose exec postgres du -sh /var/lib/postgresql/data
   ```

2. **Vacuum database**
   ```bash
   docker compose exec postgres vacuumdb -U postgres --all --analyze
   ```

3. **Clear old data** (careful!)
   - Remove old Moodle logs
   - Clear JupyterHub session data

### Redis

#### Redis Connection Refused

1. **Check container**
   ```bash
   docker compose ps redis
   docker compose exec redis redis-cli ping
   ```

2. **Check memory limit**
   ```bash
   docker compose exec redis redis-cli info memory
   ```

3. **Clear cache if needed**
   ```bash
   docker compose exec redis redis-cli FLUSHALL
   ```

### Caddy (HTTPS/Proxy)

#### SSL Certificate Issues

**"Certificate not valid"**

1. **Check DNS records**
   ```bash
   dig learn.YOURDOMAIN.com
   dig jupyter.YOURDOMAIN.com
   ```

2. **Check Caddy logs**
   ```bash
   docker compose logs caddy | grep -i cert
   ```

3. **Force certificate renewal**
   ```bash
   docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

4. **Check Let's Encrypt rate limits**
   - Staging CA has more lenient limits
   - Uncomment staging line in Caddyfile for testing

**"Too many redirects"**

1. Check `MOODLE_SSLPROXY=yes` is set
2. Verify Caddy config has correct proxy settings

#### Service Not Accessible

1. **Check Caddy routing**
   ```bash
   docker compose logs caddy
   ```

2. **Verify internal connectivity**
   ```bash
   docker compose exec caddy wget -qO- http://moodle:8080/
   ```

3. **Check firewall**
   ```bash
   sudo ufw status
   ```

## System-Level Issues

### Out of Memory

**Symptoms:**
- Containers killed (OOMKilled)
- Services unresponsive
- SSH slow or unresponsive

**Solutions:**

1. **Check current usage**
   ```bash
   free -m
   docker stats --no-stream
   ```

2. **Add swap** (if not present)
   ```bash
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Reduce service memory**
   - Edit `docker-compose.yml` memory limits
   - Reduce Maxima pool size
   - Lower Jupyter memory per user

4. **Restart memory-heavy services**
   ```bash
   docker compose restart moodle jupyterhub
   ```

5. **Identify memory hogs**
   ```bash
   docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
   ```

### Disk Space Full

1. **Check usage**
   ```bash
   df -h
   docker system df
   ```

2. **Clean up Docker**
   ```bash
   # Remove unused images
   docker image prune -f

   # Remove build cache
   docker builder prune -f

   # Remove unused volumes (careful!)
   docker volume prune -f
   ```

3. **Clean up logs**
   ```bash
   # Truncate Docker logs
   truncate -s 0 /var/lib/docker/containers/*/*-json.log
   ```

4. **Check backup size**
   ```bash
   du -sh /opt/edu-platform/backups
   ```

### High CPU Usage

1. **Identify cause**
   ```bash
   docker stats
   htop
   ```

2. **Common causes:**
   - Moodle cron running
   - Maxima calculations
   - Jupyter kernel execution
   - Backup script running

3. **Limit CPU**
   - Already configured in docker-compose.yml

### Network Issues

#### Services Can't Communicate

1. **Check network exists**
   ```bash
   docker network ls
   docker network inspect edu-platform_backend
   ```

2. **Recreate network**
   ```bash
   docker compose down
   docker compose up -d
   ```

3. **Check DNS resolution**
   ```bash
   docker compose exec moodle ping postgres
   ```

## Recovery Procedures

### Complete System Recovery

If everything is broken:

```bash
# 1. Stop all services
docker compose down

# 2. Remove containers (keeps volumes)
docker compose rm -f

# 3. Recreate containers
docker compose up -d

# 4. Check health
docker compose ps
```

### Restore from Backup

```bash
# See restore.sh for full procedure
./scripts/restore.sh backups/edu-platform-backup-*.tar.gz
```

### Factory Reset (Nuclear Option)

**WARNING: This deletes all data!**

```bash
# Stop and remove everything
docker compose down -v

# Remove all platform data
sudo rm -rf /opt/edu-platform/backups/*

# Rebuild from scratch
docker compose up -d --build
```

## Getting Help

### Information to Gather

Before asking for help, collect:

1. **Service logs**
   ```bash
   docker compose logs > logs.txt
   ```

2. **Service status**
   ```bash
   docker compose ps > status.txt
   ```

3. **Resource usage**
   ```bash
   docker stats --no-stream > resources.txt
   free -m >> resources.txt
   df -h >> resources.txt
   ```

4. **Configuration** (remove passwords!)
   ```bash
   cat docker-compose.yml > config.txt
   cat .env | grep -v PASSWORD | grep -v KEY > config.txt
   ```

### Support Channels

- Check documentation first
- Search existing issues
- Create detailed bug report with logs
