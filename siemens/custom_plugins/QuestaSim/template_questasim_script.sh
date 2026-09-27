#!/bin/bash
################################################################################
# QuestaSim Enhanced Simulation Script
# Description: Comprehensive simulation script with optional feature support
# Generated from Questa Developer Plugin System
################################################################################

# Script configuration
set -o pipefail  # Propagate pipe failures

################################################################################
# Color output support (optional)
################################################################################
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

################################################################################
# Logging functions
################################################################################
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

################################################################################
# Setup working directory
################################################################################
RUN_DIR="{{RUN_DIR}}"
if [ ! -d "$RUN_DIR" ]; then
    log_info "Creating run directory: $RUN_DIR"
    mkdir -p "$RUN_DIR" || {
        log_error "Failed to create directory: $RUN_DIR"
        exit 1
    }
fi

cd "$RUN_DIR" || {
    log_error "Failed to change to directory: $RUN_DIR"
    exit 1
}

log_info "Working directory: $(pwd)"

################################################################################
# Validate QuestaSim installation
################################################################################
if [ -z "$QUESTA_BIN_DIR" ]; then
    log_error "QUESTA_BIN_DIR environment variable is not set"
    exit 1
fi

VSIM_EXEC="${QUESTA_BIN_DIR}/vsim"
if [ ! -x "$VSIM_EXEC" ]; then
    log_error "QuestaSim executable not found or not executable: $VSIM_EXEC"
    exit 1
fi

# Add QuestaSim to PATH
export PATH="${QUESTA_BIN_DIR}:${PATH}"

################################################################################
# Version compatibility check
################################################################################
extract_version() {
    echo "$1" | grep -oE '\b[0-9]{2,4}\.[1-4]\b' | awk -F'.' '{print $1}'
}

QUESTASIM_VERSION=$("${VSIM_EXEC}" -version 2>/dev/null | head -1)
log_info "QuestaSim Version: $QUESTASIM_VERSION"

QUESTASIM_YEAR=$(extract_version "$QUESTASIM_VERSION")
DEVELOPER_YEAR=$(extract_version "{{DEVELOPER_VERSION}}")

if [ -n "$QUESTASIM_YEAR" ] && [ -n "$DEVELOPER_YEAR" ] && [ "$QUESTASIM_YEAR" != "$DEVELOPER_YEAR" ]; then
    log_warning "Version mismatch: QuestaSim ($QUESTASIM_YEAR) vs Questa Developer ($DEVELOPER_YEAR)"
fi

################################################################################
# Configuration: Simulation Parameters
################################################################################
# Core simulation settings
QUESTA_INI_PATH="{{MODELSIM_PATH}}"
QUESTA_INI_PATH="${QUESTA_INI_PATH%/*}/questa.ini"

# Default simulation time resolution (can be overridden)
SIM_TIME_RESOLUTION="${QUESTA_SIM_TIME_RESOLUTION:-1ps}"

# Default simulation mode
SIM_MODE="${QUESTA_SIM_MODE:-gui}"  # Options: gui, batch, interactive

# Architecture selection (32 or 64-bit)
SIM_ARCH="${QUESTA_SIM_ARCH:-64}"

################################################################################
# Configuration: Optional Features
################################################################################

# === Coverage Collection (Optional) ===
ENABLE_COVERAGE="${QUESTA_ENABLE_COVERAGE:-0}"
COVERAGE_OPTIONS="${QUESTA_COVERAGE_OPTIONS:--coverage}"
COVERAGE_DB="${QUESTA_COVERAGE_DB:-coverage.ucdb}"

# === UVM Support (Optional) ===
ENABLE_UVM="${QUESTA_ENABLE_UVM:-0}"
UVM_TESTNAME="${QUESTA_UVM_TESTNAME:-}"
UVM_VERBOSITY="${QUESTA_UVM_VERBOSITY:-UVM_MEDIUM}"
UVM_CONFIG_DB="${QUESTA_UVM_CONFIG_DB:-}"

# === Waveform Capture (Optional) ===
ENABLE_WAVEFORM="${QUESTA_ENABLE_WAVEFORM:-0}"
WAVEFORM_FORMAT="${QUESTA_WAVEFORM_FORMAT:-wlf}"  # Options: wlf, vcd, fsdb
WAVEFORM_FILE="${QUESTA_WAVEFORM_FILE:-vsim.wlf}"
WAVEFORM_DB="${QUESTA_WAVEFORM_DB:-}"  # For qwavedb

# === Debug Mode (Optional) ===
ENABLE_DEBUG="${QUESTA_ENABLE_DEBUG:-0}"
DEBUG_LEVEL="${QUESTA_DEBUG_LEVEL:-+acc}"  # Options: +acc, +acc=npr, etc.

# === Optimization (Optional) ===
ENABLE_VOPT="${QUESTA_ENABLE_VOPT:-0}"
VOPT_OPTIONS="${QUESTA_VOPT_OPTIONS:--O5}"

# === VIP/PLI Support (Optional) ===
VIP_PLI_LIB="${QUESTA_VIP_PLI_LIB:-}"
VIP_ENABLE="${QUESTA_VIP_ENABLE:-0}"

# === Assertion Support (Optional) ===
ENABLE_ASSERTIONS="${QUESTA_ENABLE_ASSERTIONS:-1}"
ASSERTION_OPTIONS="${QUESTA_ASSERTION_OPTIONS:-}"

# === FSM Debugging (Optional) ===
ENABLE_FSM_DEBUG="${QUESTA_ENABLE_FSM_DEBUG:-0}"

# === Power Analysis (Optional) ===
ENABLE_POWER="${QUESTA_ENABLE_POWER:-0}"
POWER_OPTIONS="${QUESTA_POWER_OPTIONS:-}"

# === Transcript/Log Control ===
TRANSCRIPT_FILE="${QUESTA_TRANSCRIPT_FILE:-transcript}"
LOG_FILE="${QUESTA_LOG_FILE:-simulation.log}"

# === Custom DO file (Optional) ===
DO_FILE_PATH="{{DO_FILE_PATH}}"
CUSTOM_DO_FILE="${QUESTA_CUSTOM_DO_FILE:-}"

# === Visualization Mode (Optional) ===
ENABLE_VISUALIZER="${QUESTA_ENABLE_VISUALIZER:-0}"
VISUALIZER_OPTIONS="${QUESTA_VISUALIZER_OPTIONS:-}"

# === Custom plusargs and defines ===
CUSTOM_PLUSARGS="${QUESTA_CUSTOM_PLUSARGS:-}"
CUSTOM_DEFINES="${QUESTA_CUSTOM_DEFINES:-}"

# === Batch/Interactive control ===
RUN_TIME="${QUESTA_RUN_TIME:-run -all}"
AUTO_QUIT="${QUESTA_AUTO_QUIT:-1}"

################################################################################
# Print Configuration Summary
################################################################################
################################################################################
# Configuration Validation and Conflict Resolution
################################################################################

# Resolve conflicts between incompatible options
if [ "$ENABLE_VISUALIZER" = "1" ]; then
    if [ "$SIM_MODE" = "batch" ]; then
        log_warning "Visualizer mode is incompatible with batch mode"
        log_warning "Changing mode from 'batch' to 'gui' for Visualizer compatibility"
        SIM_MODE="gui"
    fi
fi

# If batch mode with GUI-only features, warn user
if [ "$SIM_MODE" = "batch" ] && [ "$ENABLE_VISUALIZER" = "0" ]; then
    if [ "$ENABLE_FSM_DEBUG" = "1" ]; then
        log_warning "FSM debug visualization works best in GUI mode"
    fi
fi

################################################################################
# Print Configuration Summary
################################################################################
log_info "=========================================="
log_info "Simulation Configuration"
log_info "=========================================="
log_info "Mode: $SIM_MODE"
log_info "Architecture: ${SIM_ARCH}-bit"
log_info "Time Resolution: $SIM_TIME_RESOLUTION"
log_info "INI File: $QUESTA_INI_PATH"
log_info "Top Units: {% for top in TOP_UNITS %}{{top.LIBRARY_NAME}}.{{top.NAME}} {% endfor %}"
log_info "Libraries: {% for lib in LIBRARIES %}{{ lib }} {% endfor %}"

if [ "$ENABLE_COVERAGE" = "1" ]; then
    log_info "Coverage: Enabled (DB: $COVERAGE_DB)"
fi

if [ "$ENABLE_UVM" = "1" ]; then
    log_info "UVM: Enabled (Test: $UVM_TESTNAME, Verbosity: $UVM_VERBOSITY)"
fi

if [ "$ENABLE_WAVEFORM" = "1" ]; then
    log_info "Waveform: Enabled (Format: $WAVEFORM_FORMAT, File: $WAVEFORM_FILE)"
fi

if [ "$VIP_ENABLE" = "1" ] && [ -n "$VIP_PLI_LIB" ]; then
    log_info "VIP: Enabled (PLI: $VIP_PLI_LIB)"
fi

if [ "$ENABLE_VISUALIZER" = "1" ]; then
    log_info "Visualizer: Enabled"
fi

log_info "=========================================="

################################################################################
# Build simulation command
################################################################################
VSIM_CMD="${VSIM_EXEC}"

# Architecture selection
if [ "$SIM_ARCH" = "64" ]; then
    VSIM_CMD="$VSIM_CMD -64"
elif [ "$SIM_ARCH" = "32" ]; then
    VSIM_CMD="$VSIM_CMD -32"
fi

# Simulation mode selection
# Note: Visualizer mode is incompatible with -batch and -c flags
# When Visualizer is enabled, we use GUI mode only
if [ "$ENABLE_VISUALIZER" = "1" ]; then
    # Add Visualizer flag (implies GUI mode, no -batch or -c allowed)
    VSIM_CMD="$VSIM_CMD -visualizer $VISUALIZER_OPTIONS"
    log_info "Using Visualizer mode (GUI)"
else
    # Normal mode selection when Visualizer is disabled
    case "$SIM_MODE" in
        batch)
            VSIM_CMD="$VSIM_CMD -batch -quiet"
            ;;
        interactive)
            VSIM_CMD="$VSIM_CMD -c"
            ;;
        gui)
            # GUI mode (default, no additional flags needed)
            ;;
        *)
            log_warning "Unknown SIM_MODE: $SIM_MODE, defaulting to GUI"
            ;;
    esac
fi

# Time resolution
VSIM_CMD="$VSIM_CMD -t $SIM_TIME_RESOLUTION"

# INI file
if [ -f "$QUESTA_INI_PATH" ]; then
    VSIM_CMD="$VSIM_CMD -modelsimini \"$QUESTA_INI_PATH\""
else
    log_warning "INI file not found: $QUESTA_INI_PATH"
fi

# Suppress warnings (configurable)
VSIM_CMD="$VSIM_CMD +nowarnTSCALE +nowarnTFMPC"

# Debug/Optimization
if [ "$ENABLE_DEBUG" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -voptargs=$DEBUG_LEVEL"
elif [ "$ENABLE_VOPT" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -voptargs=\"$VOPT_OPTIONS\""
else
    VSIM_CMD="$VSIM_CMD -voptargs=+acc"
fi

# Coverage
if [ "$ENABLE_COVERAGE" = "1" ]; then
    VSIM_CMD="$VSIM_CMD $COVERAGE_OPTIONS"
    VSIM_CMD="$VSIM_CMD -coverstore $COVERAGE_DB"
fi

# Waveform capture
if [ "$ENABLE_WAVEFORM" = "1" ]; then
    case "$WAVEFORM_FORMAT" in
        wlf)
            VSIM_CMD="$VSIM_CMD -wlf $WAVEFORM_FILE"
            ;;
        vcd)
            # VCD will be handled in DO commands
            ;;
        fsdb)
            if [ -n "$VERDI_HOME" ]; then
                VSIM_CMD="$VSIM_CMD -fsdb $WAVEFORM_FILE"
            else
                log_warning "VERDI_HOME not set, FSDB format unavailable"
            fi
            ;;
    esac
    
    if [ -n "$WAVEFORM_DB" ]; then
        VSIM_CMD="$VSIM_CMD -qwavedb=$WAVEFORM_DB"
    fi
fi

# VIP/PLI support
if [ "$VIP_ENABLE" = "1" ] && [ -n "$VIP_PLI_LIB" ]; then
    if [ -f "$VIP_PLI_LIB" ]; then
        VSIM_CMD="$VSIM_CMD -pli \"$VIP_PLI_LIB\""
        VSIM_CMD="$VSIM_CMD -permit_unmatched_virtual_intf"
    else
        log_warning "VIP PLI library not found: $VIP_PLI_LIB"
    fi
fi

# UVM support
if [ "$ENABLE_UVM" = "1" ]; then
    if [ -n "$UVM_TESTNAME" ]; then
        VSIM_CMD="$VSIM_CMD +UVM_TESTNAME=$UVM_TESTNAME"
    fi
    VSIM_CMD="$VSIM_CMD +UVM_VERBOSITY=$UVM_VERBOSITY"
    
    if [ -n "$UVM_CONFIG_DB" ]; then
        VSIM_CMD="$VSIM_CMD +UVM_CONFIG_DB_TRACE"
    fi
fi

# Assertions
if [ "$ENABLE_ASSERTIONS" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -assertdebug $ASSERTION_OPTIONS"
fi

# FSM debugging
if [ "$ENABLE_FSM_DEBUG" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -fsmdebug"
fi

# Power analysis
if [ "$ENABLE_POWER" = "1" ]; then
    VSIM_CMD="$VSIM_CMD -power $POWER_OPTIONS"
fi

# Transcript/Log files
VSIM_CMD="$VSIM_CMD -l $LOG_FILE"

# Custom plusargs
if [ -n "$CUSTOM_PLUSARGS" ]; then
    VSIM_CMD="$VSIM_CMD $CUSTOM_PLUSARGS"
fi

# Custom defines
if [ -n "$CUSTOM_DEFINES" ]; then
    VSIM_CMD="$VSIM_CMD $CUSTOM_DEFINES"
fi

# Library paths
{% for lib in LIBRARIES %}
VSIM_CMD="$VSIM_CMD -L {{ lib }}"
{% endfor %}

# Top-level units
{% for top in TOP_UNITS %}
VSIM_CMD="$VSIM_CMD {{top.LIBRARY_NAME}}.{{top.NAME}}"
{% endfor %}

# DO file execution
if [ -n "$CUSTOM_DO_FILE" ] && [ -f "$CUSTOM_DO_FILE" ]; then
    VSIM_CMD="$VSIM_CMD -do \"$CUSTOM_DO_FILE\""
elif [ -n "$DO_FILE_PATH" ] && [ -f "$DO_FILE_PATH" ]; then
    VSIM_CMD="$VSIM_CMD -do \"$DO_FILE_PATH\""
else
    # Generate default DO commands
    DO_COMMANDS="$RUN_TIME"
    # Only auto-quit in batch mode (not in visualizer/gui mode)
    if [ "$AUTO_QUIT" = "1" ] && [ "$SIM_MODE" = "batch" ] && [ "$ENABLE_VISUALIZER" = "0" ]; then
        DO_COMMANDS="$DO_COMMANDS; quit -f"
    fi
    VSIM_CMD="$VSIM_CMD -do \"$DO_COMMANDS\""
fi

################################################################################
# Execute simulation
################################################################################
log_info "=========================================="
log_info "Starting QuestaSim simulation..."
log_info "=========================================="
log_info "Command: $VSIM_CMD"
log_info "=========================================="

# Record start time
START_TIME=$(date +%s)
START_TIME_STR=$(date '+%Y-%m-%d %H:%M:%S')
log_info "Simulation started at: $START_TIME_STR"

# Execute with proper error handling
eval "$VSIM_CMD"
EXIT_STATUS=$?

# Record end time
END_TIME=$(date +%s)
END_TIME_STR=$(date '+%Y-%m-%d %H:%M:%S')
ELAPSED=$((END_TIME - START_TIME))

log_info "=========================================="
log_info "Simulation completed at: $END_TIME_STR"
log_info "Elapsed time: ${ELAPSED}s"
log_info "=========================================="

################################################################################
# Post-simulation actions
################################################################################
if [ $EXIT_STATUS -eq 0 ]; then
    log_success "Simulation completed successfully"
    
    # Optional: Generate reports
    if [ "$ENABLE_COVERAGE" = "1" ] && [ -f "$COVERAGE_DB" ]; then
        log_info "Coverage database created: $COVERAGE_DB"
    fi
    
    if [ "$ENABLE_WAVEFORM" = "1" ] && [ -f "$WAVEFORM_FILE" ]; then
        log_info "Waveform file created: $WAVEFORM_FILE"
    fi
    
else
    log_error "Simulation failed with exit status: $EXIT_STATUS"
    if [ -f "$LOG_FILE" ]; then
        log_error "Check simulation log: $LOG_FILE"
    fi
fi

################################################################################
# Cleanup (optional)
################################################################################
# Add any cleanup tasks here if needed

exit $EXIT_STATUS
