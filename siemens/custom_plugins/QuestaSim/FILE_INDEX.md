# QuestaSim Plugin - File Index

## Overview

This directory contains the **QuestaSim Enhanced Plugin** for Questa Developer with comprehensive support for two simulation flows and extensive optional features.

**Version:** 2.1  
**Last Updated:** January 2025

---

## File Organization

### Core Plugin Files

#### 1. `config.json`
**Purpose:** Plugin configuration and metadata  
**Contents:**
- Plugin name, description, version
- Command definitions (two simulation flows)
- Template file mappings
- Usage examples
- Environment variable documentation

**Key Commands:**
- "QuestaSim Simulation (vsim)" - Single-step flow
- "QuestaSim Simulation (vopt + vsim)" - Two-step flow

---

#### 2. `template_questasim_script.sh`
**Purpose:** Single-step simulation flow template  
**Type:** Bash script with Django-style template variables  
**Lines:** 463  
**Generated Script:** `questasim_script.sh` (in project directory)

**Features:**
- vsim with implicit vopt in background
- Simple, fast execution
- All optional features supported
- Good for development and quick tests

**Usage:** Selected via "QuestaSim Simulation (vsim)" command

---

#### 3. `template_vopt_vsim_script.sh`
**Purpose:** Two-step simulation flow template  
**Type:** Bash script with Django-style template variables  
**Lines:** 558  
**Generated Script:** `questasim_vopt_vsim_script.sh` (in project directory)

**Features:**
- Step 1: vopt (elaborate/optimize)
- Step 2: vsim (simulate optimized design)
- Production-grade workflow
- Explicit control over elaboration and simulation
- Separate logs (vopt.log, simulation.log)

**Usage:** Selected via "QuestaSim Simulation (vopt + vsim)" command

---

### Documentation Files

#### 4. `README.md`
**Purpose:** Main plugin documentation  
**Lines:** 480+  
**Audience:** All users

**Contents:**
- Overview of both simulation flows
- Quick start guide
- Configuration reference (all environment variables)
- Usage examples (13 scenarios)
- Feature documentation (coverage, UVM, waveform, VIP, debug, etc.)
- Architecture explanation
- Template variables reference
- Version history

**When to read:** First introduction to the plugin

---

#### 5. `TWO_STEP_FLOW.md`
**Purpose:** Comprehensive two-step flow documentation  
**Lines:** 500+  
**Audience:** Users adopting two-step flow

**Contents:**
- Why two-step flow?
- Architecture and design flow diagrams
- Detailed configuration (vopt and vsim variables)
- 9 detailed usage examples
- Manual command-line equivalents
- Logs and outputs reference
- Comparison with single-step flow
- Troubleshooting guide
- Best practices
- Official Siemens documentation references

**When to read:** Implementing production workflows, coverage, or CI/CD

---

#### 6. `FLOW_SELECTION_GUIDE.md`
**Purpose:** Help users choose between single-step and two-step flows  
**Lines:** 350+  
**Audience:** Users unsure which flow to use

**Contents:**
- Quick decision matrix
- Detailed technical comparison
- 7 real-world use case examples:
  1. Daily development
  2. Nightly regression
  3. Coverage analysis
  4. UVM debug session
  5. CI/CD pipeline
  6. VIP simulation
  7. Performance optimization
- Recommendations by team role
- Migration path
- Environment variable compatibility

**When to read:** Choosing between flows, planning workflows

---

#### 7. `QUICK_REFERENCE.md`
**Purpose:** Environment variable reference card  
**Lines:** 300+  
**Audience:** Users configuring the plugin

**Contents:**
- Alphabetical variable listing
- Quick tables by category
- Default values
- Common configuration patterns
- Profile templates (12 profiles)

**When to read:** Looking up specific variable, creating configurations

---

#### 8. `QUICK_START_CARD.md`
**Purpose:** One-page quick reference  
**Lines:** 250+  
**Audience:** Users needing fast lookup

**Contents:**
- Commands summary
- Minimal setup
- Common configurations (one-liners)
- Key variables table
- Decision tree
- Typical workflows
- Troubleshooting quick fixes
- Manual command examples

**When to read:** Quick lookup, troubleshooting

---

#### 9. `TWO_STEP_IMPLEMENTATION.md`
**Purpose:** Implementation details and design decisions  
**Lines:** 600+  
**Audience:** Advanced users, developers, maintainers

**Contents:**
- Implementation motivation
- Official Siemens documentation consulted
- FUSE server query results
- File-by-file implementation details
- Environment variables (new and compatible)
- Flag distribution strategy
- Design decisions (naming, logs, optimization, coverage, etc.)
- Testing and validation
- Benefits analysis
- Comparison with single-step flow
- Future enhancements

**When to read:** Understanding implementation, contributing, advanced tuning

---

#### 10. `ENHANCEMENT_SUMMARY.md`
**Purpose:** Summary of v2.0 enhancements  
**Lines:** 200+  
**Audience:** Users upgrading from v1.0

**Contents:**
- What changed from v1.0
- New features (40+ optional variables)
- Architecture improvements
- Zero-configuration philosophy
- Configuration examples
- Migration guide

**When to read:** Upgrading from v1.0, understanding plugin evolution

---

#### 11. `config_examples.sh`
**Purpose:** Shell script with configuration examples  
**Lines:** 150+  
**Audience:** Users setting up environments

**Contents:**
- 13 configuration profiles
- Copy-paste ready shell exports
- Examples for:
  - Basic GUI
  - Batch simulation
  - Coverage collection
  - UVM testbench
  - Debug mode
  - VIP simulation
  - Regression optimization
  - Power analysis
  - FSM debug
  - Visualizer mode
  - FSDB waveforms
  - Assertions
  - Custom DO files

**When to read:** Setting up shell environment, creating profiles

---

### Legacy/Backup Files

#### 12. `template_questasim_script copy.sh`
**Purpose:** Backup of original template  
**Status:** Not used by plugin  
**Note:** Can be safely removed or kept for reference

---

## File Relationships

```
config.json
│
├─ Commands
│  ├─ "QuestaSim Simulation (vsim)"
│  │  └─ template_questasim_script.sh
│  │
│  └─ "QuestaSim Simulation (vopt + vsim)"
│     └─ template_vopt_vsim_script.sh
│
└─ Documentation
   ├─ README.md (main entry point)
   ├─ FLOW_SELECTION_GUIDE.md (flow comparison)
   ├─ TWO_STEP_FLOW.md (two-step deep dive)
   ├─ QUICK_REFERENCE.md (variable reference)
   ├─ QUICK_START_CARD.md (one-page summary)
   ├─ TWO_STEP_IMPLEMENTATION.md (implementation details)
   ├─ ENHANCEMENT_SUMMARY.md (v2.0 changes)
   └─ config_examples.sh (shell examples)
```

---

## Documentation Hierarchy

### Level 1: Getting Started
1. Read **README.md** (overview, quick start)
2. Check **QUICK_START_CARD.md** (minimal setup)
3. Run plugin with `QUESTA_BIN_DIR` only

### Level 2: Feature Exploration
1. Review **QUICK_REFERENCE.md** (variable reference)
2. Try examples from **config_examples.sh**
3. Explore coverage, UVM, waveform features

### Level 3: Flow Selection
1. Read **FLOW_SELECTION_GUIDE.md** (decision matrix)
2. Understand single-step vs two-step tradeoffs
3. Choose flow based on use case

### Level 4: Production Workflows
1. Read **TWO_STEP_FLOW.md** (comprehensive guide)
2. Implement vopt + vsim flow
3. Configure for regression, coverage, CI/CD

### Level 5: Advanced Topics
1. Read **TWO_STEP_IMPLEMENTATION.md** (implementation details)
2. Understand flag distribution, design decisions
3. Tune performance, customize workflows

---

## Quick File Selection Guide

**I want to...**

| Goal | Read This File |
|------|---------------|
| Understand what this plugin does | `README.md` |
| Get started quickly | `QUICK_START_CARD.md` |
| Choose between single-step and two-step | `FLOW_SELECTION_GUIDE.md` |
| Learn about two-step flow | `TWO_STEP_FLOW.md` |
| Look up an environment variable | `QUICK_REFERENCE.md` |
| Get shell configuration examples | `config_examples.sh` |
| Understand the implementation | `TWO_STEP_IMPLEMENTATION.md` |
| Upgrade from v1.0 | `ENHANCEMENT_SUMMARY.md` |
| Troubleshoot an issue | `QUICK_START_CARD.md` (quick fixes) or `TWO_STEP_FLOW.md` (detailed) |
| Configure coverage | `README.md` (coverage section) or `TWO_STEP_FLOW.md` (examples) |
| Configure UVM | `README.md` (UVM section) or `config_examples.sh` (UVM profile) |
| Set up CI/CD | `FLOW_SELECTION_GUIDE.md` (use case 5) or `TWO_STEP_FLOW.md` |
| Debug elaboration issues | `TWO_STEP_FLOW.md` (troubleshooting) |
| Optimize performance | `FLOW_SELECTION_GUIDE.md` (use case 7) or `TWO_STEP_FLOW.md` (best practices) |

---

## Statistics

### Code
- **Templates:** 2 files (1021 lines total)
  - Single-step: 463 lines
  - Two-step: 558 lines

### Documentation
- **Total:** 9 files (2500+ lines)
- **User-facing:** 7 files
- **Implementation:** 1 file
- **Examples:** 1 file

### Configuration
- **Environment Variables:** 40+ (all optional)
- **Configuration Profiles:** 13
- **Commands:** 2

### Features
- **Simulation Modes:** 3 (GUI, batch, interactive)
- **Advanced Features:** 10+ (coverage, UVM, waveform, VIP, debug, assertions, FSM, power, Visualizer, custom DO)
- **Waveform Formats:** 3 (WLF, VCD, FSDB)
- **Architectures:** 2 (32-bit, 64-bit)

---

## Maintenance Notes

### Adding New Features

1. **Update templates:**
   - Add environment variable check
   - Add command-line flag building logic
   - Add to both templates if applicable

2. **Update documentation:**
   - Add to README.md (configuration reference)
   - Add to QUICK_REFERENCE.md (alphabetical listing)
   - Add example to config_examples.sh
   - Update relevant guides if needed

3. **Update config.json:**
   - Add to `environmentVariables` section
   - Add usage example if significant feature

### Deprecating Features

1. Mark as deprecated in README.md
2. Add migration guide
3. Keep backward compatibility for 1+ version
4. Remove in next major version

### Version Updates

1. Update version in config.json
2. Add entry to version history in README.md
3. Document changes in ENHANCEMENT_SUMMARY.md (for major changes)
4. Update TWO_STEP_IMPLEMENTATION.md if implementation changes

---

## Best Practices for Users

1. **Start with README.md** - Don't skip the overview
2. **Use QUICK_START_CARD.md** - Fast reference saves time
3. **Choose the right flow** - Use FLOW_SELECTION_GUIDE.md
4. **Configure minimally** - Only set variables you need
5. **Read relevant sections** - Don't read everything at once
6. **Test configurations** - Verify settings work before production
7. **Check logs** - vopt.log and simulation.log for debugging
8. **Use profiles** - Copy from config_examples.sh and customize

---

## Contact and Support

For plugin issues:
1. Check troubleshooting sections in documentation
2. Review log files (vopt.log, simulation.log)
3. Verify environment variables
4. Check QuestaSim version compatibility

For documentation issues:
1. Suggest improvements
2. Report errors or outdated info
3. Request additional examples

---

## Version History Summary

| Version | Changes | Files | Lines |
|---------|---------|-------|-------|
| 1.0 | Basic vsim execution | 2 | 150 |
| 2.0 | Comprehensive rewrite, 40+ variables | 6 | 1200 |
| 2.1 | Two-step flow (vopt + vsim) | 12 | 3500+ |

---

## File Sizes (Approximate)

| File | Type | Lines | Size |
|------|------|-------|------|
| `template_questasim_script.sh` | Code | 463 | 15 KB |
| `template_vopt_vsim_script.sh` | Code | 558 | 18 KB |
| `README.md` | Doc | 480 | 25 KB |
| `TWO_STEP_FLOW.md` | Doc | 500 | 27 KB |
| `FLOW_SELECTION_GUIDE.md` | Doc | 350 | 18 KB |
| `QUICK_REFERENCE.md` | Doc | 300 | 15 KB |
| `QUICK_START_CARD.md` | Doc | 250 | 12 KB |
| `TWO_STEP_IMPLEMENTATION.md` | Doc | 600 | 32 KB |
| `ENHANCEMENT_SUMMARY.md` | Doc | 200 | 10 KB |
| `config_examples.sh` | Example | 150 | 8 KB |
| `config.json` | Config | 100 | 5 KB |

**Total:** ~3500 lines, ~185 KB

---

## Recommended Reading Order

### For New Users
1. README.md (sections: Overview, Quick Start, Configuration Reference)
2. QUICK_START_CARD.md
3. config_examples.sh (try basic profiles)

### For Production Users
1. README.md (full read)
2. FLOW_SELECTION_GUIDE.md
3. TWO_STEP_FLOW.md (if using two-step)
4. QUICK_REFERENCE.md (bookmark for lookup)

### For Advanced Users
1. All documentation (comprehensive understanding)
2. TWO_STEP_IMPLEMENTATION.md (implementation details)
3. Template files (understand code structure)

---

**This plugin provides professional-grade QuestaSim simulation with comprehensive configuration, excellent documentation, and support for both development and production workflows.**

**Happy Simulating! 🚀**
