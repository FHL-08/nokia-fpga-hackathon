# QuestaSim Plugin: Flow Selection Guide

## Overview

The QuestaSim plugin now provides **two simulation flows**:

1. **Single-Step Flow** (`template_questasim_script.sh`) - vsim only
2. **Two-Step Flow** (`template_vopt_vsim_script.sh`) - vopt + vsim

This guide helps you choose the right flow for your use case.

---

## Quick Decision Matrix

| Use Case | Recommended Flow | Why |
|----------|------------------|-----|
| **Quick dev/debug during coding** | Single-Step | Faster iteration, less setup |
| **Production regressions** | Two-Step | Better control, official best practice |
| **Coverage analysis** | Two-Step | Explicit coverage instrumentation |
| **Multiple simulation runs** | Two-Step | Optimize once, simulate many times |
| **CI/CD pipelines** | Two-Step | Explicit control, better logging |
| **Interactive debugging** | Single-Step | Simpler setup |
| **Performance optimization** | Two-Step | Control over optimization level |
| **UVM testbenches** | Either | Both work, Two-Step preferred for production |
| **VIP simulation** | Either | Both work equally well |
| **Learning/exploration** | Single-Step | Simpler, less to understand |

---

## Detailed Comparison

### Single-Step Flow (vsim)

**How it works:**
```bash
vsim <design>  # Implicitly calls vopt in background
```

**Command in Questa Developer:**
- "QuestaSim Simulation (vsim)"

**Pros:**
✅ Simpler - one command  
✅ Faster for quick tests  
✅ Less configuration needed  
✅ Good for iterative development  
✅ Easier for beginners  

**Cons:**
❌ Less control over optimization  
❌ Can't reuse optimized design  
❌ Harder to debug elaboration issues  
❌ Optimization flags mixed with simulation flags  

**Best for:**
- Daily development/debugging
- Quick sanity checks
- Learning QuestaSim
- When you just want to "run it"

---

### Two-Step Flow (vopt + vsim)

**How it works:**
```bash
vopt <design> -o <design>_opt  # Step 1: Elaborate/optimize
vsim <design>_opt              # Step 2: Simulate
```

**Command in Questa Developer:**
- "QuestaSim Simulation (vopt + vsim)"

**Pros:**
✅ Full control over each stage  
✅ Better performance for multiple runs  
✅ Explicit coverage instrumentation  
✅ Easier debugging (separate logs)  
✅ Official Siemens recommendation  
✅ Can reuse optimized design  
✅ Clear separation of concerns  

**Cons:**
❌ Slightly more complex  
❌ Two stages instead of one  
❌ More to understand  

**Best for:**
- Production workflows
- Regression testing
- Coverage collection
- CI/CD integration
- Performance-critical simulations
- When you need explicit control

---

## Technical Differences

### Flag Distribution

#### Single-Step Flow (vsim)
All flags go to vsim:
```bash
vsim -voptargs="+acc" \
     -batch \
     +cover=sbceft \
     -L work \
     design
```

#### Two-Step Flow (vopt + vsim)
Flags separated by purpose:

**vopt** (elaboration):
```bash
vopt +acc \
     +cover=sbceft \
     -O5 \
     -assertdebug \
     -L work \
     design -o design_opt
```

**vsim** (simulation):
```bash
vsim -batch \
     -coverage \
     -L work \
     design_opt
```

### Performance

**Single-Step:**
- Each vsim call re-elaborates the design
- Good for: single runs
- Not ideal for: multiple runs with different seeds

**Two-Step:**
- Elaborate once, simulate many times
- Good for: regression suites
- Example: 100 tests → 1 vopt + 100 vsim (fast!)

---

## Use Case Examples

### Use Case 1: Daily Development

**Scenario:** You're writing RTL, need quick compile-simulate-debug cycles.

**Recommendation:** **Single-Step**

```bash
export QUESTA_BIN_DIR=/path/to/bin
# Just hit "Run Simulation (vsim)" in Questa Developer
```

**Why:**
- Fastest iteration
- Don't need advanced features
- Just want to see if code works

---

### Use Case 2: Nightly Regression

**Scenario:** Automated regression with 500 tests, coverage required.

**Recommendation:** **Two-Step**

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=regression_cov.ucdb
export QUESTA_AUTO_QUIT=1

# Step 1: Elaborate once
vopt design -o design_opt +cover=sbceft

# Step 2: Run 500 tests on optimized design
for seed in {1..500}; do
  vsim design_opt +seed=$seed
done
```

**Why:**
- Optimize once, run 500 times (huge time savings)
- Explicit coverage control
- Better logging/debugging
- Production-grade approach

---

### Use Case 3: Coverage Analysis

**Scenario:** Need detailed code coverage report.

**Recommendation:** **Two-Step**

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB=detailed_cov.ucdb
```

**Why:**
- Coverage instrumentation explicit in vopt
- Better control over coverage types
- Easier to debug coverage issues

---

### Use Case 4: UVM Debug Session

**Scenario:** UVM testbench failing, need to debug with waveforms.

**Recommendation:** **Either flow works**

**Single-Step (simpler):**
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=failing_test
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_ENABLE_DEBUG=1
```

**Two-Step (more control):**
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_VOPT_ACCESS="+acc"  # Full visibility
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=failing_test
export QUESTA_ENABLE_WAVEFORM=1
```

**Single-Step is fine** - you're doing one simulation anyway.

---

### Use Case 5: CI/CD Pipeline

**Scenario:** Jenkins/GitLab CI running automated tests.

**Recommendation:** **Two-Step**

```bash
#!/bin/bash
# Jenkins job script

export QUESTA_BIN_DIR=/tools/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=ci_coverage_${BUILD_ID}.ucdb
export QUESTA_AUTO_QUIT=1
export QUESTA_VOPT_LOG_FILE=vopt_${BUILD_ID}.log
export QUESTA_VSIM_LOG_FILE=vsim_${BUILD_ID}.log

# Run via Questa Developer plugin
# Plugin generates separate vopt.log and vsim.log
# Easier to parse for CI reporting
```

**Why:**
- Separate logs easier to parse
- Better error reporting
- Explicit control for CI environment
- Production-grade approach

---

### Use Case 6: VIP Simulation

**Scenario:** Using Siemens VIP (e.g., AXI, AHB protocols).

**Recommendation:** **Either flow works**

Both flows support VIP equally:

```bash
export QUESTA_BIN_DIR=/path/to/bin
export AVERY_PLI=/path/to/avery
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB=${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so
```

Choose based on **other requirements** (coverage, regression, etc.).

---

### Use Case 7: Performance Optimization

**Scenario:** Simulation too slow, need to optimize.

**Recommendation:** **Two-Step**

```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O5  # Maximum optimization
export QUESTA_VOPT_ACCESS="+acc=r"     # Minimal visibility (faster)
export QUESTA_SIM_MODE=batch
```

**Why:**
- Explicit control over optimization level
- Can tune visibility for performance
- See optimization effects in vopt.log

---

## Migration Path

### Already Using Single-Step?

No need to migrate unless you need:
- Better performance for multiple runs
- Explicit coverage control
- Production-grade workflows

### When to Migrate

Migrate from Single-Step → Two-Step when:

1. **Running regressions** with 10+ tests
2. **Coverage is critical** (production requirement)
3. **CI/CD integration** needed
4. **Debugging elaboration issues** (separate logs help)
5. **Performance matters** (optimize once, run many)

### How to Migrate

1. Start using "QuestaSim Simulation (vopt + vsim)" command in Questa Developer
2. Same environment variables work
3. Check logs: `vopt.log` and `simulation.log` instead of single `transcript`
4. Optimized design named `<your_design>_opt`

---

## Environment Variable Compatibility

**Good news:** Both flows use **same environment variables**!

You can switch flows without changing configuration:

```bash
# This config works for BOTH flows
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test
```

Just change the command in Questa Developer:
- "QuestaSim Simulation (vsim)" → Single-Step
- "QuestaSim Simulation (vopt + vsim)" → Two-Step

---

## Summary Table

| Feature | Single-Step | Two-Step |
|---------|-------------|----------|
| **Complexity** | Simple | Moderate |
| **Speed (single run)** | Fast | Slightly slower |
| **Speed (multiple runs)** | Slow | Fast |
| **Control** | Limited | Full |
| **Debugging** | Moderate | Excellent |
| **Coverage** | Works | Better |
| **Production Use** | OK | Recommended |
| **Learning Curve** | Easy | Moderate |
| **Official Rec** | No | Yes |
| **Separate Logs** | No | Yes |
| **Reusable Opt** | No | Yes |

---

## Recommendations by Team Role

### RTL Designer (Daily Coding)
- **Use:** Single-Step
- **Why:** Fast iteration, simple setup

### Verification Engineer (Testbench Dev)
- **Use:** Single-Step for dev, Two-Step for regression
- **Why:** Balance speed and control

### DV Lead (Coverage/Sign-off)
- **Use:** Two-Step
- **Why:** Production-grade, explicit coverage

### DevOps/CI Engineer
- **Use:** Two-Step
- **Why:** Better logging, explicit control

### Manager (Just Running Tests)
- **Use:** Either
- **Why:** Both work fine, choose simpler (Single-Step)

---

## Final Recommendation

### Start Simple, Scale When Needed

1. **Start:** Single-Step (simple, fast)
2. **Scale:** Two-Step when you need:
   - Regression automation
   - Coverage requirements
   - CI/CD integration
   - Performance optimization

### Default Choice

- **Development:** Single-Step
- **Production:** Two-Step

### When in Doubt

Choose **Single-Step** for simplicity. You can always switch to Two-Step later without changing configuration.

---

## Quick Commands

### Single-Step
```bash
# In Questa Developer: "QuestaSim Simulation (vsim)"
export QUESTA_BIN_DIR=/path/to/bin
```

### Two-Step
```bash
# In Questa Developer: "QuestaSim Simulation (vopt + vsim)"
export QUESTA_BIN_DIR=/path/to/bin
```

Same config, different flow!

---

**Choose wisely, simulate confidently! 🚀**
