# FAQ

## Does it work on Wayland?

No. xwinwrap requires X11 to create below-desktop, click-through windows. Wayland does not expose the same low-level window positioning API.

If you are on a system running Wayland, you have two options: switch your session to X11 (usually available at the login screen as "GNOME on Xorg" or similar), or try running float under XWayland. XWayland runs X11 applications inside a Wayland session, but xwinwrap's below-desktop window stacking may not behave correctly depending on your compositor.

---

## Why is my CPU usage high?

mpv uses `hwdec=auto` which tries hardware video decoding first. If your GPU supports the codec your video uses (h264, hevc, av1, etc.), decoding happens on the GPU and CPU usage stays low.

If your GPU does not support hardware decode for that codec, mpv falls back to software decoding and CPU usage climbs. To check what hardware decode methods are available on your system:

```bash
mpv --hwdec=help
```

To force a specific method in float, set it in your mpv config at `~/.config/mpv/mpv.conf`:

```
hwdec=vaapi
```

Or to diagnose, run mpv directly on your video and watch the output:

```bash
mpv --hwdec=auto --vo=gpu your-video.mp4
```

In collage mode you are running 3-6 mpv instances simultaneously. Some CPU overhead is expected.

---

## Can I change the visual effects?

Yes. Edit `scripts/dream-collage.lua`. Each visual mode is defined in the `modes` table at the top of the file, and each mode's audio-reactive behavior is an `elseif` block in the `update()` function. The parameters control zoom, pan, hue, saturation, brightness, contrast, and playback speed, all driven by sinusoidal oscillation with audio modulation on top.

You can tune existing modes by changing their parameter values in the `modes` table, or add entirely new modes. See [DEVELOPMENT.md](DEVELOPMENT.md) for how to add a new mode.

---

## How do I add my own LUTs?

Put your `.cube` or `.3dl` LUT files in any folder you want. Then point float at that folder:

```bash
float ~/Videos --luts ~/my-luts
```

Or set it permanently in `~/.config/float/settings.conf`:

```
lut_dir=/home/user/my-luts
```

Float scans that directory at startup, writes the paths to `/tmp/float-luts.list`, and the Lua script inside mpv rotates through them on the `--lut-interval` timer (default 20 seconds).

You can also download a collection of CC0-licensed LUTs:

```bash
./scripts/fetch-freshluts.sh
```

---

## Why does the collage randomly go full-screen?

There is a 10% chance per reshuffle cycle that one video takes over the full screen for 8-16 seconds before returning to the tiled layout. This is intentional. It breaks up the grid pattern and adds visual variety over long sessions.

---

## Can I use it with multiple monitors?

Yes. Use `--all` to spawn a separate mpv instance on every connected monitor:

```bash
float ~/Videos --all
```

Use `--monitor N` to target one specific monitor by index (where the index matches the order from `xrandr --listmonitors`):

```bash
float ~/Videos --monitor 2
```

Without either flag, float uses your primary monitor.

---

## How do I control it while it's running?

From another terminal:

```bash
float --next     # next video
float --prev     # previous video
float --stop     # stop everything
float --list     # see what's currently playing
float --control  # open the GTK floating control panel
```

The GTK control panel (`--control`) gives you prev/next buttons and an opacity slider you can drag or hold to scrub. It's a small transparent window you can drag anywhere on your screen.

You can also send commands directly to mpv sockets:

```bash
echo '{"command":["playlist-next"]}' | socat - /tmp/mpv-float-1.sock
```

---

## Why can't I click through the video?

xwinwrap is launched with the `-ni` (no input) flag, which tells X11 to pass all input events through the window to whatever is behind it. In most window managers this works automatically.

If clicks are being captured by the float window instead of passing through, check your window manager's settings. Some compositors or window managers override input passthrough for below-desktop windows. If you are using a tiling window manager that manages all windows, float may need special configuration to be excluded from tiling rules and kept below the desktop layer.

---

## The control panel won't open / python3-gi error

The GTK control panel requires `python3-gi` (the GObject/GTK3 Python bindings):

```bash
sudo apt install python3-gi gir1.2-gtk-3.0
```

If you get a warning about `Gtk` not being imported, the bindings are missing or installed to a different Python environment than `python3` resolves to.

---

## Audio reactivity isn't working

First check that the audio daemon is writing data:

```bash
cat /tmp/float-audio
```

If the file doesn't exist or always shows zeros, the issue is in the audio capture. `audio-pulse.py` uses `parec` to capture the PulseAudio monitor source. Check that PulseAudio is running:

```bash
pactl info
```

And that a monitor source exists:

```bash
pactl list sources short | grep monitor
```

If you are on PipeWire, make sure `pipewire-pulse` is installed and running so that `parec` works:

```bash
pactl info | grep "Server Name"
```

Should show `PulseAudio (on PipeWire)` if the compatibility layer is active.

---

## Can I use it without audio reactivity?

Yes. If PulseAudio/PipeWire is not running or `parec` is not available, the audio daemon won't start. The visual effects still run — they just won't react to sound. The Lua script handles missing audio data gracefully; all audio values default to 0.

---

## What video formats are supported?

Anything mpv can play: mp4, mkv, avi, webm, mov, flv, wmv, m4v. Float searches for those extensions when scanning a folder. If you have a format mpv supports but float doesn't scan for, add the extension to the `VIDEO_EXTENSIONS` variable in the `float` script.
