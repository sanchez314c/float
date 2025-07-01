# Architecture

## System Overview

Float is a bash script that acts as the main orchestrator. It does not render anything itself. It builds playlists, detects monitor geometry, spawns xwinwrap+mpv processes per tile or monitor, manages their PIDs, and controls their lifecycle.

Audio reactivity runs through a separate Python daemon (`audio-pulse.py`) that writes floating-point values to a temp file. The Lua script running inside mpv reads that file independently on its own timer.

Everything communicates through temp files and mpv's built-in JSON IPC over Unix sockets.

---

## Component Diagram

```
float (bash orchestrator)
│
├── spawns ──► xwinwrap
│                └── hosts ──► mpv
│                               ├── dream-collage.lua   (visual effects engine)
│                               └── rounded-corners.glsl (GPU shader via mpv hook)
│
├── spawns ──► audio-pulse.py
│                └── writes ──► /tmp/float-audio
│                                    ▲
│                                    └── read by dream-collage.lua (every ~15 fps)
│
├── spawns (on --control) ──► float-control.py (GTK3 panel)
│                               └── sends JSON IPC ──► /tmp/mpv-float-*.sock
│
├── reads/writes ──► /tmp/float.pids
├── reads/writes ──► /tmp/float-opacity
├── reads ──────► /tmp/float-luts.list
└── reads ──────► ~/.config/float/settings.conf
```

---

## Data Flow

### Audio Reactivity

1. `audio-pulse.py` opens a `parec` subprocess to capture the PulseAudio monitor source (system audio output, looped back for capture).
2. For each audio chunk it computes: RMS energy, bass (low-pass moving average), highs (difference filter), mid (energy minus bass minus highs), beat (energy spike vs rolling average threshold).
3. Writes five space-separated floats to `/tmp/float-audio` atomically via a temp file + rename (~30 times per second).
4. `dream-collage.lua` runs an `mp.add_periodic_timer(1/15, ...)` callback inside mpv. Each tick it reads `/tmp/float-audio`, parses the five values, and uses them to modulate mpv playback properties.

### Video Rendering

1. `float` calls `xwinwrap` with geometry and flags (`-b` below desktop, `-ni` no input, `-s` sticky, `-nf` no focus).
2. xwinwrap places a bare X window at those coordinates and execs mpv inside it.
3. mpv loads the video file, the Lua user script (`dream-collage.lua`), and the GLSL hook shader (`rounded-corners.glsl`).
4. The Lua script calls `mp.set_property_number()` every frame tick to drive zoom, pan, hue, saturation, brightness, contrast, and speed.
5. The GLSL shader runs as an mpv output hook, applying rounded corners (28px radius) and a feathered edge fade (120px) to the final rendered frame.

### LUT Rotation

1. `float` scans the LUT directory, writes matching `.cube` and `.3dl` paths to `/tmp/float-luts.list` (one path per line).
2. It writes the rotation interval in seconds to `/tmp/float-lut-interval`.
3. `dream-collage.lua` reads both files on a timer, picks a random LUT from the list, and applies it via mpv's `vf` (video filter) property using the `lut3d` filter.

---

## IPC

mpv exposes a JSON IPC socket at `/tmp/mpv-float-<n>.sock` for each instance, where `<n>` matches the xwinwrap process index.

Commands are sent using `socat`:

```bash
echo '{"command":["playlist-next"]}' | socat - /tmp/mpv-float-1.sock
```

`float-control.py` uses Python's `socket` module to connect to the same socket and send the same JSON format.

`float --next`, `float --prev`, and `float --stop` all use socat internally to send IPC commands to every active socket.

---

## Process Lifecycle

1. `float` is called with a video path or folder.
2. It reads `~/.config/float/settings.conf` and merges CLI flags (CLI wins on conflict).
3. It reads `/tmp/float.pids` and kills any existing float processes to avoid stacking.
4. It starts `audio-pulse.py` in the background. The daemon PID goes to `/tmp/float-audio-pulse.pid`.
5. It resolves monitor geometry via `xrandr --listmonitors` output.
6. It builds a playlist from the target path (recursive find for video files, shuffle if `--shuffle`).
7. For each tile or monitor, it assembles the xwinwrap+mpv command and spawns it. Each spawned xwinwrap PID is appended to `/tmp/float.pids`.
8. In collage mode, a reshuffle loop runs in the background; its PID goes to `/tmp/float-collage.pid`.
9. On `float --stop`, all PIDs in `/tmp/float.pids`, the audio daemon PID, and the collage PID are killed. Temp files are cleaned up.

---

## Design Decisions

**xwinwrap**: Provides a bare X window that can be positioned below the desktop, be click-through (`-ni`), and stay on all workspaces (`-s`). It execs any program inside itself, making mpv the actual renderer without needing custom window management code.

**mpv**: Hardware-accelerated video decode (`hwdec=auto`), scriptable via Lua user scripts, accepts real-time property changes through the Lua API and JSON IPC, supports GLSL output hooks. All of that in one binary.

**Lua for effects**: mpv's Lua scripting API gives direct access to playback properties with no IPC round-trip overhead. The effect loop runs inside mpv's event loop, so changes take effect on the next rendered frame.

**GLSL shader**: Rounded corners and edge feathering require per-pixel blending that would be too slow in Lua or bash. mpv's GLSL hook system runs the shader on the GPU as part of the render pipeline.

**Temp files for audio**: The audio daemon and the Lua script run in different processes with different runtimes (Python vs Lua/C). A shared temp file is the simplest cross-process channel with no socket setup or serialization overhead. Atomic rename prevents partial reads.
