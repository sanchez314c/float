# Tech Stack

## Bash

The main `float` script is a bash shell script. No compilation, no dependencies beyond what's already on any Linux desktop. Bash handles CLI parsing, playlist building, xrandr monitor detection, spawning and tracking child processes, and IPC via socat. Direct shell scripting was the right call here because the whole job is wiring together external tools, not building logic.

## mpv

The video playback engine. mpv does most of the heavy lifting: hardware-accelerated decoding (`--hwdec=auto`), embedded rendering into an X11 window ID (`--wid`), a Lua user script API with direct access to video properties (zoom, pan, hue, brightness, contrast, speed), a GLSL shader hook system, and a JSON IPC protocol over Unix sockets. Nothing else on Linux gives you all of that in one package.

## xwinwrap

An X11 utility that wraps another window and makes it sit below the desktop, click-through, and borderless. Built from source from `github.com/ujjwal96/xwinwrap` because most distros don't package it. The combination of flags Float uses (`-fdt -ni -b -nf -un`) is specific to getting the right behavior. See the LEARNINGS doc for why those flags matter.

## Lua (via mpv)

All real-time visual effects live in `scripts/dream-collage.lua`. mpv loads Lua scripts natively and gives them direct access to player properties. This means zoom, pan, hue shift, brightness, contrast, playback speed, and more can all be modulated in real time without touching the video file or spawning extra processes. The 7 visual modes (dream, drift, pulse, chaos, calm, vortex, glitch) are all Lua.

## GLSL (via mpv)

`scripts/rounded-corners.glsl` is a custom GLSL hook that mpv runs on the GPU for every frame. It applies rounded corners with feathered edges and adds subtle dithering to prevent banding. mpv's shader hook system makes this straightforward: write a valid hook, reference it with `--glsl-shader`, and it runs.

## Python 3

Used for two things:

**Audio capture daemon** (`scripts/audio-pulse.py`) — Reads raw PCM from PulseAudio's monitor source via `parec`, computes RMS energy, frequency bands (bass/mid/high), and beat detection. No numpy. Frequency separation is done with a moving-average + difference filter. Results are written to `/tmp/float-audio` as plain text using atomic file replacement.

**Control panel** (`scripts/float-control.py`) — A floating GTK3 window with prev/next track buttons and an opacity slider. Transparent and draggable. Communicates with running mpv instances via the same IPC sockets as the main script.

## GTK3 (via python3-gi)

Used for the control panel UI. GTK3 supports RGBA visuals, which is what makes the transparent floating window work. `python3-gi` is the standard GObject Introspection binding for Python on Linux desktops.

## PulseAudio / PipeWire

Audio capture is done with `parec`, which reads raw PCM from a monitor source (the loopback of your system audio output). PipeWire's PulseAudio compatibility layer works the same way, so Float works on both. The daemon queries `pactl` to find the right monitor source and falls back to `default-sink.monitor` when nothing is explicitly running.

## socat

Used to send JSON commands to mpv's Unix socket IPC interface. Commands like `playlist-next`, `playlist-prev`, and property changes all go through socat. It's a one-liner tool for this: `echo '{"command":["..."]}' | socat - UNIX-CONNECT:/tmp/float-ipc-N`.

## xrandr

Monitor detection. Float reads `xrandr --current` output to get connected monitor names, positions, and resolutions. Monitors are sorted by X position so `--monitor 0` is always the leftmost one.

## xdotool

Window positioning for the drift effect (`scripts/float-drift.sh`). Used to move the xwinwrap window in a sine wave pattern over time.

## xdpyinfo

Reads total desktop dimensions for collage mode. Float uses this to calculate tile placement across the full desktop, not just one monitor.

## xprop

Sets `_NET_WM_WINDOW_OPACITY` on the xwinwrap windows at runtime to apply opacity without restarting mpv.
