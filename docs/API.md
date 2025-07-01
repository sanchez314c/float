# API Reference

## CLI

```
float <target> [options]
float --next | --prev | --stop | --list | --control
```

`<target>` is a path to a video file or a folder. If it's a folder, float scans it recursively for video files.

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--collage` | off | Tile multiple video instances in random layouts across the screen. 3-6 tiles, random size (25-60% screen width), random position, 30% chance of horizontal flip. Reshuffles every 25-75 seconds. 10% chance of a full-screen takeover for 8-16 seconds. |
| `--shuffle` | off | Randomize playlist order. |
| `--all` | off | Play on all connected monitors simultaneously. One mpv instance per monitor. |
| `--monitor N` | primary | Target a specific monitor by index (as reported by `xrandr --listmonitors`). |
| `--opacity VALUE` | 0.04 | Window opacity from 0.0 (invisible) to 1.0 (fully opaque). |
| `--luts /path` | none | Directory containing `.cube` or `.3dl` LUT files for color grading. |
| `--lut-interval N` | 20 | How often (in seconds) to rotate to a new LUT. |
| `--next` | — | Tell the running float to advance to the next video in the playlist. |
| `--prev` | — | Tell the running float to go back to the previous video. |
| `--stop` | — | Kill all running float processes and clean up temp files. |
| `--list` | — | Print all currently playing video files (reads /tmp/float.pids and queries each mpv). |
| `--control` | — | Launch the GTK3 floating control panel. |

### Settings File

`~/.config/float/settings.conf` stores persistent defaults. Format is `key=value`, one per line. CLI flags override settings file values.

```ini
opacity=0.04
lut_dir=/home/user/luts
lut_interval=20
panscan=1.0
```

Supported keys:

| Key | Description |
|-----|-------------|
| `opacity` | Default window opacity |
| `lut_dir` | Default LUT directory path |
| `lut_interval` | Default LUT rotation interval in seconds |
| `panscan` | mpv panscan value (how much the video can extend beyond window edges) |

---

## IPC Protocol

Each mpv instance opened by float creates a Unix domain socket at `/tmp/mpv-float-<n>.sock`. Commands are JSON objects sent over that socket.

mpv's IPC format:

```json
{"command": ["<command-name>", <arg1>, <arg2>]}
```

### Sending Commands

```bash
# Next video in playlist
echo '{"command":["playlist-next"]}' | socat - /tmp/mpv-float-1.sock

# Previous video in playlist
echo '{"command":["playlist-prev"]}' | socat - /tmp/mpv-float-1.sock

# Set a property
echo '{"command":["set_property","speed",1.5]}' | socat - /tmp/mpv-float-1.sock

# Get a property
echo '{"command":["get_property","filename"]}' | socat - /tmp/mpv-float-1.sock
```

Multiple sockets may be active when collage mode or `--all` is in use. Run `ls /tmp/mpv-float-*.sock` to see which are open.

---

## Inter-Process Files

These temp files are the shared state between float components.

### /tmp/float-audio

Written by `audio-pulse.py` at ~30fps. Read by `dream-collage.lua` at ~15fps.

Format: space-separated floats on a single line.

```
<energy> <bass> <mid> <high> <beat>
```

| Field | Range | Description |
|-------|-------|-------------|
| `energy` | 0.0-1.0+ | Overall RMS amplitude of the current audio chunk |
| `bass` | 0.0-1.0+ | Low-frequency energy (low-pass moving average of energy) |
| `mid` | 0.0-1.0+ | Mid-frequency energy (energy minus bass minus high) |
| `high` | 0.0-1.0+ | High-frequency energy (difference filter output) |
| `beat` | 0 or 1 | 1 when a beat is detected (energy spike above rolling average threshold) |

### /tmp/float-luts.list

Written by `float` at startup when `--luts` is provided. Read by `dream-collage.lua` for LUT rotation.

Format: one absolute file path per line. Only `.cube` and `.3dl` files are included.

```
/home/user/luts/cinematic.cube
/home/user/luts/warm.cube
/home/user/luts/fade.3dl
```

### /tmp/float-lut-interval

Written by `float`. Read by `dream-collage.lua`.

Format: single integer (seconds between LUT rotations).

```
20
```

### /tmp/float.pids

Written by `float` as it spawns xwinwrap processes. Read by `float --stop` and `float --list`.

Format: one PID per line.

```
12345
12346
12347
```

### /tmp/float-opacity

Written by `float` and updated by `float-control.py` when opacity is changed via the GUI.

Format: single float.

```
0.04
```

### /tmp/float-audio-pulse.pid

Written by `float` when it starts `audio-pulse.py`. Used by `float --stop` to kill the daemon.

Format: single integer PID.

### /tmp/float-collage.pid

Written by `float` when it starts the collage reshuffle background loop. Used by `float --stop`.

Format: single integer PID.
