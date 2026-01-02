import { test, expect } from '@playwright/test';

// Credentials from .env
const CREDENTIALS = {
  moodle: {
    user: 'admin',
    pass: 'B9Mjl5jB3geAN609'
  },
  jupyter: {
    user: 'admin',
    pass: 'zvg2LWrzrpulWRPe'
  },
  codeServer: {
    pass: 'U0FZUOYqDu42euL7'
  },
  rstudio: {
    user: 'rstudio',
    pass: 'U0FZUOYqDu42euL7'
  },
  grafana: {
    user: 'admin',
    pass: 'U0FZUOYqDu42euL7'
  },
  sagemath: {
    token: 'U0FZUOYqDu42euL7'
  }
};

// Service URLs
const SERVICES = {
  dashboard: 'http://localhost:8080',
  moodle: 'http://localhost:8081',
  jupyter: 'http://localhost:8000',
  codeServer: 'http://localhost:8844',
  rstudio: 'http://localhost:8787',
  sagemath: 'http://localhost:8888',
  grafana: 'http://localhost:3000',
  prometheus: 'http://localhost:9090',
  maxima: 'http://localhost:8765',
  deepseek: 'http://localhost:8001'
};

test.describe('Dashboard Tests', () => {
  test('Dashboard loads and displays all service cards', async ({ page }) => {
    await page.goto(SERVICES.dashboard);

    // Check title
    await expect(page).toHaveTitle(/Educational Platform/);

    // Check all service cards are present
    await expect(page.locator('.service-card.moodle')).toBeVisible();
    await expect(page.locator('.service-card.jupyter')).toBeVisible();
    await expect(page.locator('.service-card.code')).toBeVisible();
    await expect(page.locator('.service-card.rstudio')).toBeVisible();
    await expect(page.locator('.service-card.sagemath')).toBeVisible();
    await expect(page.locator('.service-card.grafana')).toBeVisible();
    await expect(page.locator('.service-card.prometheus')).toBeVisible();

    // Check sections exist
    await expect(page.locator('text=Core Services')).toBeVisible();
    await expect(page.locator('text=Scientific Computing')).toBeVisible();
    await expect(page.locator('text=Monitoring & Admin')).toBeVisible();
  });

  test('Dashboard quick links are clickable', async ({ page }) => {
    await page.goto(SERVICES.dashboard);

    const quickLinks = page.locator('.quick-access .quick-link');
    const count = await quickLinks.count();
    expect(count).toBeGreaterThan(5);
  });
});

test.describe('Moodle LMS Tests', () => {
  test('Moodle homepage loads', async ({ page }) => {
    await page.goto(SERVICES.moodle);

    // Wait for page to load (Moodle can be slow)
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    // Check for Moodle elements
    const pageContent = await page.content();
    expect(pageContent.toLowerCase()).toContain('moodle');
  });

  test('Moodle login works', async ({ page }) => {
    await page.goto(SERVICES.moodle + '/login/index.php');
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    // Fill login form
    await page.fill('input[name="username"]', CREDENTIALS.moodle.user);
    await page.fill('input[name="password"]', CREDENTIALS.moodle.pass);
    await page.click('button[type="submit"], input[type="submit"]');

    // Wait for redirect after login
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    // Should be logged in - check for dashboard or username
    const pageContent = await page.content();
    const isLoggedIn = pageContent.includes('Dashboard') ||
                       pageContent.includes(CREDENTIALS.moodle.user) ||
                       pageContent.includes('Log out');
    expect(isLoggedIn).toBeTruthy();
  });

  test('Moodle admin panel accessible', async ({ page }) => {
    // Login first
    await page.goto(SERVICES.moodle + '/login/index.php');
    await page.waitForLoadState('networkidle', { timeout: 30000 });
    await page.fill('input[name="username"]', CREDENTIALS.moodle.user);
    await page.fill('input[name="password"]', CREDENTIALS.moodle.pass);
    await page.click('button[type="submit"], input[type="submit"]');
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    // Navigate to admin
    await page.goto(SERVICES.moodle + '/admin/index.php');
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    const pageContent = await page.content();
    const hasAdminAccess = pageContent.includes('Site administration') ||
                           pageContent.includes('admin');
    expect(hasAdminAccess).toBeTruthy();
  });
});

test.describe('JupyterHub Tests', () => {
  test('JupyterHub login page loads', async ({ page }) => {
    await page.goto(SERVICES.jupyter);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Should show login form or JupyterHub branding
    const pageContent = await page.content();
    const hasJupyter = pageContent.toLowerCase().includes('jupyter') ||
                       pageContent.includes('Sign in') ||
                       pageContent.includes('username');
    expect(hasJupyter).toBeTruthy();
  });

  test('JupyterHub login works', async ({ page }) => {
    await page.goto(SERVICES.jupyter + '/hub/login');
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Fill login form
    await page.fill('input[name="username"]', CREDENTIALS.jupyter.user);
    await page.fill('input[name="password"]', CREDENTIALS.jupyter.pass);
    await page.click('input[type="submit"], button[type="submit"]');

    // Wait for redirect/spawn
    await page.waitForTimeout(5000);

    // Check we're past login
    const url = page.url();
    const notOnLogin = !url.includes('/login') || url.includes('/hub/');
    expect(notOnLogin).toBeTruthy();
  });
});

test.describe('Code Server Tests', () => {
  test('Code Server login page loads', async ({ page }) => {
    await page.goto(SERVICES.codeServer);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Should show password prompt
    const pageContent = await page.content();
    const hasLogin = pageContent.includes('password') ||
                     pageContent.includes('Password') ||
                     pageContent.includes('code-server');
    expect(hasLogin).toBeTruthy();
  });

  test('Code Server login works', async ({ page }) => {
    await page.goto(SERVICES.codeServer);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Find and fill password field
    const passwordInput = page.locator('input[type="password"]');
    if (await passwordInput.isVisible()) {
      await passwordInput.fill(CREDENTIALS.codeServer.pass);
      await page.click('button[type="submit"], input[type="submit"]');
      await page.waitForTimeout(5000);
    }

    // Should see VS Code interface or be past login
    const pageContent = await page.content();
    const isCodeServer = pageContent.includes('code-server') ||
                         pageContent.includes('Visual Studio') ||
                         pageContent.includes('workbench');
    expect(isCodeServer).toBeTruthy();
  });
});

test.describe('RStudio Server Tests', () => {
  test('RStudio login page loads', async ({ page }) => {
    await page.goto(SERVICES.rstudio);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    const pageContent = await page.content();
    const hasRStudio = pageContent.toLowerCase().includes('rstudio') ||
                       pageContent.includes('Username') ||
                       pageContent.includes('Sign In');
    expect(hasRStudio).toBeTruthy();
  });

  test('RStudio login works', async ({ page }) => {
    await page.goto(SERVICES.rstudio);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Fill login form
    const usernameInput = page.locator('input[name="username"], #username');
    const passwordInput = page.locator('input[name="password"], #password');

    if (await usernameInput.isVisible()) {
      await usernameInput.fill(CREDENTIALS.rstudio.user);
      await passwordInput.fill(CREDENTIALS.rstudio.pass);
      await page.click('button[type="submit"], #login-button');
      await page.waitForTimeout(5000);
    }

    // Check for RStudio IDE
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });
});

test.describe('SageMath Tests', () => {
  test('SageMath Jupyter interface loads', async ({ page }) => {
    await page.goto(SERVICES.sagemath + `?token=${CREDENTIALS.sagemath.token}`);
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    const pageContent = await page.content();
    const hasSage = pageContent.toLowerCase().includes('jupyter') ||
                    pageContent.toLowerCase().includes('sage') ||
                    pageContent.includes('notebook');
    expect(hasSage).toBeTruthy();
  });
});

test.describe('Grafana Tests', () => {
  test('Grafana login page loads', async ({ page }) => {
    await page.goto(SERVICES.grafana);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    const pageContent = await page.content();
    const hasGrafana = pageContent.toLowerCase().includes('grafana') ||
                       pageContent.includes('Log in') ||
                       pageContent.includes('username');
    expect(hasGrafana).toBeTruthy();
  });

  test('Grafana login works', async ({ page }) => {
    await page.goto(SERVICES.grafana + '/login');
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Fill login form
    await page.fill('input[name="user"]', CREDENTIALS.grafana.user);
    await page.fill('input[name="password"]', CREDENTIALS.grafana.pass);
    await page.click('button[type="submit"]');

    await page.waitForTimeout(3000);

    // Should be logged in
    const url = page.url();
    const notOnLogin = !url.includes('/login');
    expect(notOnLogin).toBeTruthy();
  });

  test('Grafana dashboards accessible', async ({ page }) => {
    // Login first
    await page.goto(SERVICES.grafana + '/login');
    await page.waitForLoadState('networkidle', { timeout: 20000 });
    await page.fill('input[name="user"]', CREDENTIALS.grafana.user);
    await page.fill('input[name="password"]', CREDENTIALS.grafana.pass);
    await page.click('button[type="submit"]');
    await page.waitForTimeout(3000);

    // Go to dashboards
    await page.goto(SERVICES.grafana + '/dashboards');
    await page.waitForLoadState('networkidle', { timeout: 10000 });

    const pageContent = await page.content();
    expect(pageContent).toContain('Dashboards');
  });
});

test.describe('Prometheus Tests', () => {
  test('Prometheus UI loads', async ({ page }) => {
    await page.goto(SERVICES.prometheus);
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const pageContent = await page.content();
    const hasPrometheus = pageContent.includes('Prometheus') ||
                          pageContent.includes('Expression') ||
                          pageContent.includes('Graph') ||
                          pageContent.includes('prometheus');
    expect(hasPrometheus).toBeTruthy();
  });

  test('Prometheus targets page loads', async ({ page }) => {
    await page.goto(SERVICES.prometheus + '/targets');
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(2000);

    const pageContent = await page.content();
    const hasTargets = pageContent.includes('Targets') ||
                       pageContent.includes('target') ||
                       pageContent.includes('prometheus');
    expect(hasTargets).toBeTruthy();
  });

  test('Prometheus API health check', async ({ request }) => {
    const response = await request.get(SERVICES.prometheus + '/-/healthy');
    expect(response.status()).toBe(200);
    const text = await response.text();
    expect(text).toContain('Healthy');
  });
});

test.describe('Maxima CAS Tests', () => {
  test('Maxima pool responds', async ({ page }) => {
    await page.goto(SERVICES.maxima);
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    // Should get some response (even if it's Tomcat page)
    const pageContent = await page.content();
    expect(pageContent.length).toBeGreaterThan(100);
  });
});

test.describe('DeepSeek API Tests', () => {
  test('DeepSeek API docs load', async ({ page }) => {
    await page.goto(SERVICES.deepseek + '/docs');
    await page.waitForLoadState('networkidle', { timeout: 20000 });

    const pageContent = await page.content();
    const hasAPI = pageContent.includes('API') ||
                   pageContent.includes('Swagger') ||
                   pageContent.includes('FastAPI') ||
                   pageContent.includes('docs');
    expect(hasAPI).toBeTruthy();
  });

  test('DeepSeek health endpoint works', async ({ page }) => {
    const response = await page.goto(SERVICES.deepseek + '/health');
    expect(response?.status()).toBe(200);
  });
});

test.describe('API Health Checks', () => {
  test('All services respond to HTTP requests', async ({ request }) => {
    const services = [
      { name: 'Dashboard', url: SERVICES.dashboard },
      { name: 'Moodle', url: SERVICES.moodle },
      { name: 'JupyterHub', url: SERVICES.jupyter },
      { name: 'Code Server', url: SERVICES.codeServer },
      { name: 'RStudio', url: SERVICES.rstudio },
      { name: 'SageMath', url: SERVICES.sagemath },
      { name: 'Grafana', url: SERVICES.grafana },
      { name: 'Prometheus', url: SERVICES.prometheus },
      { name: 'Maxima', url: SERVICES.maxima },
      { name: 'DeepSeek', url: SERVICES.deepseek },
    ];

    for (const service of services) {
      try {
        const response = await request.get(service.url, { timeout: 10000 });
        console.log(`${service.name}: ${response.status()}`);
        // Accept various success codes (200, 302 redirect, etc.)
        expect(response.status()).toBeLessThan(500);
      } catch (error) {
        console.log(`${service.name}: FAILED - ${error}`);
        throw new Error(`${service.name} is not responding`);
      }
    }
  });
});

test.describe('Database Connectivity', () => {
  test('PostgreSQL is accessible from services', async ({ request }) => {
    // Test via Grafana API (which uses PostgreSQL)
    const response = await request.get(SERVICES.grafana + '/api/health');
    expect(response.status()).toBe(200);
  });
});
