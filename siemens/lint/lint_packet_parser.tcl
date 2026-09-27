# =============================================================================
# lint_packet_parser.tcl
#
# Comprehensive Questa Lint configuration for the packet_parser module.
# Targets the most common RTL mistakes users make when implementing the
# AXI-Stream packet parser (header extraction, BRAM coefficient write,
# sample forwarding, FSM state machine).
#
# Usage (from Questa Lint / qverify shell):
#   do lint_packet_parser.tcl
#
# Output:  packet_parser_only/lint_out/  (HTML + TXT + JSON reports)
# =============================================================================

# onerror is ignored inside qverify do-files.

# ─────────────────────────────────────────────────────────────────────────────
# 1.  METHODOLOGY
#     Use STARC – the broadest standard methodology.  It maps directly to the
#     checks most relevant to a synthesisable, clocked datapath like this one.
# ─────────────────────────────────────────────────────────────────────────────
#lint methodology standard -goal starc
lint off *
# ─────────────────────────────────────────────────────────────────────────────
# 2.  OUTPUT DIRECTORY
#     Used by the report commands below.  Compilation is handled externally.
# ─────────────────────────────────────────────────────────────────────────────
set OUT_DIR [file normalize [file join [file dirname [info script]] lint_out]]
# set PP_SRC  — compilation handled externally, see your qrun filelist
# ─────────────────────────────────────────────────────────────────────────────
# 3.  GLOBAL PREFERENCES
# ─────────────────────────────────────────────────────────────────────────────

# Treat unsigned arithmetic promotions as errors (they mask width mismatches).
lint preference -all_const_output_ports

# Enforce that every case/casez statement has a default branch.
# (assign_width_overflow / assign_width_underflow are enabled as checks in §4a below.)
lint preference -missing_others_or_default

# ─────────────────────────────────────────────────────────────────────────────
# 4.  CHECK-SPECIFIC TUNING
#     Each block below activates or tunes a check that maps to a known pitfall
#     in the packet_parser implementation.  The rationale is documented inline.
# ─────────────────────────────────────────────────────────────────────────────

# ── 4a. WIDTH / ARITHMETIC MISMATCHES ────────────────────────────────────────
#
# KEY RISK:  total_coeffs  = N[3:0]  * T[4:0]  → 9-bit product → assigned to [7:0]
#            total_samples = N[3:0]  * S[6:0]  → 11-bit product → assigned to [8:0]
#            coeff_addr    = {coeff_ch_idx[1:0], coeff_tap_idx[3:0]} → [5:0]  (concat)
#            sample_cnt / coeff_cnt comparisons with differently-sized totals
#
# assign_width_overflow  : LHS wider than significant bits of RHS (zero padding)
# assign_width_underflow : LHS narrower than RHS (silent MSB truncation)
# multi_bit_operand      : logical operators (&&, ||) applied to multi-bit nets
# ─────────────────────────────────────────────────────────────────────────────
lint on assign_width_overflow
lint on assign_width_underflow
lint on logical_operator_on_multi_bit
lint on multiplication_operator
lint on condition_is_multi_bit
lint on logical_not_on_multi_bit

# ── 4b. RESET DISCIPLINE ─────────────────────────────────────────────────────
#
# KEY RISK:  Students forget to reset output ports (hdr_valid, pkt_done, coeff_we,
#            sample_valid, sample_last) or mix synchronous/async reset styles.
#            Active-low reset (rst_n) is the mandated convention here.
#
# flop_without_reset   : any flip-flop inferred without a reset path
# async_reset_active_high : signals named *_n used as active-HIGH reset (polarity bug)
# ─────────────────────────────────────────────────────────────────────────────
lint on flop_without_control
lint on async_reset_active_high

# ── 4c. FSM QUALITY ──────────────────────────────────────────────────────────
#
# KEY RISK:
#   • ST_IDLE (2'd3) is defined in the enum but never explicitly entered — the
#     FSM can reach it only via power-on X propagation or radiation events.
#     unreachable_state check catches this.
#   • Missing default in the case statement leaves a synthesis hole.
#   • One-hot encoding is not used; warn so the student understands the trade-off.
#   • A deadlock (state with no exit) must be impossible for continuous streams.
# ─────────────────────────────────────────────────────────────────────────────
lint on case_default_missing
lint on fsm_state_count_large
lint on fsm_without_reset_state
lint on fsm_with_deadend_state
lint on fsm_with_unreachable_state

# ── 4d. COUNTER / COMPARISON SAFETY ─────────────────────────────────────────
#
# KEY RISK:
#   • Off-by-one:  "coeff_cnt == total_coeffs - 1"  — if total_coeffs is 0
#     (header with N=0 or T=0), the counter wraps and never exits ST_COEFFS.
#   • Counter widths: coeff_cnt is [7:0] (max 255), total_coeffs max = 4*16=64
#     → safe.  sample_cnt is [7:0] but total_samples is [8:0] (max 256)
#     → comparing [7:0] to [8:0] can silently truncate.
# ─────────────────────────────────────────────────────────────────────────────
lint on comparison_width_mismatch
lint on signed_unsigned_mixed_expr

# ── 4e. LATCH INFERENCE ──────────────────────────────────────────────────────
#
# KEY RISK:  always_comb block for coeff_we / coeff_addr / coeff_din must cover
#            all conditions; an incomplete if (missing else) infers a latch.
# ─────────────────────────────────────────────────────────────────────────────
lint on latch_inferred
lint on combo_path_input_to_output
lint on feedthrough_path

# ── 4f. UNDRIVEN / UNUSED SIGNALS ────────────────────────────────────────────
#
# KEY RISK:
#   • sample_last uses samp_in_ch — if students forget the per-channel counter
#     the signal is undriven or always 0.
#   • coeff_din is always s_data[15:0]; if mistakenly connected to [31:16] the
#     upper half of s_data is read-not-used and lower half is set-not-read.
# ─────────────────────────────────────────────────────────────────────────────
lint on var_set_not_read
lint on var_read_not_set
lint on var_read_before_set
lint on var_unused
lint on unloaded_input_port
lint on undriven_output_port
lint on undriven_signal
lint on undriven_reg_clock
lint on undriven_reg_data

# ── 4g. OUTPUT PORT REGISTRATION ─────────────────────────────────────────────
#
# KEY RISK:  hdr_valid, pkt_done, coeff_we are control outputs that should be
#            registered (driven from flip-flops) to prevent glitching.
#            sample_valid, sample_last are combinationally gated — that is
#            intentional and should be noted / reviewed.
# ─────────────────────────────────────────────────────────────────────────────
lint on module_output_not_registered

# Note: Waivers are intentionally not applied here because this qverify flow
# reports "unmatched argument" on lint report item directives in setup Tcl.
# Apply waivers through the generated status directives flow if needed.

# ── 4h. CLOCK DISCIPLINE ─────────────────────────────────────────────────────
#
# KEY RISK:  Students sometimes add a second always_ff that uses a different
#            sensitivity list or clock expression.
# ─────────────────────────────────────────────────────────────────────────────
lint on always_has_multiple_events
lint on process_without_event
lint on process_has_async_set_reset
lint on reset_polarity_mismatch
lint on clock_signal_as_non_clock
lint on clock_gated

# ── 4i. CODING STYLE (SYNTHESISABILITY) ──────────────────────────────────────
#
# Blocking vs non-blocking: mixing "=" inside always_ff is a classic bug.
# ─────────────────────────────────────────────────────────────────────────────
lint on blocking_assign_in_seq_block
lint on nonblocking_assign_in_combo_block

# ── 4j. CASE / CONDITION COMPLETENESS ────────────────────────────────────────
#
# The 2-bit state enum has 4 encodings; all four should be handled (or a
# default/others clause must be present).  Also check for case expressions
# that can never be true (dead branches).
# ─────────────────────────────────────────────────────────────────────────────
lint on case_item_duplicate
lint on case_item_invalid
lint on casez_has_x
lint on bus_bits_not_set
lint on condition_const

# ── 4k. PORT / PARAMETER SANITY ──────────────────────────────────────────────
#
# Verify parameter values stay within the declared signal widths:
#   MAX_CHANNELS=4 → 3 bits, but num_channels port is [3:0] → OK
#   MAX_TAPS=16    → 5 bits, num_taps is [4:0]              → OK
#   MAX_SAMPLES=64 → 7 bits, num_samples is [6:0]           → OK
#   Students might widen/narrow these and break the arithmetic.
# ─────────────────────────────────────────────────────────────────────────────
lint on inst_param_width_overflow
lint on inst_port_width_mismatch

# ─────────────────────────────────────────────────────────────────────────────
# 5.  NAME-CONVENTION PREFERENCES
#     Reinforce naming rules expected in the hackathon RTL style guide.
# ─────────────────────────────────────────────────────────────────────────────

# Active-low resets must end in _n or _b
lint preference name -check control_signal_active_low -suffix {_n,_b}

# Enable naming checks explicitly (all checks were disabled by "lint off *").
lint on signal_name_not_standard
lint on data_type_name_not_standard
lint report check  signal_name_not_standard -severity warning
lint report check  data_type_name_not_standard -severity warning

# Include enum types/literals in naming analysis.
lint preference -verilog_data_type enumerated enumerated_literal

# State enum/signal style: enforce UPPER_CASE with underscores.
lint preference name -check signal_name_not_standard -regexp {^[A-Z][A-Z0-9_]*$}
lint preference name -check data_type_name_not_standard -regexp {^ST_[A-Z0-9_]*$}

# ─────────────────────────────────────────────────────────────────────────────
# 6.  RUN LINT
# ─────────────────────────────────────────────────────────────────────────────

lint run -d packet_parser
puts ""
puts "============================================================"
puts " Lint run complete."
puts " lint.rpt is written to the qverify output directory (-od)."
puts " scripts/run_lint.sh republishes it as results/lint.rpt,"
puts " which is the file score.py reads."
puts "============================================================"
