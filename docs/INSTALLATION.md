# Installation

## Prerequisites

Float requires an **X11 session**. It does not work on Wayland. If you are running a Wayland compositor, switch to an X11 session or use XWayland (results may vary with xwinwrap).

### Required packages

```bash
sudo apt install mpv x11-xserver-utils build-essential git socat python3 python3-gi
```

| Package | Why |
|---------|-----|
| `mpv` | Video decoder and renderer |
| `x11-xserver-utils` | Provides `xrandr` for monitor detection |
| `build-essential` | gcc + make to compile xwinwrap from source |
| `git` | Clones the xwinwrap repo during install |
| `socat` | Sends JSON IPC commands to running mpv instances |
| `python3` | Runs the audio daemon and GTK control panel |
| `python3-gi` | GTK3 Python bindings, needed for `--control` panel |

PulseAudio is required for audio reactivity. PipeWire with the PulseAudio compatibility layer (`pipewire-pulse`) also works — `parec` just needs to be available.

xwinwrap is **not** in any distro package manager. The install script builds it from source.

---

## Install

```bash
git clone https://github.com/sanchez314c/float.git
cd float
./install.sh
```

That's it. The installer handles xwinwrap and the float symlink.

### What install.sh does

1. Checks that `mpv`, `xrandr`, `git`, and `gcc` are present. Exits with an error if any are missing.
2. Clones `https://github.com/ujjwal96/xwinwrap` into a temp directory.
3. Runs `make` inside the cloned repo.
4. Copies the resulting `xwinwrap` binary to `/usr/local/bin/` (requires sudo).
5. Creates a symlink: `~/bin/float` pointing to the `float` script in your cloned repo.
6. Creates `~/bin/` if it does not exist.

After install, `~/bin/` must be on your `$PATH`. Most distros add it automatically if it exists. If `float` is not found after install, add this to `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

---

## Verification

```bash
float --help
```

This should print the usage block. If you get "command not found", check that `~/bin/` is on your path and that the symlink exists:

```bash
ls -la ~/bin/float
```

---

## Optional: Download LUTs

LUTs add color grading to the video effects. To download a collection of CC0-licensed LUTs from freshluts.com:

```bash
./scripts/fetch-freshluts.sh
```

By default this downloads into `~/Luts/freshluts/`. Point float at them with:

```bash
float ~/Videos --luts ~/Luts/freshluts
```

Or set it permanently in `~/.config/float/settings.conf`:

```
lut_dir=/path/to/luts
```

---

## First Run

```bash
float ~/Videos
```

Float will pick a random video from `~/Videos` and play it as your desktop wallpaper with the dream visual mode active. Press `Ctrl+C` in the terminal or run `float --stop` from another terminal to stop.
