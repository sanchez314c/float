# Development

## Environment

Float has no build step. The main script is bash, the effects engine is Lua (loaded by mpv at runtime), the audio daemon and control panel are Python, and the shader is GLSL (loaded by mpv at runtime). You need a text editor and the runtime deps from INSTALLATION.md.

No compilation, no virtual environments, no package managers beyond system apt packages.

---

## Project Structure

```
float/
├── float                       # Main orchestrator (bash, ~485 lines)
├── install.sh                  # Dep check + xwinwrap build + symlink
├── scripts/
│   ├── dream-collage.lua       # mpv Lua visual effects engine
│   ├── audio-pulse.py          # PulseAudio capture daemon
│   ├── float-control.py        # GTK3 floating control panel
│   ├── float-drift.sh          # Sine-wave window position drift
│   ├── rounded-corners.glsl    # GLSL rounded corner + edge fade shader
│   └── fetch-freshluts.sh      # CC0 LUT batch downloader
└── docs/                       # This documentation
```

The `float` script is the entry point for everything. It calls into the other scripts as subprocesses.

---

## How to Test Changes

Run float against a video folder and watch the output:

```bash
float ~/Videos --collage
```

To stop:

```bash
float --stop
```

For Lua script changes (`dream-collage.lua`), you do not need to restart the entire session — mpv picks up the script fresh each time you restart float. Kill the current session with `float --stop`, then start again.

For audio daemon changes (`audio-pulse.py`), same approach: stop float, edit, restart.

To see what the audio daemon is writing:

```bash
watch -n 0.1 cat /tmp/float-audio
```

To see active mpv sockets:

```bash
ls /tmp/mpv-float-*.sock
```

To test an IPC command manually:

```bash
echo '{"command":["playlist-next"]}' | socat - /tmp/mpv-float-1.sock
```

---

## Key Files to Understand

Start here, in this order:

1. **`float`** — Read the top of the file for config parsing and the main case statement for CLI args, then follow `start_float()` to understand how processes are spawned.
2. **`scripts/dream-collage.lua`** — The `modes` table defines all visual mode parameters. The `update()` function applies audio-reactive modulation. The `switch_mode()` function handles mode transitions.
3. **`scripts/audio-pulse.py`** — Short file. The main loop reads from parec, computes five values, writes to `/tmp/float-audio`.

The other scripts are shorter and self-contained.

---

## Adding a New Visual Mode

All visual modes live in `scripts/dream-collage.lua` in the `modes` table near the top of the file. Each entry looks like:

```lua
modes["mymode"] = {
    zoom_base = 1.0,
    zoom_amp = 0.02,
    pan_x_amp = 0.01,
    pan_y_amp = 0.01,
    hue_speed = 10,
    sat_base = 1.0,
    sat_amp = 0.05,
    bright_base = 0.0,
    bright_amp = 0.02,
    contrast_base = 1.0,
    contrast_amp = 0.01,
    speed_base = 1.0,
    speed_amp = 0.02,
}
```

Then add an `elseif` block in the `update()` function that reads the mode name and applies the audio-reactive math using the values you defined. Follow the pattern of the existing modes — they all use the same sinusoidal oscillation structure with audio values (energy, bass, mid, high, beat) read from the parsed `/tmp/float-audio` data.

The mode will be picked automatically by the mode-switcher since it reads from the `modes` table.

---

## Adding a CLI Flag

CLI flags are parsed in the `while [ $# -gt 0 ]` case statement near the top of the `float` script. To add a new flag:

1. Add a `--myflag)` case that sets a variable, e.g. `MY_FLAG=1; shift`.
2. Use the variable later in the script where relevant.
3. If the flag takes a value, use `--myflag) MY_VAL="$2"; shift 2`.

If the flag should also be readable from settings.conf, add a corresponding key to the config parsing block above the CLI argument loop. CLI values should override config file values.

---

## Code Style

| Language | Style |
|----------|-------|
| Bash | `lowercase_snake_case` for functions and variables, `UPPER_SNAKE_CASE` for constants |
| Python | PEP 8. No type annotations required but welcome. |
| Lua | `snake_case` for locals, same for functions. Keep the mpv timer callbacks short. |
| GLSL | Standard GLSL conventions. Comments explaining each effect step. |

Keep bash functions short and single-purpose. The existing `float` script is around 485 lines; avoid growing it significantly without splitting logic into helper functions.
