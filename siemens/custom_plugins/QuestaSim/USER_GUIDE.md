# QuestaSim Plugin - Complete User Guide

**Version:** 2.1  
**Last Updated:** December 2025  
**Plugin Type:** Simulation Plugin for Questa Developer

---

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start (5 Minutes)](#quick-start-5-minutes)
3. [Installation & Setup](#installation--setup)
4. [Basic Usage](#basic-usage)
5. [Flow Control](#flow-control)
6. [Configuration Guide](#configuration-guide)
7. [Common Use Cases](#common-use-cases)
8. [Advanced Features](#advanced-features)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)
11. [FAQ](#faq)
12. [Reference](#reference)

---

## Introduction

### What is This Plugin?

The **QuestaSim Enhanced Plugin** integrates Siemens QuestaSim/ModelSim simulation into Questa Developer, providing:

- ✅ **One-click simulation** from Questa Developer IDE
- ✅ **Two simulation flows**: Single-step (development) and Two-step (production)
- ✅ **40+ optional features**: Coverage, UVM, waveform, VIP, debug, and more
- ✅ **Zero configuration**: Works with just one environment variable
- ✅ **Professional workflows**: Regression testing, CI/CD integration, coverage analysis

### Who Should Use This Plugin?

- **RTL Designers**: Quick simulation during development
- **Verification Engineers**: UVM testbenches, coverage collection
- **DV Leads**: Production regression, coverage sign-off
- **DevOps Engineers**: CI/CD pipeline integration
- **Students/Learners**: Easy simulation environment

### Key Features

| Feature | Description |
|---------|-------------|
| **Dual Flow Support** | Choose single-step (fast) or two-step (production) at runtime |
| **Coverage Collection** | Statement, branch, condition, expression, FSM, toggle |
| **UVM Support** | Run UVM tests with configurable verbosity |
| **Waveform Capture** | WLF, VCD, FSDB formats |
| **VIP Integration** | Siemens VIP/PLI support |
| **Debug Modes** | Full visibility control (+acc options) |
| **Batch/GUI Modes** | Interactive development or automated regression |
| **Visualizer Support** | Questa Visualizer integration |

---

## Quick Start (5 Minutes)

### Step 1: Set QuestaSim Path

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

**Example:**
```bash
export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
```

### Step 2: Open Your Project

1. Launch **Questa Developer**
2. Open your compiled project (RTL already compiled)

### Step 3: Run Simulation

1. Right-click on your project or top-level module
2. Select **Plugins** → **QuestaSim Simulation**
3. Simulation runs automatically!

### Step 4: View Results

- **GUI Mode**: Waveform window opens automatically
- **Transcript**: See simulation output in Questa Developer console
- **Logs**: Check `vopt.log` and `simulation.log` in project directory

**That's it!** You've run your first simulation. 🎉

---

## Installation & Setup

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Questa Developer** | 2024.2+ | IDE with plugin support |
| **QuestaSim/ModelSim** | 2023.1+ | Simulation tool |
| **Linux** | RHEL 7/8, Ubuntu 20.04+ | Or similar |
| **Shell** | bash, csh, tcsh | Environment variables |

### Installing the Plugin

#### Method 1: Via Questa Developer Plugin Manager

1. Open Questa Developer
2. Go to **Tools** → **Plugins** → **Install Plugin**
3. Browse to plugin directory: `my_plugins/QuestaSim`
4. Click **Install**

#### Method 2: Manual Installation

1. Copy the plugin directory:
   ```bash
   cp -r my_plugins/QuestaSim $QUESTA_DEVELOPER_PLUGINS/
   ```

2. Restart Questa Developer

3. Verify installation: **Tools** → **Plugins** → **Manage Plugins**

### Configuring QuestaSim Path

Choose one method:

#### Option A: Shell Environment (Recommended)

Add to your `~/.bashrc` or `~/.cshrc`:

```bash
# Bash
export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64

# Csh
setenv QUESTA_BIN_DIR /u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
```

#### Option B: Questa Developer Environment

1. Go to **Tools** → **Options** → **Environment Variables**
2. Add: `QUESTA_BIN_DIR` = `/path/to/questasim/bin`
3. Click **Apply**

#### Option C: Project-Specific

Create `env.sh` in your project directory:

```bash
#!/bin/bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
# Add other project-specific settings here
```

Source before launching Questa Developer:
```bash
source env.sh
questa_developer
```

### Verifying Setup

Run this test:

```bash
# Check if vsim is accessible
$QUESTA_BIN_DIR/vsim -version

# Expected output:
# Model Technology ModelSim SE-64 vsim ...
```

If you see version info, you're ready!

---

## Basic Usage

### Understanding the Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Your RTL Code                                               │
│ (SystemVerilog/VHDL files)                                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Questa Developer: Compile                                   │
│ (Creates compiled libraries in work/)                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ QuestaSim Plugin: Simulate                                  │
│ • Two-step flow: vopt → vsim (default)                      │
│ • Single-step flow: vsim only (optional)                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Results                                                     │
│ • Waveforms (if enabled)                                    │
│ • Coverage database (if enabled)                            │
│ • Simulation logs                                           │
└─────────────────────────────────────────────────────────────┘
```

### Running Your First Simulation

#### GUI Mode (Default)

```bash
export QUESTA_BIN_DIR=/path/to/bin
```

1. Open project in Questa Developer
2. Click **Plugins** → **QuestaSim Simulation**
3. Waveform window opens
4. Use GUI controls to run simulation

#### Batch Mode (Automated)

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_SIM_MODE=batch
export QUESTA_AUTO_QUIT=1
```

1. Run plugin command
2. Simulation runs to completion automatically
3. Exits when done

### Understanding Simulation Flows

#### Two-Step Flow (Default - Recommended)

**What happens:**
```
Step 1: vopt (Elaboration)
  ├─ Reads compiled libraries
  ├─ Optimizes design
  ├─ Instruments for coverage (if enabled)
  └─ Creates optimized design: design_opt

Step 2: vsim (Simulation)
  ├─ Loads optimized design
  ├─ Runs simulation
  ├─ Collects coverage (if enabled)
  └─ Captures waveforms (if enabled)
```

**Best for:**
- Production regressions
- Coverage collection
- Multiple simulation runs
- CI/CD pipelines

**To use (default):**
```bash
export QUESTA_FLOW_MODE="two-step"  # or leave unset
```

#### Single-Step Flow (Fast Development)

**What happens:**
```
Step 1: vsim (with implicit vopt)
  ├─ Reads compiled libraries
  ├─ Optimizes in background (-voptargs)
  ├─ Runs simulation
  └─ All in one command
```

**Best for:**
- Daily development
- Quick iterations
- Single simulation runs
- Learning/debugging

**To use:**
```bash
export QUESTA_FLOW_MODE="single-step"
```

### Viewing Simulation Results

#### Waveforms

If waveform capture is enabled:

```bash
# Open waveform file
vsim -view vsim.wlf
```

Or in Questa Developer:
1. **File** → **Open** → Select `.wlf` file
2. **Add** → **Wave** → Select signals

#### Coverage

If coverage is enabled:

```bash
# View coverage report
vcover report coverage.ucdb

# Generate HTML report
vcover report -html coverage.ucdb
```

#### Logs

Check these files in your project directory:

| File | Contents |
|------|----------|
| `vopt.log` | Elaboration/optimization log (two-step only) |
| `simulation.log` | Simulation execution log |
| `transcript` | QuestaSim transcript |

---

## Flow Control

### Choosing a Flow

Use **environment variables** to control which flow executes:

#### Method 1: QUESTA_FLOW_MODE (Explicit)

```bash
# Two-step flow (production)
export QUESTA_FLOW_MODE="two-step"

# Single-step flow (development)
export QUESTA_FLOW_MODE="single-step"

# Auto-detect (uses QUESTA_ENABLE_TWO_STEP)
export QUESTA_FLOW_MODE="auto"
```

#### Method 2: QUESTA_ENABLE_TWO_STEP (Simple Toggle)

```bash
# Enable two-step flow (default)
export QUESTA_ENABLE_TWO_STEP=1

# Disable two-step flow (use single-step)
export QUESTA_ENABLE_TWO_STEP=0
```

### Default Behavior

**If you set nothing**, the plugin uses **two-step flow** (production-grade).

### Flow Decision Logic

```
1. Check QUESTA_FLOW_MODE
   ├─ If "single-step" → Use single-step
   ├─ If "two-step" → Use two-step
   └─ If "auto" or unset → Check QUESTA_ENABLE_TWO_STEP
       ├─ If 1 (default) → Use two-step
       └─ If 0 → Use single-step
```

### Switching Flows

You can switch flows **without changing any other configuration**:

```bash
# Common config (works for both flows)
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=base_test

# Try single-step
export QUESTA_FLOW_MODE="single-step"
# Run simulation

# Try two-step
export QUESTA_FLOW_MODE="two-step"
# Run simulation (all other settings unchanged!)
```

---

## Configuration Guide

### Required Configuration

Only **ONE** variable is required:

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

**Everything else is optional!**

### Optional Configuration Categories

1. [Simulation Control](#simulation-control)
2. [Flow Control](#flow-control-variables)
3. [Coverage](#coverage-configuration)
4. [UVM](#uvm-configuration)
5. [Waveform](#waveform-configuration)
6. [VIP/PLI](#vippli-configuration)
7. [Debug & Optimization](#debug--optimization)
8. [Assertions & FSM](#assertions--fsm)
9. [Logs & Output](#logs--output)
10. [Advanced](#advanced-options)

---

### Simulation Control

Control basic simulation behavior:

```bash
# Simulation mode
export QUESTA_SIM_MODE="gui"         # gui (default), batch, interactive

# Architecture
export QUESTA_SIM_ARCH="64"          # 64-bit (default), 32-bit

# Time resolution
export QUESTA_SIM_TIME_RESOLUTION="1ps"  # Default: 1ps

# Run time
export QUESTA_RUN_TIME="run -all"    # TCL command (default: run -all)

# Auto quit (batch mode)
export QUESTA_AUTO_QUIT=1            # 1=quit after run (default), 0=stay open
```

**Examples:**

```bash
# Interactive GUI simulation
export QUESTA_SIM_MODE="gui"

# Automated batch simulation
export QUESTA_SIM_MODE="batch"
export QUESTA_AUTO_QUIT=1

# Console simulation
export QUESTA_SIM_MODE="interactive"
```

---

### Flow Control Variables

Control which simulation flow to use:

```bash
# Primary control
export QUESTA_FLOW_MODE="two-step"   # two-step, single-step, auto

# Alternative control
export QUESTA_ENABLE_TWO_STEP=1      # 1=two-step (default), 0=single-step
```

**Two-Step Specific (vopt stage):**

```bash
# Optimization level
export QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"  # -O0 to -O5 (default: -O5)

# Debug visibility
export QUESTA_VOPT_ACCESS="+acc"     # +acc (full), +acc=npr, +acc=r

# Debug mode
export QUESTA_VOPT_DEBUG=0           # 0=optimize (default), 1=debug mode

# Extra vopt arguments
export QUESTA_VOPT_EXTRA_ARGS="-floatparameters"

# Log files
export QUESTA_VOPT_LOG_FILE="vopt.log"
export QUESTA_VSIM_LOG_FILE="simulation.log"
```

---

### Coverage Configuration

Enable and configure code coverage:

```bash
# Enable coverage
export QUESTA_ENABLE_COVERAGE=1      # 0=disabled (default), 1=enabled

# Coverage types
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
# s=statement, b=branch, c=condition, e=expression, f=fsm, t=toggle

# Coverage database
export QUESTA_COVERAGE_DB="coverage.ucdb"
```

**Examples:**

```bash
# Full coverage
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB="full_coverage.ucdb"

# Statement and branch only
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sb"
export QUESTA_COVERAGE_DB="basic_coverage.ucdb"

# Named coverage for regression
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB="regression_$(date +%Y%m%d).ucdb"
```

**Viewing Coverage:**

```bash
# Text report
vcover report coverage.ucdb

# HTML report
vcover report -html coverage.ucdb

# Detailed report
vcover report -details coverage.ucdb
```

---

### UVM Configuration

Configure UVM testbench execution:

```bash
# Enable UVM
export QUESTA_ENABLE_UVM=1           # 0=disabled (default), 1=enabled

# Test name
export QUESTA_UVM_TESTNAME="base_test"

# Verbosity level
export QUESTA_UVM_VERBOSITY="UVM_MEDIUM"
# Options: UVM_NONE, UVM_LOW, UVM_MEDIUM (default), UVM_HIGH, UVM_FULL

# Config DB trace
export QUESTA_UVM_CONFIG_DB="trace"  # Enable config DB tracing
```

**Examples:**

```bash
# Basic UVM test
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="smoke_test"

# Debug UVM test
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="debug_test"
export QUESTA_UVM_VERBOSITY="UVM_HIGH"

# Full UVM debug
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="complex_test"
export QUESTA_UVM_VERBOSITY="UVM_FULL"
export QUESTA_UVM_CONFIG_DB="trace"
```

---

### Waveform Configuration

Capture simulation waveforms:

```bash
# Enable waveform capture
export QUESTA_ENABLE_WAVEFORM=1      # 0=disabled (default), 1=enabled

# Waveform format
export QUESTA_WAVEFORM_FORMAT="wlf"  # wlf (default), vcd, fsdb

# Waveform filename
export QUESTA_WAVEFORM_FILE="vsim.wlf"

# Waveform database options
export QUESTA_WAVEFORM_DB="+wlf+compress"
```

**Format Support:**

| Format | Extension | Tool Required | Notes |
|--------|-----------|---------------|-------|
| **WLF** | `.wlf` | QuestaSim (built-in) | Native format, best performance |
| **VCD** | `.vcd` | Any VCD viewer | Standard format, larger files |
| **FSDB** | `.fsdb` | Verdi (VERDI_HOME) | High performance, requires license |

**Examples:**

```bash
# WLF waveform (native)
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT="wlf"
export QUESTA_WAVEFORM_FILE="debug.wlf"

# VCD waveform (portable)
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT="vcd"
export QUESTA_WAVEFORM_FILE="dump.vcd"

# FSDB waveform (Verdi)
export VERDI_HOME=/tools/verdi
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT="fsdb"
export QUESTA_WAVEFORM_FILE="waves.fsdb"

# Timestamped waveforms
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE="sim_$(date +%H%M%S).wlf"
```

---

### VIP/PLI Configuration

Integrate Siemens VIP or custom PLI:

```bash
# Enable VIP/PLI
export QUESTA_VIP_ENABLE=1           # 0=disabled (default), 1=enabled

# PLI library path
export QUESTA_VIP_PLI_LIB="/path/to/libtb_ms.so"

# Avery VIP (Siemens)
export AVERY_PLI="/tools/avery"
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
```

**Examples:**

```bash
# Siemens Avery VIP
export AVERY_PLI=/u/avery/latest
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"

# Custom PLI
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="/project/lib/custom_pli.so"
```

---

### Debug & Optimization

Control debug visibility and optimization:

#### For Two-Step Flow:

```bash
# Optimization level (-O0 = none, -O5 = max)
export QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"

# Visibility control
export QUESTA_VOPT_ACCESS="+acc"
# +acc = full access
# +acc=npr = nets, ports, registers
# +acc=r = read-only access (fastest)

# Debug mode (disables optimization)
export QUESTA_VOPT_DEBUG=1
```

#### For Single-Step Flow:

```bash
# Debug mode
export QUESTA_ENABLE_DEBUG=1

# Debug level
export QUESTA_DEBUG_LEVEL="+acc"

# Optimization
export QUESTA_ENABLE_VOPT=1
export QUESTA_VOPT_OPTIONS="-O5"
```

**Examples:**

```bash
# Full debug (two-step)
export QUESTA_FLOW_MODE="two-step"
export QUESTA_VOPT_DEBUG=1
export QUESTA_VOPT_ACCESS="+acc"
export QUESTA_VOPT_OPTIMIZE_LEVEL="-O0"

# Optimized production (two-step)
export QUESTA_FLOW_MODE="two-step"
export QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"
export QUESTA_VOPT_ACCESS="+acc=r"

# Debug (single-step)
export QUESTA_FLOW_MODE="single-step"
export QUESTA_ENABLE_DEBUG=1
export QUESTA_DEBUG_LEVEL="+acc=npr"
```

---

### Assertions & FSM

Enable assertion debugging and FSM analysis:

```bash
# Assertions
export QUESTA_ENABLE_ASSERTIONS=1    # 0=disabled, 1=enabled (default)

# FSM debugging
export QUESTA_ENABLE_FSM_DEBUG=1     # 0=disabled (default), 1=enabled
```

**Examples:**

```bash
# Enable assertion debugging
export QUESTA_ENABLE_ASSERTIONS=1

# Enable FSM state coverage
export QUESTA_ENABLE_FSM_DEBUG=1
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=f"
```

---

### Logs & Output

Control log files and transcript:

```bash
# Transcript file
export QUESTA_TRANSCRIPT_FILE="transcript"

# Vopt log (two-step only)
export QUESTA_VOPT_LOG_FILE="vopt.log"

# Vsim log
export QUESTA_VSIM_LOG_FILE="simulation.log"

# Main log file
export QUESTA_LOG_FILE="questa.log"
```

**Examples:**

```bash
# Timestamped logs
export QUESTA_VOPT_LOG_FILE="vopt_$(date +%Y%m%d_%H%M%S).log"
export QUESTA_VSIM_LOG_FILE="vsim_$(date +%Y%m%d_%H%M%S).log"

# Build-specific logs (CI/CD)
export QUESTA_VOPT_LOG_FILE="vopt_${BUILD_ID}.log"
export QUESTA_VSIM_LOG_FILE="vsim_${BUILD_ID}.log"
export QUESTA_COVERAGE_DB="coverage_${BUILD_ID}.ucdb"
```

---

### Advanced Options

Additional configuration options:

```bash
# Custom DO file
export QUESTA_CUSTOM_DO_FILE="/path/to/commands.do"

# Custom plusargs
export QUESTA_CUSTOM_PLUSARGS="+seed=42 +timeout=1000"

# Custom defines
export QUESTA_CUSTOM_DEFINES="+define+SIM_MODE"

# Power analysis
export QUESTA_ENABLE_POWER=1
export QUESTA_POWER_OPTIONS="-power -p_option=value"

# Visualizer mode
export QUESTA_ENABLE_VISUALIZER=1
export QUESTA_VISUALIZER_OPTIONS="-designfile design.bin"
```

---

## Common Use Cases

### Use Case 1: Daily Development

**Scenario:** Writing RTL, need quick compile-simulate-debug cycles.

**Configuration:**

```bash
#!/bin/bash
# File: dev_env.sh

export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
export QUESTA_FLOW_MODE="single-step"  # Fast iteration
export QUESTA_SIM_MODE="gui"           # Interactive GUI
export QUESTA_ENABLE_WAVEFORM=1        # Capture waveforms
export QUESTA_WAVEFORM_FILE="debug.wlf"
```

**Usage:**
```bash
source dev_env.sh
# Open Questa Developer
# Run plugin → Quick simulation with waveforms
```

---

### Use Case 2: Batch Regression

**Scenario:** Nightly regression with 100 tests, need coverage.

**Configuration:**

```bash
#!/bin/bash
# File: regression_env.sh

export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
export QUESTA_FLOW_MODE="two-step"         # Production flow
export QUESTA_SIM_MODE="batch"             # Automated
export QUESTA_AUTO_QUIT=1                  # Exit after run
export QUESTA_ENABLE_COVERAGE=1            # Code coverage
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB="regression_$(date +%Y%m%d).ucdb"
export QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"    # Maximum optimization
export QUESTA_VOPT_ACCESS="+acc=r"         # Minimal overhead
```

**Usage:**
```bash
source regression_env.sh

# Run elaboration once
# (Done automatically by plugin in two-step mode)

# Run 100 tests with different seeds
for seed in {1..100}; do
    export QUESTA_CUSTOM_PLUSARGS="+seed=$seed"
    export QUESTA_UVM_TESTNAME="test_$seed"
    # Run plugin
done

# Merge coverage
vcover merge final.ucdb regression_*.ucdb

# Generate report
vcover report -html final.ucdb
```

---

### Use Case 3: UVM Testbench

**Scenario:** Running UVM tests with debug and waveforms.

**Configuration:**

```bash
#!/bin/bash
# File: uvm_env.sh

export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
export QUESTA_FLOW_MODE="two-step"
export QUESTA_SIM_MODE="gui"
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="base_test"
export QUESTA_UVM_VERBOSITY="UVM_HIGH"
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE="uvm_test.wlf"
export QUESTA_VOPT_ACCESS="+acc"           # Full visibility for debug
```

**Usage:**
```bash
source uvm_env.sh

# Run base test
export QUESTA_UVM_TESTNAME="base_test"
# Run plugin

# Run debug test
export QUESTA_UVM_TESTNAME="debug_test"
export QUESTA_UVM_VERBOSITY="UVM_FULL"
# Run plugin
```

---

### Use Case 4: Coverage Analysis

**Scenario:** Detailed coverage collection and reporting.

**Configuration:**

```bash
#!/bin/bash
# File: coverage_env.sh

export QUESTA_BIN_DIR=/u/qa/buildsites/main/builds/linux_x86_64/modeltech/linux_x86_64
export QUESTA_FLOW_MODE="two-step"
export QUESTA_SIM_MODE="batch"
export QUESTA_AUTO_QUIT=1
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"  # All coverage types
export QUESTA_COVERAGE_DB="detailed_coverage.ucdb"
export QUESTA_VOPT_ACCESS="+acc"  # Visibility for coverage
```

**Usage:**
```bash
source coverage_env.sh

# Run all tests
./run_all_tests.sh

# View coverage report
vcover report detailed_coverage.ucdb

# Generate HTML report
vcover report -html -output cov_html detailed_coverage.ucdb

# Check coverage percentage
vcover report -summary detailed_coverage.ucdb | grep "TOTAL COVERAGE"
```

---


## Advanced Features

### Custom DO Files

Execute custom TCL commands:

**Create DO file:**

```tcl
# File: custom_commands.do

# Add waves
add wave -radix hex /tb/dut/*

# Set breakpoint
bp /tb/dut/state when {state == ERROR}

# Run simulation
run -all

# Print summary
echo "Simulation complete"
```

**Use in plugin:**

```bash
export QUESTA_CUSTOM_DO_FILE="/path/to/custom_commands.do"
```

---

### Multiple Simulation Runs

Reuse optimized design:

**Two-step flow advantage:**

```bash
export QUESTA_FLOW_MODE="two-step"

# Elaborate once (vopt runs once)
# First simulation

# Subsequent simulations reuse optimized design
# (vsim only, much faster)
export QUESTA_CUSTOM_PLUSARGS="+seed=1"
# Run plugin

export QUESTA_CUSTOM_PLUSARGS="+seed=2"
# Run plugin

export QUESTA_CUSTOM_PLUSARGS="+seed=3"
# Run plugin
```

---

### Visualizer Mode

Use Questa Visualizer GUI:

```bash
export QUESTA_ENABLE_VISUALIZER=1
export QUESTA_VISUALIZER_OPTIONS="-designfile design.bin"
export QUESTA_SIM_MODE="gui"  # Auto-adjusted if batch
```

**Note:** Visualizer is incompatible with batch mode.

---

### Power Analysis

Enable power-aware simulation:

```bash
export QUESTA_ENABLE_POWER=1
export QUESTA_POWER_OPTIONS="-power -p_option=value"
```

---

### FSM Debug

Extract FSM state coverage:

```bash
export QUESTA_ENABLE_FSM_DEBUG=1
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=f"
```

View FSM report:

```bash
vcover report -details -code f coverage.ucdb
```

---

## Troubleshooting

### Problem: "execve failed: No such file or directory"

**Error:**
```
execve failed: No such file or directory
```

**Cause:** Generated script cannot be executed (wrong shebang or not executable)

**Solutions:**

1. **Check if script was generated:**
   ```bash
   ls -la ${PROJECT_DIR}/questasim_script.sh
   ```

2. **Make script executable:**
   ```bash
   chmod +x ${PROJECT_DIR}/questasim_script.sh
   ```

3. **Verify shebang line:**
   ```bash
   head -1 ${PROJECT_DIR}/questasim_script.sh
   # Should show: #!/bin/bash
   ```

4. **Check bash location:**
   ```bash
   which bash
   # Should show: /bin/bash or /usr/bin/bash
   ```

5. **If bash is at different location, the plugin will still work** because config.json uses:
   ```json
   "command": "bash",
   "arguments": "${PROJECT_DIR}/questasim_script.sh"
   ```
   This explicitly calls bash, so shebang doesn't matter.

6. **Try running manually:**
   ```bash
   cd ${PROJECT_DIR}
   bash questasim_script.sh
   ```

7. **Check Questa Developer logs** for the exact command being executed.

**Most Common Fix:**
```bash
# The plugin should work as-is, but if you see this error:
cd your_project_directory
chmod +x questasim_script.sh
```

---

### Problem: "QUESTA_BIN_DIR not set"

**Error:**
```
[ERROR] QUESTA_BIN_DIR not set
```

**Solution:**
```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

Verify:
```bash
echo $QUESTA_BIN_DIR
$QUESTA_BIN_DIR/vsim -version
```

---

### Problem: "vopt not found"

**Error:**
```
[ERROR] vopt not found: /path/to/vopt
```

**Solutions:**

1. Check QUESTA_BIN_DIR:
   ```bash
   ls $QUESTA_BIN_DIR/vopt
   ```

2. Fix path:
   ```bash
   export QUESTA_BIN_DIR=/correct/path/to/bin
   ```

3. Verify installation:
   ```bash
   which vopt
   ```

---

### Problem: Simulation hangs

**Symptoms:** Simulation starts but doesn't progress

**Possible Causes:**

1. **Visualizer + Batch conflict:**
   ```bash
   # Don't do this:
   export QUESTA_ENABLE_VISUALIZER=1
   export QUESTA_SIM_MODE="batch"  # Conflict!
   
   # Do this:
   export QUESTA_ENABLE_VISUALIZER=1
   export QUESTA_SIM_MODE="gui"  # Auto-fixed by plugin
   ```

2. **No quit command in batch mode:**
   ```bash
   export QUESTA_AUTO_QUIT=1  # Must be 1 for batch
   ```

3. **Infinite simulation:**
   ```bash
   export QUESTA_RUN_TIME="run 1ms"  # Add timeout
   ```

---

### Problem: Coverage not collected

**Symptoms:** Coverage UCDB file empty or missing

**Solutions:**

1. **Enable coverage:**
   ```bash
   export QUESTA_ENABLE_COVERAGE=1
   ```

2. **Two-step flow (recommended for coverage):**
   ```bash
   export QUESTA_FLOW_MODE="two-step"
   ```

3. **Check coverage instrumentation in vopt.log:**
   ```bash
   grep -i coverage vopt.log
   ```

4. **Verify UCDB file:**
   ```bash
   ls -lh coverage.ucdb
   vcover report coverage.ucdb
   ```

---

### Problem: Can't see signals in waveform

**Symptoms:** Waveform file exists but signals not visible

**Solutions:**

1. **Increase visibility (two-step):**
   ```bash
   export QUESTA_VOPT_ACCESS="+acc"  # Full access
   ```

2. **Add wave commands:**
   ```bash
   # Create wave.do
   echo "add wave -r /*" > wave.do
   export QUESTA_CUSTOM_DO_FILE="wave.do"
   ```

3. **Check optimization level:**
   ```bash
   export QUESTA_VOPT_DEBUG=1  # Disable optimization
   ```

---

### Problem: UVM test not running

**Symptoms:** UVM test name not recognized

**Solutions:**

1. **Enable UVM:**
   ```bash
   export QUESTA_ENABLE_UVM=1
   ```

2. **Check test name:**
   ```bash
   export QUESTA_UVM_TESTNAME="correct_test_name"
   ```

3. **Verify UVM compilation:**
   ```bash
   grep -i "UVM" transcript
   ```

---

### Problem: Simulation too slow

**Symptoms:** Simulation takes too long

**Solutions:**

1. **Use two-step flow:**
   ```bash
   export QUESTA_FLOW_MODE="two-step"
   ```

2. **Increase optimization:**
   ```bash
   export QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"
   ```

3. **Reduce visibility:**
   ```bash
   export QUESTA_VOPT_ACCESS="+acc=r"  # Read-only, faster
   ```

4. **Disable waveforms if not needed:**
   ```bash
   export QUESTA_ENABLE_WAVEFORM=0
   ```

5. **Batch mode:**
   ```bash
   export QUESTA_SIM_MODE="batch"
   ```

---

### Problem: VIP not loading

**Symptoms:** VIP library not found

**Solutions:**

1. **Check AVERY_PLI:**
   ```bash
   echo $AVERY_PLI
   ls $AVERY_PLI/linux_x86_64/lib/libtb_ms.so
   ```

2. **Set correct path:**
   ```bash
   export AVERY_PLI=/correct/path
   export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
   ```

3. **Enable VIP:**
   ```bash
   export QUESTA_VIP_ENABLE=1
   ```

---

## Best Practices

### 1. Use Two-Step Flow for Production

**Why:** Better control, performance, debugging

```bash
# Production default
export QUESTA_FLOW_MODE="two-step"
```

### 2. Use Single-Step for Development

**Why:** Faster iteration during coding

```bash
# Development default
export QUESTA_FLOW_MODE="single-step"
```

### 3. Always Enable Coverage for Regressions

**Why:** Track code coverage over time

```bash
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB="regression_$(date +%Y%m%d).ucdb"
```

### 4. Use Batch Mode for Automation

**Why:** No GUI overhead, scriptable

```bash
export QUESTA_SIM_MODE="batch"
export QUESTA_AUTO_QUIT=1
```

### 5. Timestamp Log Files

**Why:** Easy to track and debug

```bash
export QUESTA_VOPT_LOG_FILE="vopt_$(date +%Y%m%d_%H%M%S).log"
export QUESTA_VSIM_LOG_FILE="vsim_$(date +%Y%m%d_%H%M%S).log"
```

### 6. Use Minimal Visibility for Performance

**Why:** Faster simulation

```bash
# Instead of:
export QUESTA_VOPT_ACCESS="+acc"  # Full access (slow)

# Use:
export QUESTA_VOPT_ACCESS="+acc=r"  # Read-only (fast)
```

### 7. Create Environment Files

**Why:** Reproducible, shareable configs

```bash
# Create env files for different scenarios
dev_env.sh       # Development
regression_env.sh  # Nightly regression
coverage_env.sh    # Coverage analysis
ci_env.sh         # CI/CD
```

### 8. Check Logs After Simulation

**Why:** Catch warnings and errors

```bash
# Two-step flow
grep -i "error\|warning" vopt.log
grep -i "error\|warning" simulation.log

# Look for coverage stats
grep -i "coverage" simulation.log
```

### 9. Use Version Control for Configs

**Why:** Track configuration changes

```bash
git add env.sh
git commit -m "Update simulation config for regression"
```

### 10. Document Custom Configurations

**Why:** Help team members understand setup

```bash
# Add comments to env files
# File: regression_env.sh
# Purpose: Nightly regression with coverage
# Owner: John Doe
# Last updated: 2025-12-03
```

---

## FAQ



### Q: Can I switch flows without changing config?

**A:** Yes! Just change `QUESTA_FLOW_MODE`:

```bash
export QUESTA_FLOW_MODE="single-step"  # or "two-step"
```

---

### Q: What's the difference between flows?

**A:**

| Feature | Single-Step | Two-Step |
|---------|-------------|----------|
| **Commands** | vsim only | vopt + vsim |
| **Speed (1 run)** | Fast | Slightly slower |
| **Speed (100 runs)** | Slow | Very fast |
| **Control** | Limited | Full |
| **Production** | OK | Recommended |

---

### Q: Which flow should I use?

**A:**

- **Development:** Single-step (fast iteration)
- **Production:** Two-step (better control)
- **Coverage:** Two-step (explicit instrumentation)
- **Regression:** Two-step (optimize once, run many)
- **Learning:** Single-step (simpler)

---

### Q: How do I enable coverage?

**A:**

```bash
export QUESTA_ENABLE_COVERAGE=1
```

That's it! Works with both flows.

---

### Q: How do I run a UVM test?

**A:**

```bash
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="my_test"
```

---

### Q: Where are the log files?

**A:** In your project directory:

- `vopt.log` - Elaboration (two-step only)
- `simulation.log` - Simulation
- `transcript` - QuestaSim transcript
- `coverage.ucdb` - Coverage database (if enabled)
- `vsim.wlf` - Waveform (if enabled)

---

### Q: Can I use custom DO files?

**A:** Yes:

```bash
export QUESTA_CUSTOM_DO_FILE="/path/to/commands.do"
```

---

### Q: How do I speed up simulation?

**A:**

1. Use two-step flow
2. Increase optimization: `QUESTA_VOPT_OPTIMIZE_LEVEL="-O5"`
3. Reduce visibility: `QUESTA_VOPT_ACCESS="+acc=r"`
4. Disable waveforms if not needed
5. Use batch mode

---

### Q: What if QUESTA_BIN_DIR is wrong?

**A:**

```bash
# Check current value
echo $QUESTA_BIN_DIR

# Verify vsim exists
$QUESTA_BIN_DIR/vsim -version

# Fix if wrong
export QUESTA_BIN_DIR=/correct/path/to/bin
```

---

### Q: Can I run multiple simulations?

**A:** Yes! Two-step flow is perfect for this:

```bash
export QUESTA_FLOW_MODE="two-step"

# Elaborate once (automatic)
# Then run with different seeds:
for seed in {1..100}; do
    export QUESTA_CUSTOM_PLUSARGS="+seed=$seed"
    # Run plugin
done
```

---

### Q: How do I view coverage?

**A:**

```bash
# Text report
vcover report coverage.ucdb

# HTML report
vcover report -html coverage.ucdb

# Summary
vcover report -summary coverage.ucdb
```

---

### Q: Does Visualizer work?

**A:** Yes:

```bash
export QUESTA_ENABLE_VISUALIZER=1
export QUESTA_SIM_MODE="gui"  # Required
```

---

### Q: How do I merge coverage databases?

**A:**

```bash
vcover merge final.ucdb test1.ucdb test2.ucdb test3.ucdb
```

---

### Q: Can I use FSDB waveforms?

**A:** Yes, if Verdi is installed:

```bash
export VERDI_HOME=/path/to/verdi
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT="fsdb"
```

---

### Q: What if simulation hangs?

**A:**

1. Check Visualizer + batch conflict
2. Enable auto-quit: `QUESTA_AUTO_QUIT=1`
3. Add timeout: `QUESTA_RUN_TIME="run 1ms"`

---

### Q: Where can I find more help?

**A:**

- **README.md**: Main documentation
- **FLOW_CONTROL.md**: Flow selection guide
- **TWO_STEP_FLOW.md**: Two-step flow details
- **QUICK_START_CARD.md**: Quick reference
- **QuestaSim User's Manual**: Official Siemens docs

---

## Reference

### All Environment Variables

Quick reference of all supported variables:

#### Required

| Variable | Description |
|----------|-------------|
| `QUESTA_BIN_DIR` | Path to QuestaSim bin directory (required) |

#### Flow Control

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_FLOW_MODE` | `auto` | Flow mode: `single-step`, `two-step`, `auto` |
| `QUESTA_ENABLE_TWO_STEP` | `1` | Enable two-step flow (1=yes, 0=no) |

#### Simulation

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_SIM_MODE` | `gui` | Mode: `gui`, `batch`, `interactive` |
| `QUESTA_SIM_ARCH` | `64` | Architecture: `32`, `64` |
| `QUESTA_SIM_TIME_RESOLUTION` | `1ps` | Time resolution |
| `QUESTA_RUN_TIME` | `run -all` | TCL run command |
| `QUESTA_AUTO_QUIT` | `1` | Auto quit in batch mode |

#### Coverage

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_COVERAGE` | `0` | Enable coverage (1=yes, 0=no) |
| `QUESTA_COVERAGE_OPTIONS` | `+cover=sbceft` | Coverage types |
| `QUESTA_COVERAGE_DB` | `coverage.ucdb` | Coverage database file |

#### UVM

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_UVM` | `0` | Enable UVM (1=yes, 0=no) |
| `QUESTA_UVM_TESTNAME` | `""` | UVM test name |
| `QUESTA_UVM_VERBOSITY` | `UVM_MEDIUM` | UVM verbosity level |
| `QUESTA_UVM_CONFIG_DB` | `""` | Enable config DB trace |

#### Waveform

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_WAVEFORM` | `0` | Enable waveform (1=yes, 0=no) |
| `QUESTA_WAVEFORM_FORMAT` | `wlf` | Format: `wlf`, `vcd`, `fsdb` |
| `QUESTA_WAVEFORM_FILE` | `vsim.wlf` | Waveform filename |
| `QUESTA_WAVEFORM_DB` | `""` | Waveform database options |

#### VIP/PLI

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_VIP_ENABLE` | `0` | Enable VIP/PLI (1=yes, 0=no) |
| `QUESTA_VIP_PLI_LIB` | `""` | PLI library path (.so file) |
| `AVERY_PLI` | `""` | Avery VIP installation path |

#### Debug & Optimization (Two-Step)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_VOPT_OPTIMIZE_LEVEL` | `-O5` | Optimization level (-O0 to -O5) |
| `QUESTA_VOPT_ACCESS` | `+acc` | Debug visibility |
| `QUESTA_VOPT_DEBUG` | `0` | Debug mode (1=yes, 0=no) |
| `QUESTA_VOPT_EXTRA_ARGS` | `""` | Additional vopt arguments |

#### Debug & Optimization (Single-Step)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_DEBUG` | `0` | Enable debug (1=yes, 0=no) |
| `QUESTA_DEBUG_LEVEL` | `+acc` | Debug access level |
| `QUESTA_ENABLE_VOPT` | `0` | Enable vopt optimization |
| `QUESTA_VOPT_OPTIONS` | `-O5` | Vopt optimization options |

#### Assertions & FSM

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_ASSERTIONS` | `1` | Enable assertions (1=yes, 0=no) |
| `QUESTA_ENABLE_FSM_DEBUG` | `0` | Enable FSM debug (1=yes, 0=no) |

#### Power

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_POWER` | `0` | Enable power analysis (1=yes, 0=no) |
| `QUESTA_POWER_OPTIONS` | `""` | Power analysis options |

#### Visualizer

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_VISUALIZER` | `0` | Enable Visualizer (1=yes, 0=no) |
| `QUESTA_VISUALIZER_OPTIONS` | `""` | Visualizer options |

#### Logs

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_TRANSCRIPT_FILE` | `transcript` | Transcript filename |
| `QUESTA_VOPT_LOG_FILE` | `vopt.log` | Vopt log file (two-step) |
| `QUESTA_VSIM_LOG_FILE` | `simulation.log` | Vsim log file |
| `QUESTA_LOG_FILE` | `""` | Main log file |

#### Custom

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_CUSTOM_DO_FILE` | `""` | Custom DO file path |
| `QUESTA_CUSTOM_PLUSARGS` | `""` | Custom plusargs |
| `QUESTA_CUSTOM_DEFINES` | `""` | Custom defines |

---

### Command Reference

#### vopt (Two-Step Flow)

```bash
vopt [options] <library>.<design> -o <optimized_design>
```

**Common options:**
- `-64` / `-32`: Architecture
- `-O0` to `-O5`: Optimization level
- `+acc`: Full debug access
- `+cover=<types>`: Coverage instrumentation
- `-assertdebug`: Enable assertion debugging
- `-L <library>`: Link library

#### vsim (Both Flows)

```bash
vsim [options] <design>
```

**Common options:**
- `-batch`: Batch mode
- `-gui`: GUI mode
- `-c`: Interactive console
- `-do <file>`: Execute DO file
- `-coverage`: Enable coverage collection
- `-wlf <file>`: Waveform file
- `-t <resolution>`: Time resolution

---

### File Structure

```
project/
├── questa.ini                    # QuestaSim library mappings
├── work/                         # Compiled libraries
├── questasim_script.sh           # Generated plugin script
├── vopt.log                      # Elaboration log (two-step)
├── simulation.log                # Simulation log
├── transcript                    # QuestaSim transcript
├── coverage.ucdb                 # Coverage database
└── vsim.wlf                      # Waveform file
```

---



### Contact

For plugin-specific issues:
1. Check this user guide
2. Review troubleshooting section
3. Check log files
4. Contact your local support team

---

## Quick Command Reference

```bash
# Minimal setup
export QUESTA_BIN_DIR=/path/to/bin

# Single-step (development)
export QUESTA_FLOW_MODE="single-step"

# Two-step (production)
export QUESTA_FLOW_MODE="two-step"

# Enable coverage
export QUESTA_ENABLE_COVERAGE=1

# Enable UVM
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME="test_name"

# Enable waveform
export QUESTA_ENABLE_WAVEFORM=1

# Batch mode
export QUESTA_SIM_MODE="batch"
export QUESTA_AUTO_QUIT=1

# View coverage
vcover report coverage.ucdb

# View waveform
vsim -view vsim.wlf
```

---

**Version:** 2.1  
**Document Date:** December 2025  
**Plugin Author:** Questa Developer Integration Team
