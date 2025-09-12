# Float

Play videos as translucent animated wallpaper on Linux with real-time visual effects and audio-reactive modulation.

Float runs videos under your desktop using xwinwrap and mpv. It applies sinusoidal visual effects (zoom, pan, hue, saturation, brightness, contrast, speed) that cycle through 7 named modes, reacts to your system audio output in real time, rotates through LUT color grades, and tiles multiple videos across monitors in collage mode. A small GTK3 panel lets you skip tracks and scrub opacity without touching a terminal.

---

## Install

```bash
git clone https://github.com/sanchez314c/float.git
cd float
./install.sh
```

The installer checks for dependencies, builds xwinwrap from source, and symlinks `float` into `~/bin/`.

---

## Usage

```bash
float /path/to/videos                   # Play on primary monitor
float /path/to/videos --collage         # Tiled collage that reshuffles on loop
float /path/to/videos --all             # Play on every connected monitor
float /path/to/videos --shuffle         # Randomize playlist order
float /path/to/videos --opacity 0.04   # Set translucency (0.0 - 1.0)
float /path/to/videos --luts /my/luts  # Rotate through a LUT folder
float --next                            # Skip to next video (all tiles)
float --prev                            # Go back one video
float --stop                            # Kill everything
float --control                         # Open GTK control panel
float --list                            # Show running instances
```

Config lives at `~/.config/float/settings.conf`.

---

## Documentation

See the [docs/](docs/) folder for full documentation including visual mode details, audio-reactive behavior, LUT setup, and IPC socket reference.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT. Copyright (c) 2026 Jason Paul Michaels. See [LICENSE](LICENSE).

**Author**: J. Michaels — [github.com/sanchez314c](https://github.com/sanchez314c)
