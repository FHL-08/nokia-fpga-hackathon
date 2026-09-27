# Two-Step Flow Implementation Summary

## What Was Implemented

This document summarizes the implementation of the **two-step vopt + vsim simulation flow** for the QuestaSim plugin.

---

## Implementation Date

**Date:** January 2025  
**Version:** 2.1  
**Based on:** Siemens Questa SIM User's Manual 2024.3-2025.3

---

## Motivation

User requested a two-step flow following official Siemens Questa documentation:

> "Could you make it two steps vopt and then vsim base to the fuse server to get the documentation as the compilation is already done and provided through modelsim.ini"

**Key Requirements:**
1. Separate elaboration (vopt) from simulation (vsim)
2. Follow official Siemens three-step flow: compile → vopt → vsim
3. Support all existing features (coverage, UVM, waveform, VIP, etc.)
4. Maintain compatibility with existing environment variables
5. Query FUSE documentation server for official best practices

---

## Official Documentation Consulted

### FUSE Server Queries

**Query 1:** "vopt elaboration optimization command line options vsim optimized design -voptargs"

**Key Findings:**
- vopt requires `-o <name>` to create named optimized design
- Three-step flow is official recommendation
- Example: `vopt top -o mydesign` → `vsim mydesign`

**Query 2:** "vsim simulate optimized elaborated module vopt output _opt naming convention"

**Key Findings:**
- Optimized designs conventionally use `_opt` suffix
- Official examples: `test_ringbuf_opt`, `top_opt`, `tb_opt`
- vsim simulates the optimized design unit directly
- Visibility control via `+acc` or `-access` during vopt stage

### Official Examples from Documentation

```bash
# Example 1: Debug mode with full access
vopt +acc test_ringbuf -o test_ringbuf_opt
vsim test_ringbuf_opt

# Example 2: Optimized production
vopt -O5 +acc=r top -o top_opt
vsim top_opt

# Example 3: Coverage
vopt +cover=sbceft tb -o tb_opt
vsim -coverage tb_opt
```

---

## Implementation Details

### New Files Created

#### 1. `template_vopt_vsim_script.sh` (558 lines)

**Purpose:** Main execution script for two-step flow

**Key Features:**
- **Step 1 - vopt:** Elaborate and optimize compiled design
  - Flags: `-O5`, `+acc`, `+cover`, `-assertdebug`, `-fsmdebug`
  - Output: Named optimized design with `_opt` suffix
  - Log: `vopt.log`

- **Step 2 - vsim:** Simulate optimized design
  - Flags: `-batch`, `-gui`, `-visualizer`, waveform, UVM, DO file
  - Input: Optimized design from vopt
  - Log: `simulation.log`

**Architecture:**
```bash
# Step 1: Elaborate/Optimize
vopt -64 \
  -modelsimini questa.ini \
  -O5 +acc +cover=sbceft \
  -L work -L support_lib \
  work.tb_ahb_subordinate \
  -o tb_ahb_subordinate_opt \
  -l vopt.log

# Step 2: Simulate
vsim -64 -batch \
  -modelsimini questa.ini \
  -coverage -coverstore coverage.ucdb \
  -L work -L support_lib \
  tb_ahb_subordinate_opt \
  -l simulation.log \
  -do "run -all; quit -f"
```

**Naming Convention:**
- Input design: `tb_ahb_subordinate`
- Optimized design: `tb_ahb_subordinate_opt` (automatic `_opt` suffix)
- Follows official Siemens examples

#### 2. `TWO_STEP_FLOW.md` (500+ lines)

**Purpose:** Comprehensive documentation for two-step flow

**Contents:**
- Overview and benefits
- Architecture diagrams
- Configuration reference (vopt-specific and vsim-specific variables)
- Usage examples (9 detailed scenarios)
- Command-line examples
- Logs and outputs
- Comparison with single-step flow
- Troubleshooting guide
- Best practices
- References to official documentation

**Key Sections:**
- Why Two-Step Flow?
- Design flow diagram
- Naming conventions
- Configuration tables
- Real-world examples
- Performance comparison

#### 3. `FLOW_SELECTION_GUIDE.md` (350+ lines)

**Purpose:** Help users choose between single-step and two-step flows

**Contents:**
- Quick decision matrix
- Detailed comparison
- Technical differences
- 7 use case examples:
  1. Daily development
  2. Nightly regression
  3. Coverage analysis
  4. UVM debug session
  5. CI/CD pipeline
  6. VIP simulation
  7. Performance optimization

**Key Sections:**
- Use case recommendations by role (Designer, Verification Engineer, DV Lead, DevOps, Manager)
- Migration path from single-step to two-step
- Environment variable compatibility
- Summary tables

#### 4. Updated `config.json`

**Changes:**
- Added second command: "QuestaSim Simulation (vopt + vsim)"
- Template: `template_vopt_vsim_script.sh`
- Output script: `questasim_vopt_vsim_script.sh`
- Description: "Two-step simulation: explicit vopt elaboration/optimization followed by vsim simulation (recommended for production)"

**Command Structure:**
```json
{
  "commandName": "QuestaSim Simulation (vopt + vsim)",
  "command": "bash",
  "arguments": "${PROJECT_DIR}/questasim_vopt_vsim_script.sh",
  "compilationOrderFileTemplate": ".../template_vopt_vsim_script.sh",
  "compilationOrderFilePath": "${PROJECT_DIR}/questasim_vopt_vsim_script.sh",
  "workingDirectory": "",
  "description": "Two-step simulation: explicit vopt elaboration/optimization followed by vsim simulation (recommended for production)"
}
```

#### 5. Updated `README.md`

**Changes:**
- Added "Available Simulation Flows" section at top
- Links to TWO_STEP_FLOW.md and FLOW_SELECTION_GUIDE.md
- Split "Debug and Optimization" section into:
  - Single-Step Flow variables
  - Two-Step Flow variables (vopt-specific)
- Added vopt configuration table
- Added flow comparison summary table
- Updated version history to 2.1
- Updated architecture section to describe both templates

---

## Environment Variables

### New Variables for Two-Step Flow

All variables are **optional** with sensible defaults.

#### vopt Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `QUESTA_VOPT_OPTIMIZE_LEVEL` | `-O5` | Optimization level (-O0 to -O5) |
| `QUESTA_VOPT_ACCESS` | `+acc` | Debug visibility (e.g., `+acc`, `+acc=npr`, `+acc=r`) |
| `QUESTA_VOPT_DEBUG` | `0` | Enable debug mode (1=yes, 0=no) |
| `QUESTA_VOPT_EXTRA_ARGS` | `""` | Additional vopt arguments |
| `QUESTA_VOPT_LOG_FILE` | `vopt.log` | vopt log filename |
| `QUESTA_VSIM_LOG_FILE` | `simulation.log` | vsim log filename |

### Compatibility

**100% compatible** with existing environment variables:
- Coverage: `QUESTA_ENABLE_COVERAGE`, `QUESTA_COVERAGE_OPTIONS`, `QUESTA_COVERAGE_DB`
- UVM: `QUESTA_ENABLE_UVM`, `QUESTA_UVM_TESTNAME`, `QUESTA_UVM_VERBOSITY`
- Waveform: `QUESTA_ENABLE_WAVEFORM`, `QUESTA_WAVEFORM_FORMAT`, `QUESTA_WAVEFORM_FILE`
- VIP: `QUESTA_VIP_ENABLE`, `QUESTA_VIP_PLI_LIB`
- Simulation: `QUESTA_SIM_MODE`, `QUESTA_SIM_ARCH`, `QUESTA_AUTO_QUIT`, `QUESTA_RUN_TIME`

Users can switch between flows **without changing configuration**.

---

## Flag Distribution Strategy

### vopt Flags (Elaboration/Optimization Stage)

**Purpose:** Control design elaboration, optimization, and instrumentation

**Flags:**
- Architecture: `-64` or `-32`
- INI file: `-modelsimini questa.ini`
- Optimization: `-O5` (or `-O0` for debug)
- Visibility: `+acc` (full) or `+acc=r` (read-only) or `+acc=npr` (selective)
- Coverage: `+cover=sbceft` (instrument for coverage)
- Assertions: `-assertdebug`
- FSM: `-fsmdebug`
- Power: Power analysis options
- Libraries: `-L work -L lib1 -L lib2`
- Output: `-o <design>_opt`
- Log: `-l vopt.log`

**Example:**
```bash
vopt -64 -modelsimini questa.ini \
     -O5 +acc \
     +cover=sbceft \
     -assertdebug \
     -L work -L support_lib \
     work.tb_ahb_subordinate \
     -o tb_ahb_subordinate_opt \
     -l vopt.log
```

### vsim Flags (Simulation Stage)

**Purpose:** Control simulation execution, waveform capture, and runtime behavior

**Flags:**
- Architecture: `-64` or `-32`
- Mode: `-batch` or `-gui` or `-c` (interactive) or `-visualizer`
- INI file: `-modelsimini questa.ini`
- Time resolution: `-t 1ps`
- Coverage: `-coverage -coverstore coverage.ucdb`
- UVM: `+UVM_TESTNAME=test +UVM_VERBOSITY=UVM_HIGH`
- Waveform: `-wlf vsim.wlf` or `-vcd dump.vcd`
- VIP/PLI: `-pli libtb_ms.so`
- Assertions: `-assertdebug`
- Libraries: `-L work -L lib1 -L lib2`
- Design: `<design>_opt` (optimized from vopt)
- DO file: `-do "run -all; quit -f"`
- Log: `-l simulation.log`

**Example:**
```bash
vsim -64 -batch \
     -modelsimini questa.ini \
     -t 1ps \
     -coverage -coverstore coverage.ucdb \
     +UVM_TESTNAME=smoke_test \
     -wlf debug.wlf \
     -L work -L support_lib \
     tb_ahb_subordinate_opt \
     -l simulation.log \
     -do "run -all; quit -f"
```

---

## Design Decisions

### 1. Naming Convention

**Decision:** Append `_opt` suffix to optimized design name

**Rationale:**
- Follows official Siemens examples (`test_ringbuf_opt`, `top_opt`, `tb_opt`)
- Clear distinction between raw and optimized designs
- Industry standard convention

**Implementation:**
```bash
# Template variable (from Questa Developer)
{% for top in TOP_UNITS %}
  OPTIMIZED_DESIGN="{{top.NAME}}_opt"
{% endfor %}

# Example result
# Input: tb_ahb_subordinate
# Output: tb_ahb_subordinate_opt
```

### 2. Separate Logs

**Decision:** Create separate logs for vopt and vsim

**Rationale:**
- Easier debugging (elaboration vs. simulation errors)
- Better CI/CD integration (parse logs separately)
- Follows best practices

**Implementation:**
- vopt log: `QUESTA_VOPT_LOG_FILE` (default: `vopt.log`)
- vsim log: `QUESTA_VSIM_LOG_FILE` (default: `simulation.log`)
- Transcript: `QUESTA_TRANSCRIPT_FILE` (default: `transcript`)

### 3. Default Optimization

**Decision:** Default to `-O5` (maximum optimization)

**Rationale:**
- Production-grade performance
- Can be overridden with `QUESTA_VOPT_OPTIMIZE_LEVEL`
- Debug mode (`QUESTA_VOPT_DEBUG=1`) automatically uses `-O0`

### 4. Coverage Instrumentation

**Decision:** Coverage flags during vopt stage

**Rationale:**
- Coverage instrumentation happens at elaboration time
- vsim only needs `-coverage` flag to collect data
- Official Siemens recommendation

**Implementation:**
```bash
# vopt
if [ "$ENABLE_COVERAGE" = "1" ]; then
    VOPT_CMD="$VOPT_CMD $COVERAGE_OPTIONS"  # +cover=sbceft
fi

# vsim
if [ "$ENABLE_COVERAGE" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -coverage"
    VSIM_CMD="$VSIM_CMD -coverstore $COVERAGE_DB"
fi
```

### 5. Visualizer Compatibility

**Decision:** Visualizer mode only affects vsim stage

**Rationale:**
- vopt doesn't need Visualizer flags
- Visualizer is a simulation GUI feature
- Conflict resolution (Visualizer + Batch) already handled

**Implementation:**
```bash
# vopt: no Visualizer flags

# vsim
if [ "$ENABLE_VISUALIZER" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -visualizer $VISUALIZER_OPTIONS"
fi
```

---

## Testing and Validation

### FUSE Documentation Validation

✅ Queried FUSE server for official vopt/vsim documentation  
✅ Confirmed three-step flow (compile → vopt → vsim) is official recommendation  
✅ Verified `-o` argument requirement for vopt  
✅ Confirmed `_opt` naming convention from examples  
✅ Validated flag distribution (coverage in vopt, simulation in vsim)

### Implementation Validation

✅ Script syntax validated  
✅ Template variables correct  
✅ Environment variable defaults sensible  
✅ Conflict resolution preserved (Visualizer + Batch)  
✅ All existing features supported (coverage, UVM, waveform, VIP, etc.)  
✅ Documentation comprehensive and accurate  
✅ Backward compatible (existing single-step flow unchanged)

---

## Benefits of Two-Step Flow

### Performance

**Multiple Simulations:**
- Old: Elaborate N times (slow)
- New: Elaborate once, simulate N times (fast)

**Example:**
- 100 regression tests with seeds
- Single-step: 100 × (elaborate + simulate) = slow
- Two-step: 1 × elaborate + 100 × simulate = fast

### Control

**Optimization:**
- Explicit control over `-O` level
- Can optimize once with different simulation modes

**Visibility:**
- Control `+acc` independently from simulation
- Can have optimized design with selective visibility

### Debugging

**Separate Logs:**
- vopt.log: Elaboration/optimization errors
- simulation.log: Simulation runtime errors

**Easier Troubleshooting:**
- Elaboration errors isolated from simulation errors
- Better error messages

### Production Workflows

**CI/CD Integration:**
- Separate stages for elaboration and simulation
- Can cache optimized designs
- Better logging for automation

**Coverage Collection:**
- Explicit coverage instrumentation
- Clear separation of instrumentation (vopt) and collection (vsim)

---

## Comparison with Single-Step Flow

### Single-Step Flow (Existing)

**Pros:**
- Simpler (one command)
- Faster for single runs
- Good for development

**Cons:**
- Less control over optimization
- Can't reuse optimized design
- Harder to debug elaboration issues

**Use Cases:**
- Daily development
- Quick sanity checks
- Learning/exploration

### Two-Step Flow (New)

**Pros:**
- Full control over each stage
- Better performance for multiple runs
- Explicit coverage instrumentation
- Easier debugging
- Official recommendation

**Cons:**
- Slightly more complex
- Two stages instead of one

**Use Cases:**
- Production workflows
- Regression testing
- Coverage collection
- CI/CD integration
- Performance-critical simulations

---

## User Experience

### Zero-Configuration Baseline

Both flows work with **only one required variable**:

```bash
export QUESTA_BIN_DIR=/path/to/questasim/bin
# Run plugin → works!
```

### Easy Migration

**Switching flows requires zero configuration changes:**

```bash
# Same environment variables work for both flows
export QUESTA_BIN_DIR=/path/to/bin
export QUESTA_ENABLE_COVERAGE=1
export QUESTA_ENABLE_UVM=1

# Just change command in Questa Developer:
# - "QuestaSim Simulation (vsim)" → Single-step
# - "QuestaSim Simulation (vopt + vsim)" → Two-step
```

### Clear Documentation

- **README.md**: Overview, quick comparison
- **FLOW_SELECTION_GUIDE.md**: Detailed decision matrix, use cases
- **TWO_STEP_FLOW.md**: Deep dive into two-step flow
- **Quick references**: Tables, examples, best practices

---

## Future Enhancements

### Potential Additions

1. **Vopt Result Caching**: Cache optimized designs for reuse
2. **Parallel Simulation**: Run multiple vsim on same vopt output
3. **Coverage Merging**: Merge multiple UCDB files from parallel runs
4. **Advanced Vopt Options**: Fine-grained control over optimization
5. **Performance Profiling**: Time vopt and vsim separately

### User Feedback

Gather feedback on:
- Flow selection (which flow users prefer)
- Performance improvements
- Missing features
- Documentation clarity

---

## References

### Official Siemens Documentation

- **Questa SIM User's Manual** (2024.3-2025.3)
  - Chapter on three-step simulation flow
  - vopt command reference
  - vsim command reference
  - Coverage collection

### FUSE Server Queries

- Query 1: "vopt elaboration optimization command line options vsim optimized design -voptargs"
- Query 2: "vsim simulate optimized elaborated module vopt output _opt naming convention"

### Official Examples

```bash
vopt +acc test_ringbuf -o test_ringbuf_opt
vsim test_ringbuf_opt

vopt top -o mydesign
vsim mydesign

vopt tb -o tb_opt
vsim tb_opt
```

---

## Conclusion

The two-step flow implementation provides:

✅ **Official compliance** with Siemens Questa recommendations  
✅ **Full backward compatibility** with existing single-step flow  
✅ **Enhanced control** over elaboration and simulation stages  
✅ **Better performance** for regression testing  
✅ **Improved debugging** with separate logs  
✅ **Production-ready** workflows for CI/CD  
✅ **Comprehensive documentation** with clear guidance  
✅ **Zero-configuration baseline** maintained  
✅ **Flexible migration path** between flows  

The implementation follows official Siemens documentation, validated via FUSE server queries, and provides a professional-grade simulation environment for Questa Developer users.

---

**Implementation Status: ✅ Complete**

**Files Created:**
1. `template_vopt_vsim_script.sh` (558 lines)
2. `TWO_STEP_FLOW.md` (500+ lines)
3. `FLOW_SELECTION_GUIDE.md` (350+ lines)
4. Updated `config.json`
5. Updated `README.md`
6. `TWO_STEP_IMPLEMENTATION.md` (this document)

**Total Documentation:** 1500+ lines  
**Total Code:** 558 lines  
**Configuration Variables:** 40+ (all backward compatible)

---

**Happy Simulating with Two-Step Flow! 🚀**
