# QuestaSim Flow Control via Shell Environment

## Overview

The QuestaSim plugin now supports **both single-step and two-step flows** controlled entirely through **shell environment variables**, not config.json. This gives you complete flexibility to choose the flow at runtime.

---

## Flow Control Variables

### Primary Control: `QUESTA_FLOW_MODE`

```bash
export QUESTA_FLOW_MODE="two-step"    # Explicit two-step: vopt → vsim
export QUESTA_FLOW_MODE="single-step" # Single-step: vsim with implicit vopt
export QUESTA_FLOW_MODE="auto"        # Auto-detect (default)
```

### Alternative Control: `QUESTA_ENABLE_TWO_STEP`

```bash
export QUESTA_ENABLE_TWO_STEP=1  # Enable two-step flow (default)
export QUESTA_ENABLE_TWO_STEP=0  # Use single-step flow
```

**Note:** `QUESTA_FLOW_MODE` takes precedence if set. If `QUESTA_FLOW_MODE="auto"`, then `QUESTA_ENABLE_TWO_STEP` is used.

---

## Default Behavior

**By default**, the plugin uses **two-step flow** (production-grade):

```bash
# These are equivalent (all use two-step flow):
# (no variables set)
export QUESTA_FLOW_MODE="auto"
export QUESTA_FLOW_MODE="two-step"
export QUESTA_ENABLE_TWO_STEP=1
```

---

## Usage Examples

### Example 1: Development (Single-Step)

Fast iteration during daily development:

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_FLOW_MODE="single-step"

# Run plugin → uses vsim with implicit vopt
```

### Example 2: Production (Two-Step - Default)

Production regression with explicit control:

```bash
export QUESTA_BIN_DIR=/path/to/bin
# QUESTA_FLOW_MODE not set → defaults to two-step

# Or explicitly:
export QUESTA_FLOW_MODE="two-step"

# Run plugin → uses vopt then vsim
```

### Example 3: Coverage with Two-Step

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_FLOW_MODE="two-step"
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=coverage.ucdb

# vopt instruments for coverage
# vsim collects coverage data
```

### Example 4: Quick Test (Single-Step)

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_TWO_STEP=0  # Single-step via alternative control

# Run plugin → vsim only (faster for one-off tests)
```

### Example 5: Regression Suite (Two-Step)

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_FLOW_MODE="two-step"
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_AUTO_QUIT=1

# Elaborate once with vopt
# Run multiple simulations with vsim
```

---

## How It Works

### Single-Step Flow

```
┌────────────────────────────────────────┐
│ vsim (with -voptargs)                  │
│ • Implicit vopt in background          │
│ • Optimization flags via -voptargs     │
│ • One command, faster for single runs  │
└────────────────────────────────────────┘
```

**Command example:**
```bash
vsim -voptargs="+acc -O5 +cover=sbceft" \
     -batch -coverage \
     work.design
```

### Two-Step Flow

```
┌────────────────────────────────────────┐
│ Step 1: vopt                           │
│ • Explicit elaboration/optimization    │
│ • Creates optimized design (design_opt)│
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│ Step 2: vsim                           │
│ • Simulates optimized design           │
│ • Fast, can reuse for multiple runs    │
└────────────────────────────────────────┘
```

**Command example:**
```bash
# Step 1
vopt -O5 +acc +cover=sbceft \
     work.design -o design_opt

# Step 2
vsim -batch -coverage \
     design_opt
```

---

## Switching Flows

### At Runtime

Simply change the environment variable:

```bash
# Try single-step
export QUESTA_FLOW_MODE="single-step"
# Run plugin

# Try two-step
export QUESTA_FLOW_MODE="two-step"
# Run plugin
```

**All other configuration remains the same!**

### In Shell Scripts

```bash
#!/bin/bash

# Common config
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test

# Choose flow based on need
if [ "$USE_PRODUCTION_FLOW" = "1" ]; then
    export QUESTA_FLOW_MODE="two-step"
else
    export QUESTA_FLOW_MODE="single-step"
fi

# Run simulation
# (invoke Questa Developer plugin command)
```

### In CI/CD Pipelines

```yaml
# .gitlab-ci.yml example

test-quick:
  script:
    - export QUESTA_FLOW_MODE="single-step"
    - export QUESTA_SIM_MODE=batch
    - run_simulation.sh

test-production:
  script:
    - export QUESTA_FLOW_MODE="two-step"
    - export QUESTA_SIM_MODE=batch
    - export QUESTA_ENABLE_COVERAGE=1
    - run_simulation.sh
```

---

## Configuration Details

### Flow Decision Logic

1. **If `QUESTA_FLOW_MODE` is set:**
   - Use `single-step` or `two-step` explicitly
   - If `auto`, proceed to step 2

2. **If `QUESTA_FLOW_MODE="auto"` or not set:**
   - Check `QUESTA_ENABLE_TWO_STEP`
   - If `1` (default): use two-step
   - If `0`: use single-step

3. **Validation:**
   - Script validates flow mode is valid
   - Errors out if invalid value provided

### Single-Step Behavior

When `QUESTA_FLOW_MODE="single-step"`:

- **vopt stage:** Skipped (no explicit vopt command)
- **vsim stage:** Runs with `-voptargs` containing:
  - Optimization level (`-O5` or `-O0` for debug)
  - Access level (`+acc`)
  - Coverage flags (`+cover=sbceft`)
  - Assertions (`-assertdebug`)
  - FSM debug (`-fsmdebug`)
  - Extra vopt args

**Result:** Single vsim command with implicit optimization

### Two-Step Behavior

When `QUESTA_FLOW_MODE="two-step"`:

- **vopt stage:** Explicit command with:
  - Optimization level
  - Access level
  - Coverage instrumentation
  - Assertions
  - FSM debug
  - Output: `<design>_opt`
  - Log: `vopt.log`

- **vsim stage:** Simulates optimized design:
  - Input: `<design>_opt`
  - Coverage collection (not instrumentation)
  - Waveform capture
  - UVM settings
  - Log: `simulation.log`

**Result:** Two commands, better control and performance

---

## Feature Compatibility

### All Features Work with Both Flows

✅ **Coverage** - Single-step uses -voptargs, two-step uses explicit vopt flags  
✅ **UVM** - Plusargs work identically in both flows  
✅ **Waveform** - Capture works the same in vsim stage  
✅ **VIP/PLI** - Loaded during vsim in both flows  
✅ **Debug** - Single-step uses -voptargs, two-step uses vopt access flags  
✅ **Assertions** - Enabled in vopt or via -voptargs  
✅ **FSM Debug** - Enabled in vopt or via -voptargs  
✅ **Power Analysis** - Works in both flows  
✅ **Visualizer** - GUI mode works in both flows  

### No Configuration Changes Required

When switching flows, **keep all other variables the same**:

```bash
# This config works for BOTH flows:
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB=test.ucdb
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test

# Just change the flow:
export QUESTA_FLOW_MODE="single-step"  # or "two-step"
```

---

## Logs and Outputs

### Single-Step Flow Logs

```
project/
├── questasim_script.sh      (generated script)
├── transcript               (QuestaSim transcript)
└── simulation.log           (if QUESTA_VSIM_LOG_FILE set)
```

### Two-Step Flow Logs

```
project/
├── questasim_script.sh      (generated script)
├── vopt.log                 (vopt elaboration log)
├── simulation.log           (vsim simulation log)
└── transcript               (QuestaSim transcript)
```

### Log File Control

```bash
# Two-step specific:
export QUESTA_VOPT_LOG_FILE=my_vopt.log
export QUESTA_VSIM_LOG_FILE=my_vsim.log

# Both flows:
export QUESTA_TRANSCRIPT_FILE=my_transcript
```

---

## Performance Comparison

### Single Run

| Flow | Time | Best For |
|------|------|----------|
| Single-step | ~100% | One-off tests, development |
| Two-step | ~105% | Better logging, debugging |

**Verdict:** Single-step slightly faster for one simulation

### Multiple Runs (100 tests)

| Flow | Time | Best For |
|------|------|----------|
| Single-step | ~10000% (elaborate 100×) | Not recommended |
| Two-step | ~200% (elaborate 1×) | Regression, coverage |

**Verdict:** Two-step dramatically faster for multiple runs

---

## Best Practices

### Use Single-Step When:
- ✅ Daily development with frequent code changes
- ✅ Quick sanity checks
- ✅ Single simulation runs
- ✅ Learning/exploring the design

### Use Two-Step When:
- ✅ Production regressions (10+ tests)
- ✅ Coverage collection and analysis
- ✅ CI/CD pipelines
- ✅ Multiple simulation runs on same design
- ✅ Performance-critical workflows
- ✅ Need separate elaboration/simulation logs

### Default Recommendation

**Start with two-step** (the default) unless you have a specific reason to use single-step. Two-step is the official Siemens recommendation and provides better control.

---

## Troubleshooting

### Issue: Don't know which flow is running

**Solution:** Check the log output

```
[INFO] QuestaSim Configuration
========================================
Flow: two-step
Mode: batch
...
```

Or set explicitly:

```bash
export QUESTA_FLOW_MODE="two-step"
```

### Issue: Want to force single-step

**Solution:** Use explicit setting

```bash
export QUESTA_FLOW_MODE="single-step"
# NOT "auto" - be explicit
```

### Issue: vopt not running when expected

**Solution:** Check flow mode

```bash
# Make sure two-step is enabled:
export QUESTA_FLOW_MODE="two-step"

# Or:
export QUESTA_ENABLE_TWO_STEP=1
export QUESTA_FLOW_MODE="auto"
```

### Issue: -voptargs not working

**Solution:** You're probably in two-step mode

```bash
# Single-step uses -voptargs:
export QUESTA_FLOW_MODE="single-step"

# Two-step uses explicit vopt command (no -voptargs)
export QUESTA_FLOW_MODE="two-step"
```

---

## Migration from Old Config

### Old Approach (Config-Based)

Previously, you selected flow via plugin command:
- "QuestaSim Simulation (vsim)" → single-step
- "QuestaSim Simulation (vopt + vsim)" → two-step

### New Approach (Shell-Based)

Now, one plugin command, flow controlled by environment:

```bash
# Single-step
export QUESTA_FLOW_MODE="single-step"
# Run "QuestaSim Simulation" command

# Two-step
export QUESTA_FLOW_MODE="two-step"
# Run "QuestaSim Simulation" command
```

**Benefit:** More flexible, scriptable, easier to automate

---

## Quick Reference

### Enable Two-Step (Default)
```bash
export QUESTA_FLOW_MODE="two-step"
# or
export QUESTA_ENABLE_TWO_STEP=1
# or
# (leave unset - two-step is default)
```

### Enable Single-Step
```bash
export QUESTA_FLOW_MODE="single-step"
# or
export QUESTA_ENABLE_TWO_STEP=0
```

### Check Current Flow
```bash
# Look for this in output:
[INFO] Flow: two-step
# or
[INFO] Flow: single-step
```

---

## Summary

✅ **Shell-controlled:** Flow determined by environment variables, not config.json  
✅ **Flexible:** Change flow without modifying config files  
✅ **Default:** Two-step flow (production-grade)  
✅ **Compatible:** All features work with both flows  
✅ **Simple:** One plugin command, flow controlled by `QUESTA_FLOW_MODE`  
✅ **Scriptable:** Easy to automate in CI/CD or shell scripts  

**Choose your flow with one variable, keep everything else the same! 🚀**
