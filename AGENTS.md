# AGENTS.md — Float Codebase Guide for AI Agents

## Start Here

Read `float` (the main bash script) first. It's the entry point for everything — CLI parsing, process spawning, IPC dispatch, config loading. Understanding it tells you how all the other components fit together.

Then read `scripts/dream-collage.lua` to understand the visual effects layer. This is where the 7 visual modes live, where audio reactivity is implemented, and where LUT rotation happens. Most visual behavior questions are answered here.

## File Reading Order

1. `float` — orchestration, CLI, process lifecycle
2. `scripts/dream-collage.lua` — visual effects, modes, audio integration
3. `scripts/audio-pulse.py` — audio capture daemon (read if touching audio reactivity)
4. `scripts/float-control.py` — GTK panel (read if touching the GUI)
5. `install.sh` — build/install process (read if touching setup or dependencies)

## Key Files Summary

| File | What it does |
|------|-------------|
| `float` | Main bash script. CLI parsing, xwinwrap/mpv spawning, IPC, config. |
| `scripts/dream-collage.lua` | mpv Lua script. Visual modes, audio reactivity, LUT cycling. |
| `scripts/audio-pulse.py` | Daemon that captures system audio and feeds amplitude data to the Lua script. |
| `scripts/float-control.py` | GTK3 floating panel. Sends commands to mpv via IPC sockets. |
| `scripts/float-drift.sh` | Moves the xwinwrap window slowly over time for a drifting effect. |
| `scripts/rounded-corners.glsl` | GLSL shader loaded by mpv to round video corners. |
| `scripts/fetch-freshluts.sh` | Downloads .cube LUT files from S3. Only runs on demand. |
| `install.sh` | Builds xwinwrap from source, installs the float symlink. |

## Testing

Float is a visual tool with no automated test suite. Validation is manual:

```bash
# Start playback and visually confirm video appears as wallpaper
float /path/to/videos/ --collage --shuffle

# Confirm the control panel opens
float --control

# Confirm IPC works (next/prev should cycle videos)
float --next
float --prev

# Clean shutdown — verify all xwinwrap/mpv processes are gone
float --stop
ps aux | grep -E 'xwinwrap|mpv' | grep -v grep
```

After stopping, `/tmp/float.pids` should be gone or empty and no mpv/xwinwrap processes should remain. If they do, there's a cleanup bug.

To test audio reactivity: play something through your speakers or headphones while float is running. Visual effects should pulse or shift in response to the audio. If they don't, check that `audio-pulse.py` started (look for its PID in `/tmp/float.pids` or check `pgrep -f audio-pulse`).

## Conventions

**Bash (`float`, `float-drift.sh`, `install.sh`, `fetch-freshluts.sh`):**
- Functions use `lowercase_snake_case`
- Variables are `ALL_CAPS` for globals, `lowercase` for locals
- Cleanup and error handling go through `trap` at the top of the main script

**Python (`audio-pulse.py`, `float-control.py`):**
- Follows PEP 8
- Class names are `PascalCase`, functions and variables are `snake_case`

**Lua (`dream-collage.lua`):**
- mpv script conventions: use `mp.add_periodic_timer` for loops, `mp.get_property` / `mp.set_property` for mpv state
- Effect modes are `elseif` branches inside the `update()` function, keyed on `current_mode`

## What NOT to Touch Without Testing

**xwinwrap flags** — the combination of `-fdt -ni -b -nf -un` is fragile. These flags control fullscreen-desktop-type, no-input (click-through), below-desktop, no-focus, and un-redirect. Changing them without testing on your specific compositor/WM will almost certainly break the wallpaper behavior.

**IPC socket paths** — `/tmp/mpv-float-*.sock` is referenced in the `float` bash script (creation and dispatch), in `float-control.py` (connection), and must be reachable by `socat` commands. If you rename or relocate sockets, update every reference.

**mpv `--script=` invocation** — `dream-collage.lua` is loaded via the `--script=` flag in the xwinwrap launch command. If you rename the Lua file or move it, update the path in `float`.

**PID file at `/tmp/float.pids`** — `float --stop` reads this to kill processes. If you change how PIDs are written or where the file lives, `--stop` will stop working and you'll need to kill processes manually.

## Adding a New Visual Mode

1. Add the mode name to the `modes` table at the top of `dream-collage.lua`
2. Add an `elseif current_mode == "yourmode" then` block in the `update()` function
3. Set zoom, pan_x, pan_y, hue, sat, bright, contrast, spd, rotation values with audio modulation
4. The mode will be auto-selected by the random mode picker

## Adding a New CLI Flag

1. Parse it in the argument-parsing section of the `float` bash script
2. Pass it through to xwinwrap/mpv as needed (via `--mpv-options` or a custom env var the Lua script reads)
3. Document it in the usage/help output inside `float`
