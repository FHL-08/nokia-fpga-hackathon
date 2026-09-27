# QuestaSim Enhanced Plugin for Questa Developer

## Overview

The **QuestaSim Enhanced Plugin** provides a comprehensive, configurable simulation environment for running QuestaSim simulations directly from Questa Developer. It supports **two simulation flows** and a wide range of optional features including coverage collection, UVM testbenches, waveform capture, VIP integration, debug modes, and optimization settings.

### Available Simulation Flows

1. **Single-Step Flow** (`template_questasim_script.sh`)
   - Command: "QuestaSim Simulation (vsim)"
   - vsim with implicit vopt in background
   - Simple, fast, good for development
   
2. **Two-Step Flow** (`template_vopt_vsim_script.sh`)
   - Command: "QuestaSim Simulation (vopt + vsim)"
   - Explicit vopt elaboration followed by vsim simulation
   - Production-grade, official Siemens recommendation
   - Better control, performance, and debugging

📖 **See [FLOW_SELECTION_GUIDE.md](FLOW_SELECTION_GUIDE.md) for detailed comparison**  
📖 **See [TWO_STEP_FLOW.md](TWO_STEP_FLOW.md) for two-step flow documentation**

## Core Philosophy

- **Works out-of-the-box**: The plugin functions with minimal configuration (only `QUESTA_BIN_DIR` required)
- **Optional features**: All advanced features are opt-in via environment variables
- **Flexible configuration**: Configure via shell environment, IDE settings, or plugin configuration
- **No assumptions**: Sensible defaults for all optional settings

---

## Quick Start

### Minimal Setup (Required)

Only one environment variable is required:

```bash
export QUESTA_BIN_DIR="/path/to/questasim/bin"
```

### Running a Basic Simulation

**Single-Step Flow (Development):**
1. Open your project in Questa Developer
2. Select **QuestaSim Simulation (vsim)** from the plugin menu
3. The simulation runs with default settings (GUI mode, standard optimization)

**Two-Step Flow (Production):**
1. Open your project in Questa Developer
2. Select **QuestaSim Simulation (vopt + vsim)** from the plugin menu
3. vopt elaborates/optimizes the design → vsim simulates the optimized design

---

## Configuration Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `QUESTA_BIN_DIR` | Path to QuestaSim bin directory | `/u/qa/buildsites/2025.x/builds/linux_x86_64/modeltech/linux_x86_64/` |

### Optional Variables

All variables below are **optional** and have sensible defaults. Set only what you need.

#### Simulation Control

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_SIM_MODE` | `gui` | `gui`, `batch`, `interactive` | Simulation execution mode |
| `QUESTA_SIM_ARCH` | `64` | `32`, `64` | Architecture (32 or 64-bit) |
| `QUESTA_SIM_TIME_RESOLUTION` | `1ps` | `1fs`, `1ps`, `1ns`, etc. | Time resolution |
| `QUESTA_RUN_TIME` | `run -all` | Any TCL command | Simulation run command |
| `QUESTA_AUTO_QUIT` | `1` | `0`, `1` | Auto quit in batch mode |

#### Coverage Collection

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_COVERAGE` | `0` | `0`, `1` | Enable coverage collection |
| `QUESTA_COVERAGE_OPTIONS` | `-coverage` | Coverage options | Coverage collection flags |
| `QUESTA_COVERAGE_DB` | `coverage.ucdb` | Filename | Coverage database name |

**Example: Enable Coverage**
```bash
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=my_test_coverage.ucdb
```

#### UVM Support

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_UVM` | `0` | `0`, `1` | Enable UVM support |
| `QUESTA_UVM_TESTNAME` | _(empty)_ | Test name | UVM test to run (+UVM_TESTNAME) |
| `QUESTA_UVM_VERBOSITY` | `UVM_MEDIUM` | `UVM_NONE`, `UVM_LOW`, `UVM_MEDIUM`, `UVM_HIGH`, `UVM_FULL` | UVM verbosity level |
| `QUESTA_UVM_CONFIG_DB` | _(empty)_ | Any value | Enable config DB trace |

**Example: Run UVM Test**
```bash
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=base_test
export QUESTA_UVM_VERBOSITY=UVM_HIGH
```

#### Waveform Capture

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_WAVEFORM` | `0` | `0`, `1` | Enable waveform capture |
| `QUESTA_WAVEFORM_FORMAT` | `wlf` | `wlf`, `vcd`, `fsdb` | Waveform file format |
| `QUESTA_WAVEFORM_FILE` | `vsim.wlf` | Filename | Waveform filename |
| `QUESTA_WAVEFORM_DB` | _(empty)_ | Options | Options for -qwavedb |

**Example: Capture Waveforms**
```bash
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FORMAT=wlf
export QUESTA_WAVEFORM_FILE=my_design.wlf
```

**Note**: FSDB format requires `VERDI_HOME` to be set.

#### Debug and Optimization

**For Single-Step Flow (vsim):**

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_DEBUG` | `0` | `0`, `1` | Enable debug mode |
| `QUESTA_DEBUG_LEVEL` | `+acc` | `+acc`, `+acc=npr`, etc. | Debug access level |
| `QUESTA_ENABLE_VOPT` | `0` | `0`, `1` | Enable vopt optimization |
| `QUESTA_VOPT_OPTIONS` | `-O5` | Optimization flags | Vopt optimization options |

**Example: Debug Mode**
```bash
export QUESTA_ENABLE_DEBUG=1
export QUESTA_DEBUG_LEVEL="+acc=npr"
```

**Example: Optimized Run**
```bash
export QUESTA_ENABLE_VOPT=1
export QUESTA_VOPT_OPTIONS="-O5"
```

**For Two-Step Flow (vopt + vsim):**

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_VOPT_OPTIMIZE_LEVEL` | `-O5` | `-O0` to `-O5` | Optimization level (vopt stage) |
| `QUESTA_VOPT_ACCESS` | `+acc` | `+acc`, `+acc=npr`, `+acc=r` | Debug visibility (vopt stage) |
| `QUESTA_VOPT_DEBUG` | `0` | `0`, `1` | Enable debug mode (vopt stage) |
| `QUESTA_VOPT_EXTRA_ARGS` | `""` | Any vopt args | Additional vopt arguments |
| `QUESTA_VOPT_LOG_FILE` | `vopt.log` | Filename | vopt log file |
| `QUESTA_VSIM_LOG_FILE` | `simulation.log` | Filename | vsim log file |

**Example: Full Debug (Two-Step)**
```bash
export QUESTA_VOPT_ACCESS="+acc"          # Full visibility
export QUESTA_VOPT_DEBUG=1                # Debug mode
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O0     # No optimization
```

**Example: Optimized Regression (Two-Step)**
```bash
export QUESTA_VOPT_OPTIMIZE_LEVEL=-O5     # Maximum optimization
export QUESTA_VOPT_ACCESS="+acc=r"        # Minimal visibility (faster)
export QUESTA_SIM_MODE=batch
```

#### VIP/PLI Support

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_VIP_ENABLE` | `0` | `0`, `1` | Enable VIP/PLI support |
| `QUESTA_VIP_PLI_LIB` | _(empty)_ | Path to .so file | VIP PLI library path |
| `AVERY_PLI` | _(empty)_ | Directory path | Avery VIP PLI installation |

**Example: VIP Simulation**
```bash
export AVERY_PLI=/u/release/avery/2025.2/vip/avery_pli-2025.2
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
```

#### Assertions and FSM

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_ASSERTIONS` | `1` | `0`, `1` | Enable assertion debugging |
| `QUESTA_ASSERTION_OPTIONS` | _(empty)_ | Options | Additional assertion flags |
| `QUESTA_ENABLE_FSM_DEBUG` | `0` | `0`, `1` | Enable FSM debugging |

#### Power Analysis

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_POWER` | `0` | `0`, `1` | Enable power analysis |
| `QUESTA_POWER_OPTIONS` | _(empty)_ | Options | Power analysis options |

#### Visualizer Mode

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_ENABLE_VISUALIZER` | `0` | `0`, `1` | Enable Visualizer mode |
| `QUESTA_VISUALIZER_OPTIONS` | _(empty)_ | Options | Visualizer options |

#### Logging and Transcripts

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_TRANSCRIPT_FILE` | `transcript` | Filename | Transcript filename |
| `QUESTA_LOG_FILE` | `simulation.log` | Filename | Log file name |

#### Custom Scripts and Arguments

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `QUESTA_CUSTOM_DO_FILE` | _(empty)_ | Path to .do file | Custom DO script (overrides template) |
| `QUESTA_CUSTOM_PLUSARGS` | _(empty)_ | Plusargs | Custom +args (e.g., +seed=123) |
| `QUESTA_CUSTOM_DEFINES` | _(empty)_ | Defines | Custom defines (-DDEBUG) |

#### External Tools

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `VERDI_HOME` | _(empty)_ | Directory path | Verdi installation (for FSDB) |

---

## Usage Examples

### Example 1: Basic GUI Simulation

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
# Run simulation (GUI mode by default)
```

### Example 2: Batch Simulation with Coverage

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=regression_coverage.ucdb
export QUESTA_AUTO_QUIT=1
```

### Example 3: UVM Testbench with Waveforms

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=sanity_test
export QUESTA_UVM_VERBOSITY=UVM_HIGH
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_WAVEFORM_FILE=uvm_test.wlf
```

### Example 4: VIP Integration

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export AVERY_PLI=/u/release/avery/2025.2/vip/avery_pli-2025.2
export QUESTA_VIP_ENABLE=1
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
export QUESTA_ENABLE_UVM=1
export QUESTA_UVM_TESTNAME=ahb_master_test
```

### Example 5: Debug Session

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_SIM_MODE=gui
export QUESTA_ENABLE_DEBUG=1
export QUESTA_DEBUG_LEVEL="+acc=npr"
export QUESTA_ENABLE_WAVEFORM=1
export QUESTA_ENABLE_FSM_DEBUG=1
```

### Example 6: Regression (Optimized Batch)

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_ENABLE_VOPT=1
export QUESTA_VOPT_OPTIONS="-O5"
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_AUTO_QUIT=1
export QUESTA_RUN_TIME="run 10ms"
```

### Example 7: Power Analysis

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_ENABLE_POWER=1
export QUESTA_POWER_OPTIONS="-power_report=power.rpt"
export QUESTA_ENABLE_WAVEFORM=1
```

### Example 8: Custom Plusargs and Seeds

```bash
export QUESTA_BIN_DIR=/u/release/questa/2025.2/questasim/bin
export QUESTA_SIM_MODE=batch
export QUESTA_CUSTOM_PLUSARGS="+seed=42 +VERBOSE +TEST_MODE=1"
export QUESTA_CUSTOM_DEFINES="-DDEBUG -DUSE_CHECKER"
```

---

## Feature Interaction Matrix

| Feature | Compatible With | Notes |
|---------|----------------|-------|
| Coverage | UVM, VIP, Waveform | All work together |
| Debug Mode | Waveform, FSM Debug, Assertions | Recommended for debug sessions |
| Optimization (vopt) | Coverage, Batch mode | Speeds up regression runs |
| UVM | Coverage, Waveform, VIP | Full UVM support |
| VIP | UVM, Coverage | Requires AVERY_PLI |
| Visualizer | Debug, Waveform, UVM | **Incompatible with batch mode** (auto-switches to GUI) |
| FSDB Waveform | Debug, UVM | Requires VERDI_HOME |
| Batch Mode | Coverage, Vopt, UVM | **Incompatible with Visualizer** (Visualizer forces GUI) |

### Important Compatibility Notes

**Visualizer + Batch Mode Conflict:**
- Visualizer mode requires GUI and is incompatible with batch mode
- If both `QUESTA_ENABLE_VISUALIZER=1` and `QUESTA_SIM_MODE=batch` are set, the plugin automatically switches to GUI mode
- Warning message: "Visualizer mode is incompatible with batch mode - Changing mode from 'batch' to 'gui'"

---

## Troubleshooting

### Issue: "QUESTA_BIN_DIR not set"
**Solution**: Export the required variable:
```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
```

### Issue: "vsim not found"
**Solution**: Verify the path is correct and vsim is executable:
```bash
ls -l $QUESTA_BIN_DIR/vsim
```

### Issue: VIP library not loading
**Solution**: Verify AVERY_PLI and library path:
```bash
export AVERY_PLI=/correct/path
export QUESTA_VIP_PLI_LIB="${AVERY_PLI}/linux_x86_64/lib/libtb_ms.so"
ls -l $QUESTA_VIP_PLI_LIB
```

### Issue: FSDB waveforms not working
**Solution**: Set VERDI_HOME:
```bash
export VERDI_HOME=/path/to/verdi
```

### Issue: Coverage database not created
**Solution**: Ensure directory permissions and coverage is enabled:
```bash
export QUESTA_ENABLE_COVERAGE=1
chmod 755 $(pwd)
```

---

## Advanced Topics

### Using Custom DO Files

Override the default DO file:
```bash
export QUESTA_CUSTOM_DO_FILE=/path/to/my_script.do
```

### Running Multiple Tests

Create a wrapper script:
```bash
#!/bin/bash
for test in test1 test2 test3; do
    export QUESTA_UVM_TESTNAME=$test
    export QUESTA_COVERAGE_DB="${test}_coverage.ucdb"
    # Run simulation via plugin
done
```

### Integration with CI/CD

```bash
#!/bin/bash
# CI/CD friendly configuration
export QUESTA_BIN_DIR=/tools/questa/bin
export QUESTA_SIM_MODE=batch
export QUESTA_AUTO_QUIT=1
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_COVERAGE_DB=${BUILD_ID}_coverage.ucdb
export QUESTA_LOG_FILE=${BUILD_ID}_simulation.log
```

---

## Architecture

The plugin uses a template-based architecture with **two available templates**:

### Single-Step Flow
1. **config.json**: Defines "QuestaSim Simulation (vsim)" command
2. **template_questasim_script.sh**: Bash template for vsim-only flow
3. **Generated script**: `questasim_script.sh` in project directory
4. **Execution**: vsim with implicit vopt in background

### Two-Step Flow
1. **config.json**: Defines "QuestaSim Simulation (vopt + vsim)" command
2. **template_vopt_vsim_script.sh**: Bash template for vopt + vsim flow
3. **Generated script**: `questasim_vopt_vsim_script.sh` in project directory
4. **Execution**: Explicit vopt (elaborate/optimize) → vsim (simulate)

Both templates:
- Replace template variables with project data (e.g., `{{TOP_UNITS}}`)
- Read environment variables for feature configuration
- Support all optional features identically

### Template Variables (Supplied by Questa Developer)

| Variable | Description | Example |
|----------|-------------|---------|
| `{{RUN_DIR}}` | Simulation run directory | `/path/to/project/run` |
| `{{DEVELOPER_VERSION}}` | Questa Developer version | `2025.1` |
| `{{MODELSIM_PATH}}` | Path to modelsim.ini | `/path/to/modelsim.ini` |
| `{{TOP_UNITS}}` | Top-level design units | List with NAME, LIBRARY_NAME, FILE_URI |
| `{{LIBRARIES}}` | Compiled libraries | List of library names |
| `{{DO_FILE_PATH}}` | Template DO file path | `/path/to/default.do` |
| `{{ADDITIONAL_ARGS}}` | Extra arguments | User-specified flags |

---

## Flow Comparison Summary

### Choose Your Flow

| Factor | Single-Step (vsim) | Two-Step (vopt + vsim) |
|--------|-------------------|------------------------|
| **Use Case** | Development | Production |
| **Complexity** | Simple | Moderate |
| **Control** | Limited | Full |
| **Performance (single run)** | Fast | Slightly slower |
| **Performance (multiple runs)** | Slow | Fast |
| **Debugging** | Good | Excellent |
| **Official Recommendation** | No | Yes |
| **Best For** | Daily coding | Regression, Coverage, CI/CD |

### Quick Decision

- **Use Single-Step if:** You're developing/debugging RTL and want fast iteration
- **Use Two-Step if:** You need production-grade workflows, coverage, or CI/CD

📖 **Detailed guidance:** [FLOW_SELECTION_GUIDE.md](FLOW_SELECTION_GUIDE.md)  
📖 **Two-step documentation:** [TWO_STEP_FLOW.md](TWO_STEP_FLOW.md)

---

## Version History

### Version 2.1 (Current)
- **NEW**: Two-step flow (vopt + vsim) for production workflows
- Explicit elaboration/optimization control
- Separate logs for vopt and vsim stages
- Optimized design reuse for multiple simulations
- Official Siemens three-step flow support (compile → vopt → vsim)
- All configuration compatible with both flows

### Version 2.0
- Complete rewrite with comprehensive feature support
- All advanced features are optional and configurable
- Enhanced error handling and logging
- Color-coded console output
- Detailed configuration documentation
- Support for: Coverage, UVM, Waveforms, VIP, Debug, Optimization, Assertions, FSM, Power, Visualizer

### Version 1.0
- Basic vsim execution
- Minimal configuration

---

## Contributing

To add new optional features:

1. Add environment variable check in the script
2. Document in config.json `environmentVariables` section
3. Update this README with usage examples
4. Ensure feature works without the variable set (use defaults)

---

## Support

For issues or questions:
- Check Questa Developer documentation
- Review QuestaSim command reference
- Verify environment variable values
- Check simulation log file (`QUESTA_LOG_FILE`)

---

## License

This plugin is part of the Questa Developer integration framework.

---

**Note**: This plugin is designed to work without any optional configuration. All advanced features are opt-in and do not affect the basic simulation flow if not configured.
