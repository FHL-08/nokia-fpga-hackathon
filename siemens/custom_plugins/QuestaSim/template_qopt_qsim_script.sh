#!/bin/bash
################################################################################
# QuestaSim Three-Step Flow: qopt + qsim
# Description: Separate elaboration/optimization and simulation steps
# Assumes compilation is already done (libraries in questa.ini)
################################################################################

# Self-Repair: Ensure this script is executable
if [ ! -x "$0" ] && [ -w "$0" ]; then
    chmod +x "$0" 2>/dev/null || true
fi

set -o pipefail

################################################################################
# Color output
################################################################################
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

################################################################################
# Setup working directory
# Use comp_out directory (where compiled libraries reside) so that
# relative library paths in questa.ini (e.g. work = ./work) resolve correctly.
################################################################################
RUN_DIR="$(dirname "{{MODELSIM_PATH}}")/comp_out"
if [ ! -d "$RUN_DIR" ]; then
    mkdir -p "$RUN_DIR" || { log_error "Failed to create $RUN_DIR"; exit 1; }
fi
cd "$RUN_DIR" || { log_error "Failed to cd to $RUN_DIR"; exit 1; }
log_info "Working directory: $(pwd)"

################################################################################
# Validate QuestaSim installation
################################################################################
QUESTA_BIN_DIR="${QUESTA_BIN_DIR:-}"
if [ -z "$QUESTA_BIN_DIR" ]; then
    log_error "QUESTA_BIN_DIR not set"
    exit 1
fi

QOPT_EXEC="${QUESTA_BIN_DIR}/qopt"
QSIM_EXEC="${QUESTA_BIN_DIR}/qsim"

if [ ! -x "$QOPT_EXEC" ]; then
    log_error "qopt not found: $QOPT_EXEC"
    exit 1
fi

if [ ! -x "$QSIM_EXEC" ]; then
    log_error "qsim not found: $QSIM_EXEC"
    exit 1
fi

export PATH="${QUESTA_BIN_DIR}:${PATH}"

################################################################################
# Version check
################################################################################
QUESTASIM_VERSION=$("${QSIM_EXEC}" -version 2>/dev/null | head -1)
log_info "QuestaSim Version: $QUESTASIM_VERSION"

################################################################################
# Configuration
################################################################################
QUESTA_INI_PATH="{{MODELSIM_PATH}}"
QUESTA_INI_PATH="${QUESTA_INI_PATH%/*}/questa.ini"

# Flow control - detect which flow to use
QUESTA_FLOW_MODE="${QUESTA_FLOW_MODE:-auto}"  # auto, single-step, two-step
QUESTA_ENABLE_TWO_STEP="${QUESTA_ENABLE_TWO_STEP:-1}"  # 1=two-step (default), 0=single-step

# Simulation settings
SIM_MODE="${QUESTA_SIM_MODE:-batch}"
SIM_ARCH="${QUESTA_SIM_ARCH:-64}"
SIM_TIME_RESOLUTION="${QUESTA_SIM_TIME_RESOLUTION:-1ps}"

# Qopt settings (two-step flow)
QOPT_ACCESS="-access=rw+/."
QOPT_DEBUG=""
QOPT_EXTRA_ARGS="${QUESTA_QOPT_EXTRA_ARGS:-}"

# Coverage
ENABLE_COVERAGE="${QUESTA_ENABLE_COVERAGE:-0}"
COVERAGE_OPTIONS="${QUESTA_COVERAGE_OPTIONS:-+cover=sbceft}"
COVERAGE_DB="${QUESTA_COVERAGE_DB:-coverage.ucdb}"  # Default UCDB filename
TESTNAME="${QUESTA_TESTNAME:-test_coverage}"  # Default testname for single UCDB generation

# UVM
ENABLE_UVM="${QUESTA_ENABLE_UVM:-0}"
UVM_TESTNAME="${QUESTA_UVM_TESTNAME:-}"
UVM_VERBOSITY="${QUESTA_UVM_VERBOSITY:-UVM_MEDIUM}"

# Waveform
ENABLE_WAVEFORM="${QUESTA_ENABLE_WAVEFORM:-0}"
WAVEFORM_FORMAT="${QUESTA_WAVEFORM_FORMAT:-qwave}"
WAVEFORM_FILE="${QUESTA_WAVEFORM_FILE:-qsim.wlf}"

# VIP
VIP_ENABLE="${QUESTA_VIP_ENABLE:-0}"
VIP_PLI_LIB="${QUESTA_VIP_PLI_LIB:-}"

# Assertions
ENABLE_ASSERTIONS="${QUESTA_ENABLE_ASSERTIONS:-1}"

# FSM
ENABLE_FSM_DEBUG="${QUESTA_ENABLE_FSM_DEBUG:-0}"

# Power
ENABLE_POWER="${QUESTA_ENABLE_POWER:-0}"
POWER_OPTIONS="${QUESTA_POWER_OPTIONS:-}"

# Visualizer
ENABLE_VISUALIZER="${QUESTA_ENABLE_VISUALIZER:-0}"
VISUALIZER_OPTIONS="${QUESTA_VISUALIZER_OPTIONS:-}"

# Logs
TRANSCRIPT_FILE="${QUESTA_TRANSCRIPT_FILE:-transcript}"
QOPT_LOG_FILE="${QUESTA_QOPT_LOG_FILE:-qopt.log}"
QSIM_LOG_FILE="${QUESTA_QSIM_LOG_FILE:-simulation.log}"

# Custom
CUSTOM_DO_FILE="${QUESTA_CUSTOM_DO_FILE:-}"
CUSTOM_PLUSARGS="${QUESTA_CUSTOM_PLUSARGS:-}"
CUSTOM_DEFINES="${QUESTA_CUSTOM_DEFINES:-}"

# Runtime
RUN_TIME="${QUESTA_RUN_TIME:-run -all}"
AUTO_QUIT="${QUESTA_AUTO_QUIT:-1}"

################################################################################
# Conflict resolution
################################################################################
if [ "$ENABLE_VISUALIZER" = "1" ] && [ "$SIM_MODE" = "batch" ]; then
    log_warning "Visualizer incompatible with batch mode - switching to gui"
    SIM_MODE="gui"
fi

# Enable visualizer by default when GUI mode is selected
if [ "$SIM_MODE" = "gui" ] && [ -z "${QUESTA_ENABLE_VISUALIZER+x}" ]; then
    ENABLE_VISUALIZER="1"
    log_info "GUI mode detected - enabling visualizer by default"
fi

# Enable debug mode when visualizer is enabled (required for visualizer)
if [ "$ENABLE_VISUALIZER" = "1" ] && [ "$QOPT_DEBUG" = "0" ]; then
    QOPT_DEBUG="1"
    log_info "Visualizer enabled - enabling debug mode for qopt"
fi

################################################################################
# Flow detection and validation
################################################################################
# Auto-detect flow mode if set to 'auto'
if [ "$QUESTA_FLOW_MODE" = "auto" ]; then
    if [ "$QUESTA_ENABLE_TWO_STEP" = "1" ]; then
        QUESTA_FLOW_MODE="two-step"
    else
        QUESTA_FLOW_MODE="single-step"
    fi
fi

# Validate flow mode
case "$QUESTA_FLOW_MODE" in
    single-step|two-step)
        # Valid modes
        ;;
    *)
        log_error "Invalid QUESTA_FLOW_MODE: $QUESTA_FLOW_MODE (valid: single-step, two-step, auto)"
        exit 1
        ;;
esac

################################################################################
# Print configuration
################################################################################
log_info "=========================================="
log_info "QuestaSim Configuration"
log_info "=========================================="
log_info "Flow: $QUESTA_FLOW_MODE"
log_info "Mode: $SIM_MODE"
log_info "Architecture: ${SIM_ARCH}-bit"
log_info "Time Resolution: $SIM_TIME_RESOLUTION"
log_info "INI File: $QUESTA_INI_PATH"
log_info "Top Units: {% for top in TOP_UNITS %}{{top.LIBRARY_NAME}}.{{top.NAME}}  {% endfor %}" 
log_info "Libraries: {% for lib in LIBRARIES %}{{ lib }} {% endfor %}"
if [ "$ENABLE_COVERAGE" = "1" ]; then
    if [ -n "$TESTNAME" ]; then
        log_info "Coverage: Enabled (testname: $TESTNAME)"
    else
        log_info "Coverage: Enabled (coverstore: $COVERAGE_DB)"
    fi
fi
[ "$ENABLE_UVM" = "1" ] && log_info "UVM: Enabled (Test: $UVM_TESTNAME)"
[ "$ENABLE_WAVEFORM" = "1" ] && log_info "Waveform: Enabled ($WAVEFORM_FORMAT)"
[ "$VIP_ENABLE" = "1" ] && log_info "VIP: Enabled"
[ "$ENABLE_VISUALIZER" = "1" ] && log_info "Visualizer: Enabled"
log_info "=========================================="

################################################################################
# Execute based on flow mode
################################################################################
if [ "$QUESTA_FLOW_MODE" = "single-step" ]; then
    log_info "Using single-step flow (qsim with implicit qopt)"
    # Skip to qsim execution with -qoptargs
    SKIP_QOPT=1
else
    log_info "Using two-step flow (explicit qopt + qsim)"
    SKIP_QOPT=0
fi

################################################################################
# STEP 1: Run qopt (Elaboration/Optimization)
################################################################################
if [ "$SKIP_QOPT" = "0" ]; then
log_step "STEP 1/2: Running qopt (elaboration/optimization)"

# Check and fix work library mapping
if [ -f "$QUESTA_INI_PATH" ]; then
    if ! grep -q "^work[[:space:]]*=" "$QUESTA_INI_PATH" 2>/dev/null; then
        log_warning "No 'work' library found in questa.ini"
        
        # Find the first user library mapping to use as reference
        FIRST_LIB=$(grep "^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=" "$QUESTA_INI_PATH" | grep -v "^others" | head -1)
        
        if [ -n "$FIRST_LIB" ]; then
            # Extract library path
            LIB_PATH=$(echo "$FIRST_LIB" | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Get the directory where libraries are stored
            LIB_DIR=$(dirname "$LIB_PATH")
            WORK_LIB_PATH="${LIB_DIR}/work"
            
            log_info "Creating work library at: $WORK_LIB_PATH"
            
            # Create work library using vlib (if it doesn't exist)
            if [ ! -d "$WORK_LIB_PATH" ]; then
                "${QUESTA_BIN_DIR}/vlib" "$WORK_LIB_PATH" 2>&1 | grep -v "Warning" || true
                if [ -d "$WORK_LIB_PATH" ]; then
                    log_success "Work library created successfully"
                else
                    log_error "Failed to create work library"
                    exit 1
                fi
            else
                log_info "Work library directory already exists"
            fi
            
            # Map work library using vmap with -ini flag
            cd "$(dirname "$QUESTA_INI_PATH")" || exit 1
            VMAP_OUTPUT=$("${QUESTA_BIN_DIR}/vmap" -ini "$QUESTA_INI_PATH" work "$WORK_LIB_PATH" 2>&1)
            if echo "$VMAP_OUTPUT" | grep -q "Modifying\|Mapping"; then
                log_success "Work library mapped successfully"
            elif grep -q "^work[[:space:]]*=" "$QUESTA_INI_PATH" 2>/dev/null; then
                log_info "Work library already mapped in questa.ini"
            else
                log_error "Failed to map work library"
                echo "$VMAP_OUTPUT"
                exit 1
            fi
            cd "$RUN_DIR" || exit 1
        else
            log_error "No library mappings found in questa.ini"
            log_error "Please add at least one library mapping to questa.ini"
            exit 1
        fi
    fi
fi

# Build qopt command
QOPT_CMD="${QOPT_EXEC}"

# Architecture
[ "$SIM_ARCH" = "64" ] && QOPT_CMD="$QOPT_CMD -64"
[ "$SIM_ARCH" = "32" ] && QOPT_CMD="$QOPT_CMD -32"

# INI file
if [ -f "$QUESTA_INI_PATH" ]; then
    QOPT_CMD="$QOPT_CMD -ini \"$QUESTA_INI_PATH\""
fi

# Optimization level and debug
if [ "$QOPT_DEBUG" = "1" ]; then
    QOPT_CMD="$QOPT_CMD -debug $QOPT_ACCESS"
else
    QOPT_CMD="$QOPT_CMD"
fi

# Coverage
if [ "$ENABLE_COVERAGE" = "1" ]; then
    QOPT_CMD="$QOPT_CMD $COVERAGE_OPTIONS"
fi

# Assertions
if [ "$ENABLE_ASSERTIONS" = "1" ]; then
    QOPT_CMD="$QOPT_CMD -debug,assert"
fi

# FSM
if [ "$ENABLE_FSM_DEBUG" = "1" ]; then
    QOPT_CMD="$QOPT_CMD +cover=f -fsmdebug"
fi

# Power
if [ "$ENABLE_POWER" = "1" ] && [ -n "$POWER_OPTIONS" ]; then
    QOPT_CMD="$QOPT_CMD $POWER_OPTIONS"
fi

# Custom args
if [ -n "$QOPT_EXTRA_ARGS" ]; then
    QOPT_CMD="$QOPT_CMD $QOPT_EXTRA_ARGS"
fi

# Visualizer design database file
if [ "$ENABLE_VISUALIZER" = "1" ]; then
    QOPT_CMD="$QOPT_CMD +designfile"
    log_info "Visualizer enabled - adding +designfile to generate design.bin"
fi

# Library paths
{% for lib in LIBRARIES %}
QOPT_CMD="$QOPT_CMD -L {{ lib }}"
{% endfor %}

# Top-level units (input to qopt)
{% for top in TOP_UNITS %}
QOPT_CMD="$QOPT_CMD {{top.LIBRARY_NAME}}.{{top.NAME}} "
{% endfor %}

# Output optimized design name
# Convention: work.<top>_opt
OPTIMIZED_DESIGN="{% for top in TOP_UNITS %}{{top.NAME}}_opt{% endfor %}"
QOPT_CMD="$QOPT_CMD  -o $OPTIMIZED_DESIGN"

# Logging
QOPT_CMD="$QOPT_CMD -l $QOPT_LOG_FILE"

log_info "qopt command: $QOPT_CMD"
log_info "Optimized design name: $OPTIMIZED_DESIGN"

START_QOPT=$(date +%s)
eval "$QOPT_CMD"
QOPT_EXIT=$?
END_QOPT=$(date +%s)
QOPT_ELAPSED=$((END_QOPT - START_QOPT))

if [ $QOPT_EXIT -ne 0 ]; then
    log_error "qopt failed with exit code $QOPT_EXIT"
    log_error "Check log: $QOPT_LOG_FILE"
    exit $QOPT_EXIT
fi

log_success "qopt completed successfully (${QOPT_ELAPSED}s)"

else
    log_info "Skipping explicit qopt step (single-step flow)"
    QOPT_EXIT=0
    QOPT_ELAPSED=0
fi

################################################################################
# STEP 2: Run qsim (Simulation)
################################################################################
if [ "$SKIP_QOPT" = "0" ]; then
    log_step "STEP 2/2: Running qsim (simulation)"
else
    log_step "Running qsim (single-step with implicit qopt)"
fi

# Build qsim command
QSIM_CMD="${QSIM_EXEC}"

# Architecture
[ "$SIM_ARCH" = "64" ] && QSIM_CMD="$QSIM_CMD -64"
[ "$SIM_ARCH" = "32" ] && QSIM_CMD="$QSIM_CMD -32"

# Simulation mode (Visualizer overrides)
if [ "$ENABLE_VISUALIZER" = "1" ]; then
    QSIM_CMD="$QSIM_CMD -visualizer $VISUALIZER_OPTIONS"
else
    case "$SIM_MODE" in
        batch) QSIM_CMD="$QSIM_CMD -batch -quiet" ;;
        interactive) QSIM_CMD="$QSIM_CMD -c" ;;
        gui)  QSIM_CMD="$QSIM_CMD -gui" ;; # Default, no flags
    esac
fi

# Time resolution
QSIM_CMD="$QSIM_CMD -t $SIM_TIME_RESOLUTION"

# INI file
if [ -f "$QUESTA_INI_PATH" ]; then
    QSIM_CMD="$QSIM_CMD -ini \"$QUESTA_INI_PATH\""
fi

# Suppress warnings
QSIM_CMD="$QSIM_CMD +nowarnTSCALE +nowarnTFMPC"

# Coverage
if [ "$ENABLE_COVERAGE" = "1" ]; then
    QSIM_CMD="$QSIM_CMD -coverage"
    if [ -n "$TESTNAME" ]; then
        # Use -testname to generate single UCDB file
        # Note: Coverage must be saved manually in UVM final_phase since $finish bypasses DO commands
        QSIM_CMD="$QSIM_CMD -testname $TESTNAME"
    else
        # Use -coverstore for regression with multiple tests
        QSIM_CMD="$QSIM_CMD -coverstore $COVERAGE_DB"
    fi
fi

# UVM
if [ "$ENABLE_UVM" = "1" ]; then
    if [ -n "$UVM_TESTNAME" ]; then
        QSIM_CMD="$QSIM_CMD +UVM_TESTNAME=$UVM_TESTNAME"
    fi
    QSIM_CMD="$QSIM_CMD +UVM_VERBOSITY=$UVM_VERBOSITY"
    
    # UVM-aware coverage integration
    if [ "$ENABLE_COVERAGE" = "1" ] && [ -n "$UVM_TESTNAME" ] && [ -z "$TESTNAME" ]; then
        QSIM_CMD="$QSIM_CMD -uvmtestname"
    fi
fi

# Waveform
if [ "$ENABLE_WAVEFORM" = "1" ]; then
    case "$WAVEFORM_FORMAT" in
        qwave) QSIM_CMD="$QSIM_CMD -qwavedb=+signal+memory=all" ;;
        vcd) QSIM_CMD="$QSIM_CMD -vcd $WAVEFORM_FILE" ;;
        fsdb)
            if [ -n "$VERDI_HOME" ]; then
                QSIM_CMD="$QSIM_CMD -fsdb $WAVEFORM_FILE"
            else
                log_warning "FSDB requires VERDI_HOME - falling back to qwave"
                QSIM_CMD="$QSIM_CMD -qwavedb=+signal+memory=all"
            fi
            ;;
    esac
fi

# VIP/PLI
if [ "$VIP_ENABLE" = "1" ] && [ -n "$VIP_PLI_LIB" ] && [ -f "$VIP_PLI_LIB" ]; then
    QSIM_CMD="$QSIM_CMD -pli \"$VIP_PLI_LIB\""
fi

# Assertions
if [ "$ENABLE_ASSERTIONS" = "1" ]; then
    QSIM_CMD="$QSIM_CMD -assertdebug"
fi

# Custom plusargs
if [ -n "$CUSTOM_PLUSARGS" ]; then
    QSIM_CMD="$QSIM_CMD $CUSTOM_PLUSARGS"
fi

# Custom defines
if [ -n "$CUSTOM_DEFINES" ]; then
    QSIM_CMD="$QSIM_CMD $CUSTOM_DEFINES"
fi

# Library paths
{% for lib in LIBRARIES %}
QSIM_CMD="$QSIM_CMD -L {{ lib }}"
{% endfor %}

# Design unit (optimized or raw depending on flow)
if [ "$SKIP_QOPT" = "0" ]; then
    # Two-step: use optimized design from qopt (always in work library)
    QSIM_CMD="$QSIM_CMD work.$OPTIMIZED_DESIGN"
else
    # Single-step: use raw design with -qoptargs
    {% for top in TOP_UNITS %}
    QSIM_CMD="$QSIM_CMD {{top.LIBRARY_NAME}}.{{top.NAME}} "
    {% endfor %}
    
    # Build -qoptargs for implicit qopt
    QOPTARGS=""
    [ "$QOPT_DEBUG" = "1" ] && QOPTARGS="$QOPTARGS $QOPT_ACCESS" 
    [ "$ENABLE_COVERAGE" = "1" ] && QOPTARGS="$QOPTARGS $COVERAGE_OPTIONS"
    [ "$ENABLE_ASSERTIONS" = "1" ] && QOPTARGS="$QOPTARGS -debug,assert"
    [ "$ENABLE_FSM_DEBUG" = "1" ] && QOPTARGS="$QOPTARGS +cover=f -fsmdebug"
    [ -n "$QOPT_EXTRA_ARGS" ] && QOPTARGS="$QOPTARGS $QOPT_EXTRA_ARGS"
    
    if [ -n "$QOPTARGS" ]; then
        QSIM_CMD="$QSIM_CMD -qoptargs=\"$QOPTARGS\""
    fi
fi

# Logging
QSIM_CMD="$QSIM_CMD -l $QSIM_LOG_FILE"

# DO file
if [ -n "$CUSTOM_DO_FILE" ] && [ -f "$CUSTOM_DO_FILE" ]; then
    QSIM_CMD="$QSIM_CMD -do \"$CUSTOM_DO_FILE\""
elif [ -n "$DO_FILE_PATH" ] && [ -f "$DO_FILE_PATH" ]; then
    QSIM_CMD="$QSIM_CMD -do \"$DO_FILE_PATH\""
else
    DO_COMMANDS="$RUN_TIME"
    
    # Note: Coverage save in DO script won't execute if UVM calls $finish
    # Coverage must be saved in UVM final_phase using SystemVerilog or TCL commands
    
    # Auto-quit for batch mode only
    if [ "$AUTO_QUIT" = "1" ] && [ "$SIM_MODE" = "batch" ] && [ "$ENABLE_VISUALIZER" = "0" ]; then
        DO_COMMANDS="$DO_COMMANDS; quit -f"
    fi
    
    QSIM_CMD="$QSIM_CMD -do \"$DO_COMMANDS\""
fi

log_info "qsim command: $QSIM_CMD"

START_QSIM=$(date +%s)
eval "$QSIM_CMD"
QSIM_EXIT=$?
END_QSIM=$(date +%s)
QSIM_ELAPSED=$((END_QSIM - START_QSIM))

################################################################################
# Summary
################################################################################
TOTAL_ELAPSED=$((QOPT_ELAPSED + QSIM_ELAPSED))

log_info "=========================================="
log_info "Simulation Summary"
log_info "=========================================="
log_info "Flow: $QUESTA_FLOW_MODE"
if [ "$SKIP_QOPT" = "0" ]; then
    log_info "qopt time: ${QOPT_ELAPSED}s"
fi
log_info "qsim time: ${QSIM_ELAPSED}s"
log_info "Total time: ${TOTAL_ELAPSED}s"
log_info "=========================================="

if [ $QSIM_EXIT -eq 0 ]; then
    log_success "Simulation completed successfully"
    if [ "$ENABLE_COVERAGE" = "1" ]; then
        if [ -n "$TESTNAME" ] && [ -f "${TESTNAME}.ucdb" ]; then
            log_info "Coverage DB: ${TESTNAME}.ucdb"
        elif [ -f "$COVERAGE_DB" ]; then
            log_info "Coverage DB: $COVERAGE_DB"
        fi
    fi
    [ "$ENABLE_WAVEFORM" = "1" ] && [ -f "$WAVEFORM_FILE" ] && log_info "Waveform: $WAVEFORM_FILE"
else
    log_error "Simulation failed with exit code $QSIM_EXIT"
    log_error "Check logs: $QOPT_LOG_FILE, $QSIM_LOG_FILE"
fi

exit $QSIM_EXIT
