# QuestaSim Plugin - Quick Reference Card

## Minimal Setup (Required Only)

```bash
export QUESTA_BIN_DIR="/path/to/questasim/bin"
```

That's it! Everything else is optional.

---

## Common Configurations

### GUI Simulation (Default)
No extra variables needed - just run!

### Batch Mode
```bash
export QUESTA_SIM_MODE=batch
export QUESTA_AUTO_QUIT=1
```

### With Coverage
```bash
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=my_cov.ucdb
```

### UVM Test
```bash
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=my_test
export QUESTA_UVM_VERBOSITY=UVM_HIGH
```

### Capture Waveforms
```bash
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE=waves.wlf
```

### Debug Mode
```bash
export QUESTA_ENABLE_DEBUG=1
export QUESTA_DEBUG_LEVEL="+acc=npr"
```

### VIP Support
```bash
export AVERY_PLI=/path/to/avery_pli
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
```

### Optimized Regression
```bash
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_VOPT=1
export QUESTA_VOPT_OPTIONS="-O5"
export QUESTA_AUTO_QUIT=1
```

---

## Variable Quick Lookup

| What I Want | Variable | Example Value |
|-------------|----------|---------------|
| Batch mode | `QUESTA_SIM_MODE` | `batch` |
| Coverage | `QUESTA_ENABLE_COVERAGE` | `1` |
| UVM test | `QUESTA_UVM_TESTNAME` | `base_test` |
| Waveforms | `QUESTA_ENABLE_WAVEFORM` | `1` |
| Debug | `QUESTA_ENABLE_DEBUG` | `1` |
| VIP | `QUESTA_VIP_ENABLE` | `1` |
| Fast sim | `QUESTA_ENABLE_VOPT` | `1` |
| Custom time | `QUESTA_RUN_TIME` | `run 10ms` |
| FSM debug | `QUESTA_ENABLE_FSM_DEBUG` | `1` |
| Power | `QUESTA_ENABLE_POWER` | `1` |
| Visualizer | `QUESTA_ENABLE_VISUALIZER` | `1` |

---

## All Variables at a Glance

### Must Have ✓
- `QUESTA_BIN_DIR` - Path to QuestaSim bin

### Simulation Control
- `QUESTA_SIM_MODE` - gui/batch/interactive
- `QUESTA_SIM_ARCH` - 32/64
- `QUESTA_SIM_TIME_RESOLUTION` - 1ps, 1ns, etc.
- `QUESTA_RUN_TIME` - run -all, run 10ms, etc.
- `QUESTA_AUTO_QUIT` - 0/1

### Coverage
- `QUESTA_ENABLE_COVERAGE` - 0/1
- `QUESTA_COVERAGE_OPTIONS` - Coverage flags
- `QUESTA_COVERAGE_DB` - DB filename

### UVM
- `QUESTA_ENABLE_UVM` - 0/1
- `QUESTA_UVM_TESTNAME` - Test name
- `QUESTA_UVM_VERBOSITY` - UVM_LOW/MEDIUM/HIGH
- `QUESTA_UVM_CONFIG_DB` - Enable trace

### Waveforms
- `QUESTA_ENABLE_WAVEFORM` - 0/1
- `QUESTA_WAVEFORM_FORMAT` - wlf/vcd/fsdb
- `QUESTA_WAVEFORM_FILE` - Filename
- `QUESTA_WAVEFORM_DB` - qwavedb options

### Debug & Optimization
- `QUESTA_ENABLE_DEBUG` - 0/1
- `QUESTA_DEBUG_LEVEL` - +acc, +acc=npr
- `QUESTA_ENABLE_VOPT` - 0/1
- `QUESTA_VOPT_OPTIONS` - -O5, etc.

### VIP
- `QUESTA_VIP_ENABLE` - 0/1
- `QUESTA_VIP_PLI_LIB` - Path to .so
- `AVERY_PLI` - Avery installation

### Advanced
- `QUESTA_ENABLE_ASSERTIONS` - 0/1
- `QUESTA_ENABLE_FSM_DEBUG` - 0/1
- `QUESTA_ENABLE_POWER` - 0/1
- `QUESTA_ENABLE_VISUALIZER` - 0/1
- `QUESTA_CUSTOM_DO_FILE` - Custom script
- `QUESTA_CUSTOM_PLUSARGS` - +args
- `QUESTA_CUSTOM_DEFINES` - -Ddefines

### Logging
- `QUESTA_LOG_FILE` - Log filename
- `QUESTA_TRANSCRIPT_FILE` - Transcript name

---

## Typical Workflows

### Development (Interactive Debug)
```bash
export QUESTA_BIN_DIR=/tools/questa/bin
export QUESTA_ENABLE_DEBUG=1
export QUESTA_ENABLE_WAVEFORM=1
# Run in GUI (default)
```

### Verification (Coverage + UVM)
```bash
export QUESTA_BIN_DIR=/tools/questa/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=full_regression
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=regression.ucdb
export QUESTA_AUTO_QUIT=1
```

### Regression (Fast Batch)
```bash
export QUESTA_BIN_DIR=/tools/questa/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_VOPT=1
export QUESTA_VOPT_OPTIONS="-O5"
export QUESTA_RUN_TIME="run 1ms"
export QUESTA_AUTO_QUIT=1
```

### VIP Testbench
```bash
export QUESTA_BIN_DIR=/tools/questa/bin
export AVERY_PLI=/tools/avery/vip/avery_pli-2025.2
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=ahb_test
```

---

## Defaults (If You Don't Set Anything)

| Feature | Default Behavior |
|---------|------------------|
| Mode | GUI |
| Architecture | 64-bit |
| Time Resolution | 1ps |
| Run Command | run -all |
| Coverage | Disabled |
| UVM | Disabled |
| Waveform | Disabled |
| Debug | Basic (+acc) |
| VIP | Disabled |
| Assertions | Enabled |
| FSM Debug | Disabled |
| Power | Disabled |

---

## Environment Setup Script Template

Save as `questa_env.sh`:

```bash
#!/bin/bash
# QuestaSim Environment Setup

# === Required ===
export QUESTA_BIN_DIR="/u/release/questa/2025.2/questasim/bin"

# === Optional: Customize as needed ===
export QUESTA_SIM_MODE=batch
export QUESTA_SIM_ARCH=64
export QUESTA_SIM_TIME_RESOLUTION=1ps

# Enable features you need
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_UVM=1
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_ENABLE_DEBUG=0
export QUESTA_ENABLE_VOPT=0

# UVM configuration
export QUESTA_UVM_TESTNAME=my_test
export QUESTA_UVM_VERBOSITY=UVM_MEDIUM

# File names
export QUESTA_COVERAGE_DB=coverage.ucdb
export QUESTA_WAVEFORM_FILE=waves.wlf
export QUESTA_LOG_FILE=simulation.log

# VIP support (if needed)
# export AVERY_PLI=/path/to/avery_pli
# export QUESTA_VIP_ENABLE=1
# export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"

echo "QuestaSim environment configured"
```

Usage:
```bash
source questa_env.sh
# Run simulation via plugin
```

---

## Tips

1. **Start Simple**: Only set `QUESTA_BIN_DIR`, run simulation, add features as needed
2. **Incremental**: Enable one feature at a time to verify configuration
3. **Debug First**: Use GUI + debug mode to understand your design
4. **Then Optimize**: Switch to batch + vopt for regression
5. **Check Logs**: Always review `QUESTA_LOG_FILE` for errors
6. **Version Match**: Verify QuestaSim and Questa Developer versions match

---

## Getting Help

```bash
# Check QuestaSim version
$QUESTA_BIN_DIR/vsim -version

# List all libraries
ls -la work/

# Verify PLI library
ls -l $QUESTA_VIP_PLI_LIB

# Check generated script
cat questasim_script.sh
```

---

**Remember**: The plugin works with ZERO optional variables! Start simple, add complexity only when needed.
