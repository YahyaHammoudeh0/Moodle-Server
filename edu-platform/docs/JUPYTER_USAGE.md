# JupyterHub Usage Guide

This guide covers how to use JupyterHub on the educational platform, including user management, available kernels, and common tasks.

## Accessing JupyterHub

Access JupyterHub at: `https://jupyter.YOURDOMAIN.com`

## User Management

### Creating User Accounts

**Admin Interface:**
1. Log in as admin
2. Click **Admin** in the top menu
3. Click **Add Users**
4. Enter usernames (one per line)
5. Click **Add Users**

**Self-Registration (if enabled):**
1. Go to the JupyterHub login page
2. Click **Sign Up**
3. Enter username, email, and password
4. Wait for admin approval

### Managing Users

As admin, you can:
- **Start/Stop servers**: Control user notebook servers
- **Edit users**: Change admin status
- **Delete users**: Remove user accounts

### Bulk User Creation

For classes, create users via command line:

```bash
# Create users from list
docker compose exec jupyterhub python -c "
from jupyterhub import orm
from jupyterhub.app import JupyterHub
app = JupyterHub()
app.init_db()

users = ['student1', 'student2', 'student3']
for username in users:
    orm.User(name=username)
app.db.commit()
"
```

## Available Kernels

The custom notebook image includes:

| Kernel | Language | Use Case |
|--------|----------|----------|
| Python 3 | Python | General programming, data science |
| R | R | Statistics, visualization |
| Julia | Julia | Scientific computing |
| Octave | Octave | MATLAB-compatible computing |
| Bash | Shell | System commands |
| SQL | SQL | Database queries |

### Kernel-Specific Features

**Python 3:**
- NumPy, SciPy, Pandas
- Matplotlib, Seaborn, Plotly
- Scikit-learn, TensorFlow, PyTorch
- SymPy for symbolic math

**R:**
- Tidyverse (dplyr, ggplot2, tidyr)
- Shiny for interactive apps
- Caret for machine learning
- R Markdown support

**Julia:**
- Plots.jl for visualization
- DataFrames.jl for data handling
- DifferentialEquations.jl for ODEs
- Flux.jl for machine learning

**Octave:**
- Control systems toolbox
- Signal processing
- Image processing
- Statistics

## Working with Notebooks

### Creating a New Notebook

1. Click **New** → Select kernel
2. Or use File → New → Notebook

### Saving Work

- **Auto-save**: Notebooks auto-save periodically
- **Manual save**: Ctrl+S or File → Save
- **Checkpoints**: File → Save and Checkpoint

### Exporting Notebooks

File → Download as:
- **Notebook (.ipynb)**: Native format
- **Python (.py)**: Python script
- **HTML (.html)**: Static webpage
- **PDF via LaTeX**: Requires LaTeX (installed)
- **Markdown (.md)**: Markdown format

## Python Examples

### Scientific Computing

```python
import numpy as np
import matplotlib.pyplot as plt
from scipy import integrate

# Define a function
def f(x):
    return np.sin(x) * np.exp(-x/5)

# Plot
x = np.linspace(0, 10, 100)
plt.plot(x, f(x))
plt.title('Damped Sine Wave')
plt.xlabel('x')
plt.ylabel('f(x)')
plt.grid(True)
plt.show()

# Numerical integration
result, error = integrate.quad(f, 0, 10)
print(f"Integral from 0 to 10: {result:.4f}")
```

### Symbolic Math

```python
from sympy import *

# Define symbols
x, y = symbols('x y')

# Differentiation
f = x**3 + 2*x*y + y**2
df_dx = diff(f, x)
df_dy = diff(f, y)
print(f"∂f/∂x = {df_dx}")
print(f"∂f/∂y = {df_dy}")

# Integration
g = sin(x) * cos(x)
G = integrate(g, x)
print(f"∫ sin(x)cos(x) dx = {G}")

# Solve equations
eq = Eq(x**2 - 5*x + 6, 0)
solutions = solve(eq, x)
print(f"Solutions: {solutions}")
```

### Machine Learning

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

# Load data
iris = load_iris()
X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.3, random_state=42
)

# Train model
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Evaluate
y_pred = clf.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, y_pred):.2f}")
print(classification_report(y_test, y_pred, target_names=iris.target_names))
```

## R Examples

### Basic Statistics

```r
# Generate sample data
set.seed(42)
data <- data.frame(
    group = rep(c("A", "B", "C"), each = 30),
    value = c(rnorm(30, 10, 2), rnorm(30, 12, 2), rnorm(30, 11, 3))
)

# Summary statistics
summary(data)

# ANOVA
model <- aov(value ~ group, data = data)
summary(model)

# Post-hoc test
TukeyHSD(model)
```

### Visualization with ggplot2

```r
library(ggplot2)
library(dplyr)

# Create plot
ggplot(data, aes(x = group, y = value, fill = group)) +
    geom_boxplot() +
    geom_jitter(width = 0.2, alpha = 0.5) +
    theme_minimal() +
    labs(title = "Distribution by Group",
         x = "Group",
         y = "Value")
```

## Julia Examples

### Basic Julia

```julia
using Plots
using DifferentialEquations

# Solve ODE: y' = -2y, y(0) = 1
f(y, p, t) = -2 * y
y0 = 1.0
tspan = (0.0, 5.0)
prob = ODEProblem(f, y0, tspan)
sol = solve(prob)

# Plot solution
plot(sol, xlabel="t", ylabel="y(t)",
     title="Solution to y' = -2y",
     label="Numerical", lw=2)
plot!(t -> exp(-2t), 0, 5, label="Exact", ls=:dash)
```

### Data Analysis

```julia
using DataFrames
using CSV
using Statistics

# Create sample data
df = DataFrame(
    name = ["Alice", "Bob", "Charlie", "Diana"],
    age = [25, 30, 35, 28],
    score = [85, 92, 78, 95]
)

# Summary statistics
describe(df)

# Group operations
mean_score = mean(df.score)
println("Mean score: $mean_score")
```

## Octave Examples

### Signal Processing

```octave
% Generate signal
t = 0:0.001:1;
signal = sin(2*pi*50*t) + 0.5*sin(2*pi*120*t);
noise = 0.5*randn(size(t));
noisy_signal = signal + noise;

% Plot
subplot(2,1,1)
plot(t, noisy_signal)
title('Noisy Signal')
xlabel('Time (s)')

% FFT
Y = fft(noisy_signal);
f = (0:length(Y)-1) * 1000 / length(Y);
subplot(2,1,2)
plot(f(1:500), abs(Y(1:500)))
title('Frequency Spectrum')
xlabel('Frequency (Hz)')
```

## Installing Additional Packages

### Python Packages

```python
# In a notebook cell
!pip install --user package_name

# Or use conda
!conda install -y package_name
```

### R Packages

```r
# Install from CRAN
install.packages("package_name")

# Install from GitHub
devtools::install_github("user/package")
```

### Julia Packages

```julia
using Pkg
Pkg.add("PackageName")
```

## Resource Limits

Each user notebook has limits:
- **Memory**: 1GB (configurable)
- **CPU**: 0.5 cores (configurable)
- **Idle timeout**: 30 minutes

### Checking Resource Usage

The `jupyter-resource-usage` extension shows current memory/CPU in the top bar.

### What Happens When Limits Are Exceeded

- **Memory**: Kernel may be killed with "Kernel Died" error
- **Idle**: Server shuts down automatically; restart from home page

## File Management

### Directory Structure

```
/home/jovyan/
├── work/           # Persistent user files
├── shared/         # Read-only shared materials
└── ...             # Other temporary files
```

**Important**: Only files in `/home/jovyan/work/` are persistent!

### Uploading Files

1. Click **Upload** button
2. Select files
3. Click **Upload** to confirm

### Downloading Files

1. Right-click file
2. Select **Download**

## Collaboration Features

### Sharing Notebooks

1. Download notebook as `.ipynb`
2. Share via email/LMS
3. Recipient uploads to their account

### Using Git

```bash
# In terminal
git clone https://github.com/user/repo.git
cd repo
# Work on files
git add .
git commit -m "Changes"
git push
```

Or use the JupyterLab Git extension (sidebar icon).

## Troubleshooting

### Kernel Died

**Cause**: Usually memory exceeded

**Solutions**:
1. Restart kernel: Kernel → Restart
2. Clear output: Cell → All Output → Clear
3. Reduce data size
4. Process data in chunks

### Server Won't Start

**Cause**: Resource limits or previous crash

**Solutions**:
1. Wait a few minutes
2. Contact admin to restart server
3. Check admin panel for errors

### Slow Performance

**Solutions**:
1. Close unused notebooks
2. Restart kernel
3. Reduce plot resolution
4. Use smaller datasets for testing

### Import Errors

**Cause**: Package not installed

**Solution**:
```python
!pip install --user missing_package
# Then restart kernel
```

### Permission Denied

**Cause**: Writing outside home directory

**Solution**: Only write to `/home/jovyan/work/`

## Best Practices

### For Students

1. **Save frequently**: Ctrl+S or auto-save
2. **Use work directory**: Store files in `/home/jovyan/work/`
3. **Clear output before sharing**: Reduces file size
4. **Restart kernel periodically**: Clears memory

### For Instructors

1. **Provide template notebooks**: With structure and examples
2. **Use shared folder**: For read-only materials
3. **Set clear expectations**: About resource limits
4. **Test notebooks**: Before assigning

### Memory Management

1. **Delete large variables**: `del variable` or `rm(variable)`
2. **Use generators**: Instead of loading all data
3. **Close figures**: `plt.close()` after displaying
4. **Downsample data**: For exploration

## Getting Help

- **In-notebook**: Use `?function_name` or `help(function)`
- **Documentation**: `https://jupyter.org/documentation`
- **Platform issues**: Contact course instructor or admin
