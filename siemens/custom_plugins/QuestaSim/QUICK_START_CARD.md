# QuestaSim Plugin - Quick Reference Card

## Commands in Questa Developer

```
┌──────────────────────────────────────────────────────────────┐
│ QuestaSim Simulation (vsim)                                  │
│ • Single-step flow                                           │
│ • Best for: Development, quick tests                         │
│ • Template: template_questasim_script.sh                     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ QuestaSim Simulation (vopt + vsim)                           │
│ • Two-step flow: vopt → vsim                                 │
│ • Best for: Production, regression, coverage, CI/CD          │
│ • Template: template_vopt_vsim_script.sh                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Minimal Setup (Required)

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

**That's it!** Both flows work with just this one variable.

---

## Common Configurations

### Development (GUI Mode)
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

### Coverage Collection
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=my_coverage.ucdb
```

### UVM Test
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test
export QUESTA_UVM_VERBOSITY=UVM_HIGH
```

### Debug with Waveforms
```bash
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE=debug.wlf

# Two-step only:
export QUESTA_VOPT_ACCESS="+acc"  # Full visibility
```

### VIP Simulation
```bash
export QUESTA_BIN_DIR=/path/to/bin
export AVERY_PLI=/path/to/avery
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB=${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so
```

---

## Two-Step Flow Specific

### Maximum Optimization (Regression)
```bash
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O5
export QUESTA_VOPT_ACCESS="+acc=r"  # Minimal visibility
export QUESTA_SIM_MODE=batch
```

### Full Debug Mode
```bash
export QUESTA_VOPT_DEBUG=1
export QUESTA_VOPT_ACCESS="+acc"     # Full visibility
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O0
```

### Separate Logs
```bash
export QUESTA_VOPT_LOG_FILE=my_vopt.log
export QUESTA_VSIM_LOG_FILE=my_vsim.log
```

---

## Key Variables Quick Reference

### Simulation Control
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_SIM_MODE` | `gui` | `gui`, `batch`, `interactive` |
| `QUESTA_SIM_ARCH` | `64` | `32`, `64` |
| `QUESTA_AUTO_QUIT` | `1` | `0`, `1` |
| `QUESTA_RUN_TIME` | `run -all` | Any TCL command |

### Coverage
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_ENABLE_COVERAGE` | `0` | `0`, `1` |
| `QUESTA_COVERAGE_OPTIONS` | `+cover=sbceft` | Coverage types |
| `QUESTA_COVERAGE_DB` | `coverage.ucdb` | Filename |

### UVM
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_ENABLE_UVM` | `0` | `0`, `1` |
| `QUESTA_UVM_TESTNAME` | `""` | Test name |
| `QUESTA_UVM_VERBOSITY` | `UVM_MEDIUM` | `UVM_NONE` to `UVM_FULL` |

### Waveform
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_ENABLE_WAVEFORM` | `0` | `0`, `1` |
| `QUESTA_WAVEFORM_FORMAT` | `wlf` | `wlf`, `vcd`, `fsdb` |
| `QUESTA_WAVEFORM_FILE` | `vsim.wlf` | Filename |

### VIP
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_VIP_ENABLE` | `0` | `0`, `1` |
| `QUESTA_VIP_PLI_LIB` | `""` | Path to .so file |

### vopt (Two-Step Only)
| Variable | Default | Options |
|----------|---------|---------|
| `QUESTA_VOPT_OPTIMIZE_LEVEL` | `-O5` | `-O0` to `-O5` |
| `QUESTA_VOPT_ACCESS` | `+acc` | `+acc`, `+acc=npr`, `+acc=r` |
| `QUESTA_VOPT_DEBUG` | `0` | `0`, `1` |
| `QUESTA_VOPT_LOG_FILE` | `vopt.log` | Filename |
| `QUESTA_VSIM_LOG_FILE` | `simulation.log` | Filename |

---

## Decision Tree

```
Need simulation?
│
├─ Development/quick test? → Single-Step (vsim)
│
├─ Production/regression? → Two-Step (vopt + vsim)
│
├─ Coverage required? → Two-Step (vopt + vsim)
│
├─ Multiple runs on same design? → Two-Step (vopt + vsim)
│
├─ CI/CD integration? → Two-Step (vopt + vsim)
│
└─ Just learning? → Single-Step (vsim)
```

---

## Typical Workflows

### Development Cycle
```bash
# Use Single-Step for fast iteration
export QUESTA_BIN_DIR=/path/to/bin

# Edit code → Compile → Run plugin → Debug
# Repeat quickly
```

### Nightly Regression
```bash
# Use Two-Step for efficiency
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=nightly_$(date +%Y%m%d).ucdb
export QUESTA_AUTO_QUIT=1

# Elaborate once (vopt)
# Run 500 tests (vsim × 500)
# Merge coverage
```

### Coverage Sign-off
```bash
# Use Two-Step for explicit control
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_OPTIONS="+cover=sbceft"
export QUESTA_COVERAGE_DB=signoff_coverage.ucdb
export QUESTA_VOPT_ACCESS="+acc=r"  # Minimal overhead
```

### Debug Session
```bash
# Either flow works
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE=debug_$(date +%H%M%S).wlf

# Single-step: simpler
# Two-step: better control
```

---

## Troubleshooting Quick Fixes

### Issue: Simulation hangs
**Fix:** Check mode conflicts
```bash
# If using Visualizer, don't use batch
export QUESTA_ENABLE_VISUALIZER=0
export QUESTA_SIM_MODE=batch
```

### Issue: No coverage data
**Fix:** Enable coverage
```bash
export QUESTA_ENABLE_COVERAGE=1

# Two-step: coverage in vopt stage
```

### Issue: Can't see signals
**Fix:** Increase visibility
```bash
# Two-step only
export QUESTA_VOPT_ACCESS="+acc"  # Full visibility
```

### Issue: Simulation too slow
**Fix:** Reduce visibility, increase optimization
```bash
# Two-step only
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O5
export QUESTA_VOPT_ACCESS="+acc=r"  # Read-only
```

---

## Files and Logs

### Single-Step Flow
```
project/
├── questasim_script.sh          (generated from template)
├── transcript                    (QuestaSim transcript)
└── simulation.log                (if QUESTA_LOG_FILE set)
```

### Two-Step Flow
```
project/
├── questasim_vopt_vsim_script.sh  (generated from template)
├── vopt.log                        (vopt elaboration log)
├── simulation.log                  (vsim simulation log)
└── transcript                      (QuestaSim transcript)
```

### Output Files (Both Flows)
```
├── coverage.ucdb       (if coverage enabled)
├── vsim.wlf            (if waveform enabled, WLF format)
├── dump.vcd            (if waveform enabled, VCD format)
└── dump.fsdb           (if waveform enabled, FSDB format)
```

---

## Manual Command Examples

### Single-Step (Equivalent)
```bash
vsim -batch -quiet \
     -t 1ps \
     -modelsimini questa.ini \
     -coverage \
     +UVM_TESTNAME=test \
     -L work \
     work.design \
     -do "run -all; quit -f"
```

### Two-Step (Equivalent)
```bash
# Step 1: vopt
vopt -64 \
     -modelsimini questa.ini \
     -O5 +acc \
     +cover=sbceft \
     -L work \
     work.design \
     -o design_opt \
     -l vopt.log

# Step 2: vsim
vsim -64 -batch \
     -modelsimini questa.ini \
     -coverage -coverstore coverage.ucdb \
     +UVM_TESTNAME=test \
     -L work \
     design_opt \
     -l simulation.log \
     -do "run -all; quit -f"
```

---

## Documentation Links

- **README.md**: Main documentation
- **FLOW_SELECTION_GUIDE.md**: Choose single-step vs two-step
- **TWO_STEP_FLOW.md**: Deep dive into vopt + vsim
- **QUICK_REFERENCE.md**: Environment variable reference
- **TWO_STEP_IMPLEMENTATION.md**: Implementation details

---

## Version Info

**Current Version:** 2.1  
**Single-Step Template:** `template_questasim_script.sh`  
**Two-Step Template:** `template_vopt_vsim_script.sh`

---

## Environment Variable Compatibility

✅ **All variables work with both flows**  
✅ **Switch flows without changing configuration**  
✅ **Zero-configuration baseline maintained**

---

## Quick Tips

💡 **Start simple**: Use single-step for development  
💡 **Scale when needed**: Switch to two-step for production  
💡 **Same config**: Environment variables work for both flows  
💡 **Debug separately**: Two-step has separate vopt and vsim logs  
💡 **Performance**: Two-step faster for multiple runs  
💡 **Coverage**: Two-step gives explicit control  
💡 **CI/CD**: Two-step better for automation  

---

**Need more detail?** See the full documentation files!

**Quick start?** Set `QUESTA_BIN_DIR` and run the plugin! 🚀
