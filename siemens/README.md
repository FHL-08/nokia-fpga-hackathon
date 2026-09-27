# FIR Filter Bank — Packet Parser Hackathon Exercise

## Objective

Complete the `packet_parser` module so the entire FIR Filter Bank design compiles, simulates correctly, and passes lint checks.

The `packet_parser` module parses incoming AXI-Stream packets containing a header, filter coefficients, and input samples. It feeds the downstream FIR channel engines and coefficient BRAMs.

## What You Receive

```
hackathon_exercise/
├── rtl/                        # Full RTL design
│   ├── packet_parser.sv        # ← YOUR TASK: fill in the two TODO blocks
│   ├── fir_filter_bank_top.sv  # Top-level integrator (read-only)
│   ├── fir_channel.sv          # FIR engine (read-only)
│   ├── coeff_bram.sv           # Coefficient BRAM (read-only)
│   ├── output_packetizer.sv    # Output serializer (read-only)
│   └── saturation.sv           # Q1.15 saturation (read-only)
├── tb/
│   ├── tb_packet_parser.sv     # Standalone testbench — 14 test cases
│   ├── tb_fir_filter_bank.sv   # Full-system testbench — 5 test vectors
│   └── tb_pkg.sv               # Q1.15 helpers and reference model
├── doc/
│   └── Packet_parser_requirements.docx   # Full specification
├── lint/
│   └── lint_packet_parser.tcl  # Questa Lint configuration (45+ checks)
├── scripts/
│   ├── common.sh               # shared tool discovery + compile/sim helper
│   ├── run_lint.sh             # Questa Lint      -> results/lint.rpt
│   ├── run_parser_tb.sh        # packet_parser TB -> results/parser_sim.log
│   ├── run_fir_tb.sh           # FIR system TB    -> results/fir_sim.log
│   ├── run_all.sh              # runs all three, then scores
│   └── score.py                # scorer -> results/score.txt + score.json
├── Jenkinsfile                 # CI pipeline (runs scripts/run_all.sh)
└── solution/                   # Reference solution (remove before distributing)
    └── packet_parser.sv
```

## Your Task

Open `rtl/packet_parser.sv` and implement the two `always_ff` blocks marked with **TODO**:

### TODO 1 — Main FSM + Sequential Logic (~45 lines)

Implement the 3-state FSM that processes incoming AXI-Stream words:

| State | Action |
|-------|--------|
| `st_header` | When `s_valid`, extract N/T/S from `s_data`, compute totals, pulse `hdr_valid`, go to `ST_COEFFS` |
| `ST_COEFFS` | Count coefficient words, track per-channel tap index for BRAM addressing, transition to `ST_SAMPLES` when all coefficients received |
| `ST_SAMPLES` | Count sample words, pulse `pkt_done` when last sample received, return to `st_header` |

Key details:
- Asynchronous active-low reset (`rst_n`)
- `hdr_valid` and `pkt_done` must pulse for exactly 1 clock cycle
- Header format: `s_data = {N[31:24], T[23:16], S[15:0]}`
- `total_coeffs = N × T`, `total_samples = N × S`
- BRAM addressing: track `coeff_ch_idx` and `coeff_tap_idx` — reset tap index and advance channel when `coeff_tap_idx == r_num_taps - 1`

### TODO 2 — Sample Channel Tracking (~15 lines)

Implement per-channel sample counting:
- Reset on new packet header
- In `ST_SAMPLES`: track `samp_in_ch` (0 to `r_num_samp - 1`), advance `ch_idx` at each channel boundary

## AXI-Stream Packet Format

```
Word 0 (Header):
  [31:24] = N  (num_channels, 1–4)
  [23:16] = T  (num_taps, 1–16)
  [15:0]  = S  (num_samples, 1–64)

Words 1..N×T (Coefficients, channel-major):
  [15:0]  = Q1.15 signed coefficient
  Order:  ch0_tap0, ch0_tap1, …, ch0_tap(T-1), ch1_tap0, …

Words N×T+1..N×T+N×S (Samples, channel-major):
  [15:0]  = Q1.15 signed sample
  Order:  ch0_samp0, …, ch0_samp(S-1), ch1_samp0, …
  s_last asserted on final word
```

## Verification Workflow

Everything runs headlessly from the command line — no GUI, no VS Code, no
Questa Developer project. The scripts compile only files tracked in this
repository.

```bash
bash scripts/run_all.sh          # lint + both testbenches + score
```

Run the stages individually while you iterate:

```bash
bash scripts/run_lint.sh         # -> results/lint.rpt
bash scripts/run_parser_tb.sh    # -> results/parser_sim.log
bash scripts/run_fir_tb.sh       # -> results/fir_sim.log
python3 scripts/score.py         # -> score card on stdout
```

The two testbenches use separate work libraries and separate log files, so
running one never invalidates the other's result.

> `ip_tb_ready/` and `uvm_fir_seq/` hold a Questa VIP / UVM environment that is
> **not** part of grading — it depends on generated VIP files that are not
> tracked here. `tb/tb_fir_filter_bank.sv` is the FIR testbench that counts.

### Tool setup

The scripts locate QuestaSim and qverify automatically when they are on `PATH`,
but point them explicitly for a reproducible run:

```bash
export QUESTA_BIN=/path/to/questa/<version>/questasim/bin
export QVERIFY_BIN=/path/to/q1sfv/<version>/bin
```

### Evaluation artifacts

`scripts/run_all.sh` always writes these, one file per stage, never shared:

| File | Produced by | Read by |
|------|-------------|---------|
| `results/lint.rpt` | `run_lint.sh` | `score.py` |
| `results/parser_sim.log` | `run_parser_tb.sh` | `score.py` |
| `results/fir_sim.log` | `run_fir_tb.sh` | `score.py` |
| `results/*_compile.log` | compile step | humans, on failure |
| `results/score.txt` | `score.py` | Jenkins |
| `results/score.json` | `score.py` | Jenkins / dashboards |

### Scoring

| Section | Max | How it is earned |
|---------|-----|------------------|
| Packet Parser | 6.00 | Per-check partial credit across TC01–TC14 |
| FIR Filter Bank | 4.00 | Pro-rated over the 5 test vectors |
| **Core** | **10.00** | |
| Bonus — clean run | 3.00 | All vectors pass, 0 sample errors, latency and backpressure clean |
| Bonus — lint-free RTL | 1.00 | 0 lint errors (`--lint-max-errors` to relax) |
| **Total** | **14.00** | |

`SCORE_STATUS` is `PASS` when every artifact was found and the core score
reaches 60% (`--pass-threshold`).

### CI contract

`score.py` prints a stable, greppable block. These are the strings to match:

```
===== HACKATHON SCORE SUMMARY =====
SCORE_PARSER: 6.00 / 6.00
SCORE_FIR: 4.00 / 4.00
SCORE_CORE: 10.00 / 10.00
SCORE_BONUS_CLEAN_RUN: 3.00 / 3.00
SCORE_BONUS_LINT: 1.00 / 1.00
SCORE_BONUS: 4.00 / 4.00
SCORE_TOTAL: 14.00 / 14.00
SCORE_PERCENT: 100.00
SCORE_STATUS: PASS
SCORE_MISSING_ARTIFACTS: 0
FINAL_SCORE: 14.00/14.00
===== END HACKATHON SCORE SUMMARY =====
```

The two lines CI keys on are `FINAL_SCORE: <total>/<max>` and
`SCORE_STATUS: PASS|FAIL`.

### Jenkins

Every push triggers [Jenkinsfile](Jenkinsfile), which runs
`bash scripts/run_all.sh` and archives `results/**`. The agent must provide
`QUESTA_BIN`, `QVERIFY_BIN` and the licence environment; nothing else is
assumed. A submission below the pass threshold marks the build **unstable**,
not failed.

### Work through the exercise in this order

#### Step 1: Implement TODO 1 and TODO 2

Read the spec in `doc/Packet_parser_requirements.docx`, study the TODO comments in the skeleton, and write your implementation.

#### Step 2: Run Questa Lint

```bash
bash scripts/run_lint.sh
```

Fix any lint violations before proceeding to simulation. The lint config checks for:
- Width mismatches and truncation
- Missing resets on flip-flops
- FSM quality (unreachable/deadend states)
- Latch inference
- Blocking assigns in sequential blocks
- Undriven outputs and unused signals
- Naming conventions (UPPER_CASE signals and `ST_` prefixed enum types)

#### Step 3: Run Standalone Testbench (14 test cases)

```bash
bash scripts/run_parser_tb.sh
```

All 14 test cases must pass:
- TC01: Reset behavior
- TC02–TC03: Typical and maximum packets
- TC04–TC05: Valid gaps in coefficients/samples
- TC06: Back-to-back packets
- TC07: Reset mid-packet
- TC08: s_ready always high
- TC09–TC10: hdr_valid/pkt_done pulse width
- TC11: BRAM address sequence
- TC12–TC13: Per-channel sample_last
- TC14: Coefficient data integrity

#### Step 4: Run Full-System Testbench (5 test vectors)

```bash
bash scripts/run_fir_tb.sh
```

All 196 filtered output samples across 5 test vectors must match the software reference model.

## Success Criteria

| Check | Target |
|-------|--------|
| Questa Lint | No errors; understand all warnings |
| Standalone TB | 14/14 test cases PASS |
| Full-system TB | 5/5 test vectors PASS, 196/196 samples correct |
| Latency | ≤ 32 cycles from last input to first output |

## What to Commit

Commit your source only — `rtl/`, and anything else you genuinely changed.
Everything under `results/` and `work/` is regenerated on every run and is
already covered by [.gitignore](.gitignore). Each push triggers a Jenkins
build that reruns the whole flow from scratch.

## Suggested Milestones

| Time | Milestone |
|------|-----------|
| 0:00–0:30 | Read spec, study skeleton and existing combinational logic |
| 0:30–1:00 | Implement TODO 1: header parsing + ST_COEFFS state |
| 1:00–1:30 | Implement TODO 1: ST_SAMPLES state + TODO 2: channel tracking |
| 1:30–2:00 | Run lint, fix violations |
| 2:00–2:30 | Run standalone TB, debug failures |
| 2:30–3:00 | Run full-system TB, final fixes |

## Bonus Step: Fix the Setup Timing Violation (Extra Points!)

After completing the main exercise, run Vivado STA on the design. You will see **setup violations** (WNS ≈ -0.476ns) on the multiply-accumulate path inside `fir_channel.sv`.

**The problem:** The critical path performs BRAM read → DSP48 multiply → 32-bit carry-chain accumulation all in a single clock cycle. This creates 11 logic levels (BRAM → DSP48E1 → LUT2 → 8× CARRY4 → LUT2 → FF) with 8.098ns of logic delay, exceeding the 10ns clock period.

**Your challenge:** Pipeline the `fir_channel` module to break this critical path.

### Recommended Approach: Register the Multiply Result

The simplest and most effective fix is to add a **pipeline register** (`mult_pipe`) between the DSP multiplier output and the accumulator adder. Here's a step-by-step guide:

#### Step 1: Add the pipeline register

Declare a new 32-bit register next to `mult_result`:

```systemverilog
logic signed [31:0] mult_pipe;   // pipeline register between multiply and accumulate
```

Don't forget to reset it to `'0` in the async reset block.

#### Step 2: Understand the original ST_MAC timing

In the original design, ST_MAC does everything in one cycle:

```
Cycle N:  coeff_dout arrives → multiply → add to accumulator  (too slow!)
```

After pipelining, we split this into two stages:

```
Cycle N:    coeff_dout arrives → multiply → store in mult_pipe  (Stage 1)
Cycle N+1:  mult_pipe          → add to accumulator             (Stage 2)
```

Both stages run **simultaneously** in each ST_MAC cycle — Stage 1 processes the *current* tap while Stage 2 accumulates the *previous* tap's result.

#### Step 3: Modify ST_MAC to use two pipeline stages

In each ST_MAC cycle, do both:

```systemverilog
// Stage 1: compute and REGISTER the multiply (current tap)
mult_pipe   <= $signed(shift_reg[mac_tap]) * $signed(coeff_dout);

// Stage 2: ACCUMULATE the previous tap's product from mult_pipe
accumulator <= accumulator + (mult_pipe >>> 15);
```

**Key insight:** At `mac_tap == 0`, the `mult_pipe` still holds `0` from initialization in ST_SHIFT, so accumulating it is harmless (adds zero).

#### Step 4: Add a new state to drain the pipeline

After the last tap (`mac_tap == num_taps - 1`), the final multiply is sitting in `mult_pipe` but has NOT been accumulated yet. You need one extra state to drain it:

```systemverilog
ST_MAC_LAST: begin
    accumulator <= accumulator + (mult_pipe >>> 15);
    state       <= ST_OUTPUT;
end
```

Add `ST_MAC_LAST = 3'd4` to your `state_t` enum.

#### Step 5: Initialize mult_pipe in ST_SHIFT

In ST_SHIFT, alongside resetting `accumulator <= '0`, also reset:

```systemverilog
mult_pipe <= '0;   // so first ST_MAC accumulation adds zero
```

#### Step 6: Verify the flow

For a 3-tap filter, the pipelined MAC flow looks like:

| Cycle | State | Stage 1 (mult_pipe <=) | Stage 2 (accumulator +=) |
|-------|-------|------------------------|--------------------------|
| 0 | ST_MAC (tap 0) | `sr[0] × coeff[0]` | `+ 0` (init) |
| 1 | ST_MAC (tap 1) | `sr[1] × coeff[1]` | `+ sr[0]×coeff[0]` |
| 2 | ST_MAC (tap 2) | `sr[2] × coeff[2]` | `+ sr[1]×coeff[1]` |
| 3 | ST_MAC_LAST | — | `+ sr[2]×coeff[2]` |
| 4 | ST_OUTPUT | saturate & output | — |

**Cost:** +1 cycle per sample. Worst case (T=16): 20 cycles total, still within the ≤32-cycle latency budget.

**Important:** The rest of the FSM (ST_IDLE, ST_SHIFT, ST_OUTPUT, FIFO logic, coefficient pre-fetching) stays **exactly the same**. You only change ST_MAC and add ST_MAC_LAST.

**Scoring:**
- Setup violations eliminated (WNS ≥ 0) → **+5 bonus points**
- Full-system testbench still passes after pipelining → **+5 bonus points**

## Tips

- The combinational logic (BRAM write, output assigns) is already provided — don't modify it
- Study how `coeff_addr` is formed: `{coeff_ch_idx, coeff_tap_idx[3:0]}` — your sequential logic must drive these correctly
- `sample_last` is derived from `samp_in_ch == r_num_samp - 1` — make sure your TODO 2 drives `samp_in_ch` correctly
- All outputs that depend on `state` (like `sample_valid`, `coeff_we`) are already wired — you just need to drive `state` through the FSM
- Watch the comparison `sample_cnt == total_samples - 1`: `sample_cnt` is 8 bits but `total_samples` is 9 bits
