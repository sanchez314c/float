# Troubleshooting

## xwinwrap: command not found

Run `./install.sh`. It checks for xwinwrap, builds it from source, and symlinks it to `~/bin/`. If you want to build it manually: clone from `github.com/ujjwal96/xwinwrap`, install `libx11-dev` and `libxext-dev`, then run `gcc -o xwinwrap xwinwrap.c -lX11 -lXext`.

## No video files found in: /path

Float scans for files with these extensions: `mp4 mkv avi webm mov flv wmv m4v`. If your files use a different format (e.g., `.ts`, `.mpg`), they won't be picked up. Check the path and that your files match one of those extensions.

## Monitor N not found

Run `xrandr --current` to see which monitors are connected and their names. Float numbers them by X position (leftmost = 0). If you have 2 monitors, valid values are `--monitor 0` and `--monitor 1`. Disconnected monitors in xrandr output don't count.

## Videos play but no audio reactivity

The audio daemon needs a running PulseAudio or PipeWire session with a monitor source active. Check:

```bash
pactl list short sources
```

You're looking for a source that ends in `.monitor` and shows status `RUNNING`. If all monitor sources show `IDLE`, that means no audio is currently playing from the system. Start playing any audio and the reactivity will kick in. If no monitor sources appear at all, PulseAudio/PipeWire may not be running.

## float --stop doesn't kill everything

Occasionally orphaned mpv or xwinwrap processes survive. Kill them manually:

```bash
pkill -9 -f "xwinwrap.*mpv"
```

You can confirm nothing's left with `pgrep -a xwinwrap`.

## Control panel won't launch

The control panel (`float --control`) needs `python3-gi` for GTK3 bindings. Install it:

```bash
sudo apt install python3-gi gir1.2-gtk-3.0
```

## Videos look stretched or cropped wrong

The `panscan` setting in `~/.config/float/settings.conf` controls how mpv fills the window. Default is `0.5`.

- `panscan=0` — letterbox/pillarbox, no cropping
- `panscan=0.5` — moderate crop-to-fill (default)
- `panscan=1` — full crop-to-fill, maximizes coverage

Edit the value and restart Float to apply.

## High CPU usage

mpv may be decoding in software. Check what hardware decode backends are available:

```bash
mpv --hwdec=help
```

Then install the appropriate driver for your GPU:

- Intel: `sudo apt install intel-media-va-driver`
- AMD: `sudo apt install mesa-va-drivers`
- NVIDIA: `sudo apt install nvidia-vaapi-driver` (or use vdpau)

Float passes `--hwdec=auto` to mpv, so once drivers are installed, hardware decoding activates automatically.

## LUTs not applying

LUT files must be `.cube` or `.3dl` format. Verify the path you're passing contains valid files:

```bash
ls /your/lut/path/*.cube /your/lut/path/*.3dl
```

You can also use `--luts /path` to point at a directory, or run `scripts/fetch-freshluts.sh` to download a set of CC0-licensed LUTs automatically.
