# QuestaSim Two-Step Flow: vopt + vsim

## Overview

This plugin provides a **two-step simulation flow** following official Siemens Questa best practices:

1. **Step 1 - vopt**: Elaborate and optimize the compiled design
2. **Step 2 - vsim**: Simulate the optimized design

This approach provides better control over the optimization and simulation stages compared to the single-step flow where `vsim` implicitly calls `vopt` in the background.

---

## Why Two-Step Flow?

### Benefits

✅ **Explicit Control**: Separate optimization flags from simulation flags  
✅ **Better Performance**: Optimized design can be simulated multiple times without re-optimization  
✅ **Debug Flexibility**: Can adjust visibility (`+acc`, `-access`) at elaboration time  
✅ **Coverage Precision**: Coverage instrumentation happens during vopt  
✅ **Official Recommendation**: Follows Siemens Questa User's Manual three-step flow (compile → vopt → vsim)

### When to Use

- **Production workflows**: Regression testing, CI/CD pipelines
- **Coverage analysis**: When code coverage is critical
- **Debug sessions**: When you need explicit control over visibility
- **Multiple runs**: Optimize once, simulate many times with different seeds/tests

---

## Architecture

### Design Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Step 0: Compilation (Already Done via Questa Developer)    │
│ • Source files compiled into libraries (modelsim.ini)      │
│ • Design units available in work library                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 1: vopt (Elaboration/Optimization)                    │
│ • Input: Compiled libraries + top-level design units       │
│ • Flags: +acc, +cover, -O5, -assertdebug, -fsmdebug       │
│ • Output: Optimized design (e.g., tb_ahb_subordinate_opt) │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Step 2: vsim (Simulation)                                  │
│ • Input: Optimized design from vopt                        │
│ • Flags: -batch/-gui/-visualizer, waveform, UVM, DO file  │
│ • Output: Simulation results, coverage DB, waveforms       │
└─────────────────────────────────────────────────────────────┘
```

### Naming Convention

Following official Siemens examples:

```bash
# Top-level design: tb_ahb_subordinate
# Optimized design: tb_ahb_subordinate_opt

vopt tb_ahb_subordinate -o tb_ahb_subordinate_opt
vsim tb_ahb_subordinate_opt
```

The plugin automatically appends `_opt` suffix to your top-level design name.

---

## Configuration

### Required Environment Variables

Only **one** required variable:

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

### Key Optional Variables

All other variables are optional with sensible defaults.

#### vopt Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_VOPT_OPTIMIZE_LEVEL` | `-O5` | Optimization level (-O0 to -O5) |
| `QUESTA_VOPT_ACCESS` | `+acc` | Debug visibility (use `+acc` for full access) |
| `QUESTA_VOPT_DEBUG` | `0` | Enable debug mode (1=yes, 0=no) |
| `QUESTA_VOPT_EXTRA_ARGS` | `""` | Additional vopt arguments |

#### vsim Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_SIM_MODE` | `gui` | Simulation mode: `gui`, `batch`, `interactive` |
| `QUESTA_SIM_ARCH` | `64` | Architecture: `64` or `32` bit |
| `QUESTA_SIM_TIME_RESOLUTION` | `1ps` | Time resolution (e.g., `1ps`, `1ns`) |
| `QUESTA_AUTO_QUIT` | `1` | Auto-quit after simulation (batch mode) |
| `QUESTA_RUN_TIME` | `run -all` | Simulation run command |

#### Coverage (vopt stage)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_COVERAGE` | `0` | Enable coverage (1=yes, 0=no) |
| `QUESTA_COVERAGE_OPTIONS` | `+cover=sbceft` | Coverage types (s=statement, b=branch, c=condition, e=expression, f=fsm, t=toggle) |
| `QUESTA_COVERAGE_DB` | `coverage.ucdb` | Coverage database file |

#### UVM (vsim stage)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_UVM` | `0` | Enable UVM (1=yes, 0=no) |
| `QUESTA_UVM_TESTNAME` | `""` | UVM test name (+UVM_TESTNAME) |
| `QUESTA_UVM_VERBOSITY` | `UVM_MEDIUM` | UVM verbosity level |

#### Waveform (vsim stage)

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_ENABLE_WAVEFORM` | `0` | Enable waveform capture (1=yes, 0=no) |
| `QUESTA_WAVEFORM_FORMAT` | `wlf` | Format: `wlf`, `vcd`, `fsdb` |
| `QUESTA_WAVEFORM_FILE` | `vsim.wlf` | Waveform filename |

---

## Usage Examples

### Example 1: Basic Two-Step GUI Simulation

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin

# Run plugin command: "QuestaSim Simulation (vopt + vsim)"
```

**What happens:**
1. vopt creates optimized design: `tb_ahb_subordinate_opt`
2. vsim simulates in GUI mode

---

### Example 2: Batch Regression with Coverage

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB=regression_coverage.ucdb
export QUESTA_AUTO_QUIT=1

# Run plugin command: "QuestaSim Simulation (vopt + vsim)"
```

**What happens:**
1. vopt adds `+cover=sbceft` flags (code coverage instrumentation)
2. vsim runs in batch mode with `-coverage` flag
3. Coverage data saved to `regression_coverage.ucdb`
4. Auto-quits after simulation

---

### Example 3: UVM Testbench with Debug

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
export QUESTA_VOPT_ACCESS="+acc"
export QUESTA_VOPT_DEBUG=1
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=smoke_test
export QUESTA_UVM_VERBOSITY=UVM_HIGH
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT=wlf
export QUESTA_WAVEFORM_FILE=uvm_debug.wlf

# Run plugin command: "QuestaSim Simulation (vopt + vsim)"
```

**What happens:**
1. vopt with `+acc` for full debug visibility
2. vsim with UVM plusargs: `+UVM_TESTNAME=smoke_test +UVM_VERBOSITY=UVM_HIGH`
3. Waveform captured to `uvm_debug.wlf`

---

### Example 4: VIP Simulation

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
export AVERY_PLI=/path/to/avery
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB=${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so

# Run plugin command: "QuestaSim Simulation (vopt + vsim)"
```

**What happens:**
1. vopt elaborates design
2. vsim loads PLI library: `-pli libtb_ms.so`
3. VIP protocols available in simulation

---

### Example 5: Production Regression (Optimized)

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O5
export QUESTA_VOPT_ACCESS="+acc=r"  # Read-only access for minimal overhead
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbce"
export QUESTA_AUTO_QUIT=1
export QUESTA_RUN_TIME="run -all"

# Run plugin command: "QuestaSim Simulation (vopt + vsim)"
```

**What happens:**
1. vopt with maximum optimization (`-O5`)
2. Minimal debug access (`+acc=r`)
3. Coverage on statement/branch/condition/expression
4. Batch mode for CI/CD integration

---

## Command Line Examples

### Manual vopt + vsim Commands

If you want to see what the plugin generates, here are equivalent manual commands:

#### Step 1: vopt

```bash
vopt -64 \
  -modelsimini questa.ini \
  -O5 \
  +acc \
  +cover=sbceft \
  -assertdebug \
  -L work \
  -L support_lib \
  work.tb_ahb_subordinate \
  -o tb_ahb_subordinate_opt \
  -l vopt.log
```

#### Step 2: vsim

```bash
vsim -64 \
  -batch -quiet \
  -t 1ps \
  -modelsimini questa.ini \
  +nowarnTSCALE +nowarnTFMPC \
  -coverage \
  -coverstore coverage.ucdb \
  -L work \
  -L support_lib \
  tb_ahb_subordinate_opt \
  -l simulation.log \
  -do "run -all; quit -f"
```

---

## Logs and Outputs

### Log Files

| File | Description |
|------|-------------|
| `vopt.log` | vopt elaboration/optimization log |
| `simulation.log` | vsim simulation log |
| `transcript` | QuestaSim transcript |

### Output Files

| File | When Created | Description |
|------|--------------|-------------|
| `coverage.ucdb` | Coverage enabled | Code coverage database |
| `vsim.wlf` | Waveform enabled | Waveform database (ModelSim/Questa) |
| `*.vcd` | VCD format | Value Change Dump (standard format) |
| `*.fsdb` | FSDB format | Verdi waveform database |

---

## Comparison: Single-Step vs Two-Step

### Single-Step Flow (template_questasim_script.sh)

```
┌─────────────────────────────────────────┐
│ vsim (implicit vopt in background)     │
│ • Optimization hidden                   │
│ • Less control over elaboration         │
│ • Good for quick simulations            │
└─────────────────────────────────────────┘
```

**Pros:**
- Simpler (one command)
- Faster for quick tests
- Good for development

**Cons:**
- Less control over optimization
- Can't reuse optimized design
- Harder to debug elaboration issues

### Two-Step Flow (template_vopt_vsim_script.sh)

```
┌─────────────────────────────────────────┐
│ vopt (explicit elaboration)             │
│ • Full control over optimization        │
│ • Explicit visibility settings          │
│ • Coverage instrumentation              │
└─────────────────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ vsim (simulate optimized design)        │
│ • Fast startup (no elaboration)         │
│ • Can run multiple times on same design │
│ • Clear separation of concerns          │
└─────────────────────────────────────────┘
```

**Pros:**
- Full control over each stage
- Better performance for multiple runs
- Easier debugging
- Official recommendation

**Cons:**
- Slightly more complex
- Two commands instead of one

---

## Troubleshooting

### Issue: "Design unit not found"

**Symptom:** vopt can't find the top-level design unit

**Solution:** Check that:
1. Compilation completed successfully (check modelsim.ini)
2. Top-level unit name is correct in Questa Developer project
3. Library name matches compiled library

### Issue: "Coverage not collected"

**Symptom:** coverage.ucdb is empty or missing

**Solution:**
1. Ensure `QUESTA_ENABLE_COVERAGE=1`
2. Coverage must be enabled during **vopt** stage (not just vsim)
3. Check vopt log for coverage instrumentation messages

### Issue: "Can't see signals in waveform"

**Symptom:** Waveform file exists but signals not visible

**Solution:**
1. Check `QUESTA_VOPT_ACCESS` setting (use `+acc` for full visibility)
2. vopt must have visibility flags (`+acc` or `-access`)
3. For selective access: `+acc=npr` (nets, ports, registers)

### Issue: "Simulation too slow"

**Symptom:** Simulation takes too long

**Solution:**
1. Reduce visibility: `QUESTA_VOPT_ACCESS="+acc=r"` (read-only)
2. Increase optimization: `QUESTA_VOPT_OPTIMIZE_LEVEL=-O5`
3. Disable waveform if not needed: `QUESTA_ENABLE_WAVEFORM=0`

---

## Advanced Configuration

### Custom DO Files

```bash
export QUESTA_CUSTOM_DO_FILE=/path/to/my_commands.do
```

The plugin will execute your DO file after loading the design.

### Custom Plusargs

```bash
export QUESTA_CUSTOM_PLUSARGS="+seed=42 +timeout=1000"
```

### FSM Debug

```bash
export QUESTA_ENABLE_FSM_DEBUG=1
```

Enables FSM debugging (adds `-fsmdebug` to vopt).

### Power Analysis

```bash
export QUESTA_ENABLE_POWER=1
export QUESTA_POWER_OPTIONS="-power"
```

---

## Best Practices

1. **Always use two-step flow for production** - Better control and performance
2. **Use single-step for quick development** - Faster iteration during coding
3. **Enable coverage during vopt** - Coverage instrumentation must happen at elaboration
4. **Minimize visibility for regressions** - Use `+acc=r` instead of `+acc` for speed
5. **Reuse optimized designs** - Run vopt once, vsim many times with different seeds
6. **Check vopt log first** - Elaboration errors easier to debug in separate log

---

## References

- **Questa SIM User's Manual** (2024.3-2025.3): Chapter on three-step simulation flow
- **Official Examples**: `vopt +acc test_ringbuf -o test_ringbuf_opt` → `vsim test_ringbuf_opt`
- **Siemens Documentation**: Search FUSE server for "vopt elaboration" and "vsim optimized design"

---

## Quick Reference Card

### Minimal Setup (GUI)
```bash
export QUESTA_BIN_DIR=/path/to/bin
# Run plugin → done!
```

### Batch Regression
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_SIM_MODE=batch
export QUESTA_AUTO_QUIT=1
```

### Coverage + Waveform
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_WAVEFORM=1
```

### UVM Test
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test
```

---

**Happy Simulating! 🚀**
