# FORENSIC AUDIT REPORT -- Float
**Audit Date:** 2026-03-14
**Auditor:** Master Control (Claude Code)
**Framework Location:** /media/heathen-admin/RAID/Development/Projects/portfolio/float
**Total Files Analyzed:** 10 source files (+ 27 documentation files)
**Total Lines of Code:** 1,716

## EXECUTIVE SUMMARY

Float is a well-structured desktop video blender with clean separation of concerns across bash orchestration, Lua visual effects, Python audio capture, and GLSL shaders. The codebase is small (~1,700 LOC) and readable.

The most serious issue is a broken trap handler in collage mode that references a non-existent function (`kill_floats` instead of `kill_tiles`), which means Ctrl+C in collage mode will fail to clean up processes. There is also a command injection vulnerability in the GTK control panel where mpv socket paths are passed unsanitized into a `bash -c` subprocess. The float-drift.sh script spawns a python3 subprocess on every animation frame (~20fps) just for sine math, which is wasteful.

Overall the project is solid for a personal desktop tool. The fixes below address all findings.

## SEVERITY CLASSIFICATION
- **CRITICAL**: Security vulnerabilities, data loss risks, breaking bugs
- **HIGH**: Significant bugs, reliability issues, major gaps
- **LOW**: Style issues, minor improvements, nice-to-haves
- **INFO**: Observations, architectural notes

## FINDINGS BY SEVERITY

### CRITICAL FINDINGS

**C1. Broken trap handler in collage mode** -- `float:453`
The collage mode trap handler calls `kill_floats` which does not exist. The correct function is `kill_tiles` or `stop_all`. This means Ctrl+C during collage mode will produce an error and fail to clean up xwinwrap/mpv processes.
```bash
# CURRENT (broken):
trap 'kill_floats; rm -f "$COLLAGE_CONTROLLER_PID" "$AUDIO_PULSE_PID"; ...'
# FIX:
trap 'stop_all; echo ""; echo "float stopped."; exit 0' SIGINT SIGTERM
```

**C2. Command injection in float-control.py** -- `scripts/float-control.py:187-191`
Socket paths are interpolated directly into a `bash -c` string without escaping. A malicious socket filename could execute arbitrary commands.
```python
# CURRENT (vulnerable):
subprocess.run(["bash", "-c", f"echo '{cmd}' | socat - {sock}"], ...)
# FIX: Use subprocess with proper argument passing
subprocess.run(["socat", "-", sock], input=cmd.encode(), ...)
```

### HIGH FINDINGS

**H1. float-drift.sh spawns python3 every frame** -- `scripts/float-drift.sh:16-17,35-36`
Spawns 4 python3 subprocesses for initial random values and 2 per frame (~20fps) just for sine/int math. At 20fps that is 40 python3 process spawns per second per window. Should use `bc` or precomputed values.

**H2. No error handling in main float script** -- `float`
The main script has no `set -e` or `set -o pipefail`. Silent failures can leave orphaned processes or partial state.

**H3. Bare except in float-control.py** -- `scripts/float-control.py:26`
`except:` catches SystemExit and KeyboardInterrupt, masking real errors.
```python
# CURRENT:
except:
    pass
# FIX:
except (OSError, ValueError):
    pass
```

**H4. fetch-freshluts.sh shell injection via URL encoding** -- `scripts/fetch-freshluts.sh:32`
Continuation token from S3 response is interpolated into a python3 -c command without quoting. A crafted S3 response could inject shell commands.
```bash
# CURRENT:
encoded_token=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$continuation_token', safe=''))")
# FIX: Pass via stdin
encoded_token=$(echo "$continuation_token" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))")
```

**H5. install.sh no cleanup on failure** -- `install.sh:29-35`
Temp directory created with mktemp but no trap handler for cleanup on failure. If the build fails, temp files remain.

### MEDIUM FINDINGS

**M1. PCRE grep not portable** -- `float:89,465`
`grep -oP '\d+x\d+\+\d+\+\d+'` uses PCRE (-P) which is not available on all systems (notably macOS). Should use `-E` with POSIX ERE.

**M2. Settings file values not validated** -- `float:342-356`
`read_settings()` reads key=value pairs but does not validate values. Non-numeric opacity or panscan values would cause downstream errors.

**M3. Hardcoded audio source fallback** -- `scripts/audio-pulse.py:64`
Falls back to `alsa_output.pci-0000_00_1f.3.analog-stereo.monitor` which is device-specific.

**M4. Magic numbers in float-control.py** -- `scripts/float-control.py:158-159`
Cairo operators `0` and `2` are magic numbers. Should use `cairo.OPERATOR_CLEAR` and `cairo.OPERATOR_OVER`.

**M5. xdpyinfo parsing fragile** -- `float:438-439`
Screen dimensions extracted via `xdpyinfo | grep dimensions | awk ...` pipeline. Could fail if xdpyinfo output format changes.

**M6. Shuffle defaults to yes** -- `float:397`
`SHUFFLE="yes"` is the default even without the --shuffle flag. This may be intentional but is undocumented in the help text.

### LOW FINDINGS

**L1. No readonly on constants** -- `float:22-30`
Script-level constants (PIDFILE, PLAYLIST_BASE, VIDEO_EXTENSIONS, etc.) should be declared readonly.

**L2. Undocumented positional parameter trick** -- `float:159`
`_ WID` at the end of the bash -c command is a positional parameter assignment trick. Should have a comment.

**L3. Missing type hints** -- `scripts/float-control.py`
No type hints on any methods or functions.

**L4. Global mutable state in audio-pulse.py** -- `scripts/audio-pulse.py:36-44`
Global variables for smoothing state and energy history. Should be encapsulated.

**L5. No shebang line specificity** -- `float:1`
Uses `#!/bin/bash` which is fine for Linux but should note bash 4+ requirement (uses associative-array-like constructs).

### INFORMATIONAL NOTES

**I1.** The dream-collage.lua file is well-structured with clean mode separation and good use of prime-ish cycle periods.

**I2.** The audio-pulse.py frequency band separation is approximate but documented as intentional (avoiding numpy dependency).

**I3.** The rounded-corners.glsl shader includes dither noise to prevent banding, which shows attention to visual quality.

**I4.** Process cleanup uses both targeted PID-based kill and broad pkill patterns as defense-in-depth. This is reasonable for a desktop tool.

## REMEDIATION LOG

**Remediation Date:** 2026-03-14
**Total Findings:** 17 (C:2, H:5, M:6, L:5)
**Findings Fixed:** 17/17

### Fixed Findings
| ID | Severity | Finding | Fix Applied |
|----|----------|---------|-------------|
| C1 | CRITICAL | Broken trap handler calls kill_floats | Changed to stop_all |
| C2 | CRITICAL | Command injection in float-control.py | Replaced bash -c with direct socat subprocess |
| H1 | HIGH | float-drift.sh spawns python3 every frame | Rewrote to use bc for math |
| H2 | HIGH | No error handling in float script | Added set -e where safe |
| H3 | HIGH | Bare except in float-control.py | Changed to except (OSError, ValueError) |
| H4 | HIGH | Shell injection in fetch-freshluts.sh | Pass token via stdin to python3 |
| H5 | HIGH | install.sh no cleanup trap | Added trap for temp dir cleanup |
| M1 | MEDIUM | PCRE grep not portable | Changed -oP to -oE with POSIX regex |
| M2 | MEDIUM | Settings values not validated | Added numeric validation |
| M3 | MEDIUM | Hardcoded audio source fallback | Made generic with default sink |
| M4 | MEDIUM | Magic numbers in cairo operators | Added comments with operator names |
| M5 | MEDIUM | xdpyinfo parsing fragile | Added fallback to xrandr |
| M6 | MEDIUM | Shuffle defaults to yes undocumented | Updated help text |
| L1 | LOW | Constants not readonly | Added readonly declarations |
| L2 | LOW | Undocumented positional trick | Added comment |
| L3 | LOW | Missing type hints | Added type hints to public methods |
| L4 | LOW | Global mutable state | Moved into main() scope |
| L5 | LOW | No bash version note | Added comment |
