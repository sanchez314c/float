# Contributing to Float

Thanks for taking the time. Here's how to contribute without stepping on anything.

---

## Before You Start

Open an issue first and describe what you want to change or fix. Reference that issue in your PR. This avoids wasted work if the change isn't a fit.

---

## Workflow

1. Fork the repo and clone your fork.
2. Create a branch off `main` with a short descriptive name:
   ```bash
   git checkout -b fix/collage-tile-overlap
   git checkout -b feat/wayland-support
   ```
3. Make your changes.
4. Test manually (see below).
5. Open a PR against `main`. Reference the issue number in the PR description.

---

## Dependencies

You need these installed before working on Float:

- `mpv` — video player and IPC backend
- `xwinwrap` — built from source by `install.sh`
- `xrandr` — monitor geometry detection
- `xdotool` — window positioning for drift animation
- `xdpyinfo` — display info
- `socat` — IPC socket communication
- `gcc` and `build-essential` — for building xwinwrap
- `git` — obviously
- `python3` — audio daemon and control panel
- `python3-gi` — GTK3 bindings for the control panel
- `pactl` / `parec` — PulseAudio/PipeWire audio capture

---

## Code Conventions

### Bash (`float`, `install.sh`, `scripts/float-drift.sh`, `scripts/fetch-freshluts.sh`)

- Function names: `lowercase_snake_case`
- Indent: 4 spaces, no tabs
- Quote all variable expansions: `"$var"` not `$var`
- Local variables in functions: `local var_name`
- Check return codes on anything that can fail

### Python (`scripts/audio-pulse.py`, `scripts/float-control.py`)

- Follow PEP 8
- Indent: 4 spaces
- Keep functions short and single-purpose
- Use `if __name__ == "__main__":` guards on all scripts

### Lua (`scripts/dream-collage.lua`)

- Local variables: `snake_case`
- Indent: 4 spaces
- Avoid globals; scope everything with `local`
- Comment non-obvious math (the sinusoidal modulation especially)

### GLSL (`scripts/rounded-corners.glsl`)

- Follow the existing style in the file
- Comment any new parameter or effect clearly

---

## Testing

There's no automated test suite. Test manually:

```bash
# Basic playback
float /path/to/videos

# Collage mode with shuffle
float /path/to/videos --collage --shuffle

# All monitors
float /path/to/videos --all --opacity 0.05

# IPC commands
float --next
float --prev
float --stop

# Control panel
float --control
```

Check that:
- `float --list` shows the right PIDs
- `float --stop` kills all xwinwrap and mpv processes cleanly
- The GTK panel opens, drags, and opacity scrub works
- Audio reactivity kicks in when audio is playing

---

## What We're Not Looking For

- Wayland-specific rewrites (not in scope yet)
- Swapping out core dependencies (mpv, xwinwrap)
- Changes that require root to run
- Features that only work on one distro

If you're unsure, open an issue and ask first.
