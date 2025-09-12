# Float Changelog

## 2026-03-14 01:30 — Repo Prep + Forensic Audit Remediation

### Repo Prep (Phase 1)
- Created .editorconfig, .python-version (3.11)
- Created run-source-linux.sh, run-source-mac.sh, run-source-windows.bat
- Created resources/icons/, tests/ with .gitkeep
- Updated .gitignore (4 patterns to 30+ standard patterns)
- Moved 3 .backup files to AI-Pre-Trash

### Audit Fixes (Phase 2)
- CRITICAL: Fixed broken trap handler in collage mode (kill_floats → stop_all)
- CRITICAL: Fixed command injection in float-control.py (bash -c → direct socat subprocess)
- HIGH: Rewrote float-drift.sh to use bc instead of spawning python3 every frame
- HIGH: Fixed bare except clause in float-control.py
- HIGH: Fixed shell injection in fetch-freshluts.sh URL encoding
- HIGH: Added trap cleanup handler to install.sh
- MEDIUM: Changed grep -oP (PCRE) to -oE (POSIX ERE) for portability
- MEDIUM: Added numeric validation to settings.conf reader
- MEDIUM: Fixed hardcoded audio source fallback to generic default.monitor
- MEDIUM: Added operator name comments to cairo magic numbers
- MEDIUM: Updated help text to document shuffle default behavior
- LOW: Added readonly to script constants
- LOW: Added explanatory comment for xwinwrap flag combination and WID trick

## 2026-03-14 01:20 — Documentation Standardization

- Renamed `changelog.md` to `CHANGELOG.md`
- Created 26 standard documentation files:
  - Root: README.md, CONTRIBUTING.md, LICENSE, CODE_OF_CONDUCT.md, SECURITY.md, CLAUDE.md, AGENTS.md, VERSION_MAP.md
  - GitHub templates: .github/ISSUE_TEMPLATE/bug_report.md, .github/ISSUE_TEMPLATE/feature_request.md, .github/PULL_REQUEST_TEMPLATE.md
  - Docs: README.md, ARCHITECTURE.md, INSTALLATION.md, DEVELOPMENT.md, API.md, BUILD_COMPILE.md, DEPLOYMENT.md, FAQ.md, TROUBLESHOOTING.md, TECHSTACK.md, WORKFLOW.md, QUICK_START.md, LEARNINGS.md, PRD.md, TODO.md
- All documentation derived from actual source code analysis, no boilerplate

## 2026-03-09 18:45 — Audio Reactive + LUT Rotation

- Audio-reactive mode: captures system audio via PulseAudio/PipeWire monitor source
  - Real-time RMS energy, bass/mid/high frequency bands, beat detection
  - Each visual mode reacts differently to audio (bass pumps zoom, beats flash brightness, etc.)
  - audio-pulse.py daemon auto-starts/stops with float
- LUT rotation: randomly cycles through .cube/.3dl/.png LUT files during playback
  - Configure via settings.conf (`lut_dir=`, `lut_interval=`) or `--luts /path` flag
  - Shuffled order, re-shuffles after exhausting all LUTs
  - Settings file at ~/.config/float/settings.conf
- No-repeat shuffle: pre-shuffled playlists ensure every video plays once before looping
- Settings.conf support: persistent defaults for opacity, LUT dir, LUT interval, panscan

## 2026-03-09 — Initial Release

- Core desktop video wallpaper playback via xwinwrap + mpv
- Recursive folder scanning for video files (mp4, mkv, avi, webm, mov, flv, wmv, m4v)
- Adjustable opacity (0.0-1.0) for blending over desktop wallpaper
- Shuffle mode for randomized playlist order
- Multi-monitor support (--all, --monitor N)
- Dream collage lua engine with 7 visual modes:
  - dream: gentle zoom, drift, color shift, speed wobble
  - drift: heavy Ken Burns panning
  - pulse: color and brightness pumping
  - chaos: everything cranked
  - calm: subtle breathing
  - vortex: deep zoom with spiral pan
  - glitch: sudden random jumps
- Collage mode: random 1-6 tile layouts that reshuffle every 15-45 seconds
- Layout types: fullscreen, split, 2x2, big+small, center+corners, 3x2, random scatter
- Install script with automatic xwinwrap build from source
