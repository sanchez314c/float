# Quick Start

## From zero to running in under 5 minutes

**1. Clone the repo**

```bash
git clone https://github.com/sanchez314c/float.git && cd float
```

**2. Run the installer**

```bash
./install.sh
```

This checks for dependencies, builds xwinwrap from source if needed, and symlinks the `float` command to `~/bin/`. You may be prompted for sudo to install missing packages.

**3. Start Float**

```bash
float ~/Videos --collage
```

Point it at any folder with video files. `--collage` gives you the multi-tile layout. Skip the flag if you want a single fullscreen video instead.

**4. Confirm it's working**

You should see translucent video tiles overlaid on your desktop, drifting and shifting. They sit below all your windows and don't intercept clicks. Visual modes cycle automatically every 10-35 seconds.

**5. Stop it**

```bash
float --stop
```

**6. Open the control panel** (optional)

```bash
float --control
```

A small floating panel appears with prev/next buttons and an opacity slider. Drag it anywhere on screen.

---

**Other useful flags:**

```bash
float ~/Videos --shuffle          # randomize playlist order
float ~/Videos --monitor 1        # target a specific monitor (0 = leftmost)
float ~/Videos --opacity 0.06     # set starting opacity (0.0-1.0)
float ~/Videos --luts ~/luts/     # add LUT color grading rotation
float --list                      # show all running instances
```
