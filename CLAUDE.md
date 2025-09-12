# Float — AI Assistant Context

## What This Is

Float plays videos as translucent animated wallpaper on Linux. It sits below the desktop layer using xwinwrap + mpv, applies real-time visual effects via a Lua script, and modulates those effects based on system audio output. The result is a living, audio-reactive desktop background.

## Tech Stack

- **Bash** — main entry point, process orchestration, CLI parsing
- **Python 3** — audio capture daemon (PulseAudio/PipeWire) and GTK3 control panel
- **Lua** — mpv script that implements 7 visual effect modes and audio reactivity
- **GLSL** — rounded corner shader loaded by mpv
- **xwinwrap** — wraps mpv so it renders into a desktop-layer window (must be built from source)
- **GTK3** — floating control panel GUI

## File Structure

```
float                          Main bash script — CLI entry point, process management, IPC dispatch
install.sh                     Installer — builds xwinwrap from source, symlinks float to ~/bin/
scripts/dream-collage.lua      mpv Lua script — 7 visual modes, audio reactivity, LUT rotation
scripts/audio-pulse.py         Audio capture daemon — reads PulseAudio/PipeWire monitor source
scripts/float-control.py       GTK3 control panel — floating UI for live effect control
scripts/float-drift.sh         Window drift animation — moves the xwinwrap window over time
scripts/rounded-corners.glsl   GLSL shader — rounds the corners of the video window
scripts/fetch-freshluts.sh     Downloads .cube LUT files from S3 for color grading
```

## Key Commands

```bash
# Install (builds xwinwrap, sets up symlink)
./install.sh

# Play a single video
float /path/to/video.mp4

# Play all videos in a folder, shuffled, collage layout
float /path/to/videos/ --collage --shuffle

# Target a specific monitor (zero-indexed)
float /path/to/video.mp4 --monitor 1

# Set opacity (0.0-1.0, default 0.04)
float /path/to/video.mp4 --opacity 0.08

# Open the GTK control panel
float --control

# Navigate tracks
float --next
float --prev

# Kill everything float started
float --stop

# List running float instances
float --list
```

## Architecture

The `float` bash script is the orchestrator. It:
1. Parses CLI args and reads `~/.config/float/settings.conf`
2. Spawns one or more `xwinwrap` processes, each wrapping an `mpv` instance
3. Passes `dream-collage.lua` to mpv via `--script=` so the Lua script loads at startup
4. Writes mpv process PIDs to `/tmp/float.pids` for later cleanup
5. Creates mpv IPC sockets at `/tmp/mpv-float-*.sock` for live control
6. Optionally starts `audio-pulse.py` as a background daemon — it captures system audio and writes amplitude data that `dream-collage.lua` polls to drive audio-reactive effects
7. Optionally starts `float-control.py` (GTK panel) and `float-drift.sh` (window drift)

`dream-collage.lua` handles all visual logic inside mpv. It cycles through 7 modes (dream, drift, pulse, chaos, calm, vortex, glitch), rotates LUT files for color grading, and reads audio data from the daemon to modulate effect intensity.

## Config File

Location: `~/.config/float/settings.conf`

```ini
opacity=0.04
lut_dir=/path/to/luts
lut_interval=20
panscan=0.5
```

Settings are read at startup. CLI flags override config values.

## Things to Watch Out For

**xwinwrap must be built from source.** There's no distro package. `install.sh` handles this, but if it fails (missing dependencies, wrong gcc version), float won't work at all. The binary ends up at `/usr/local/bin/xwinwrap`.

**PID management is file-based.** Running instances are tracked in `/tmp/float.pids`. If the file gets corrupted or float is killed hard (SIGKILL), stale xwinwrap/mpv processes may linger. `float --stop` reads that file to kill them.

**IPC sockets at `/tmp/mpv-float-*.sock`.** The `float` script sends commands (next, prev, property changes) over these sockets using `socat`. If you change socket paths, update every reference — in the bash script and the Lua script.

**Audio daemon is optional.** If `audio-pulse.py` fails to start (wrong PulseAudio sink name, PipeWire compatibility issue), float still runs — audio reactivity just won't work. The Lua script checks for data and falls back gracefully.

**Collage mode** spawns multiple mpv instances tiled across the screen. Each gets its own IPC socket. `--next` and `--prev` cycle all of them.
