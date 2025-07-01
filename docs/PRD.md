# Product Requirements

## What it is

Float turns a folder of video files into a living desktop background. Videos play as translucent animated wallpaper, sitting below all open windows and reacting in real time to system audio. Multiple tiles can run simultaneously in a collage layout that reshuffles itself on a timer.

## Why it exists

Linux has wallpaper tools like Variety and Komorebi. None of them support real-time visual effects, audio reactivity, or multi-tile collage layouts. Static images and basic video looping exist, but nothing that makes the desktop feel alive in response to what's playing. Float fills that gap.

## Who it's for

Linux desktop users who want ambient visual atmosphere. Not a productivity tool. The target is someone who runs music or ambient video in the background and wants their desktop to reflect that, not just sit there.

## Core features

- **Video wallpaper** — Any folder of video files plays as a transparent, click-through, below-desktop layer
- **Collage mode** — 3 to 6 tiles, random sizes (25-60% of screen), random positions, reshuffled every 25-75 seconds with a 10% chance of one tile going full screen
- **7 visual modes** — dream, drift, pulse, chaos, calm, vortex, glitch. Each has a distinct character. Modes auto-switch on a random timer.
- **Audio reactivity** — Bass pumps zoom, beats flash brightness, energy drives vortex speed, high frequencies modulate hue. Reads from PulseAudio/PipeWire monitor source.
- **LUT rotation** — Applies color grading from .cube/.3dl files, cycling on a configurable interval
- **Multi-monitor support** — Target any connected monitor by index, sorted left to right
- **Opacity control** — Set at launch or adjust live via the control panel or xprop
- **GTK3 control panel** — Floating, transparent, draggable window with prev/next and opacity slider

## What it doesn't do

- **Wayland** — xwinwrap is X11 only. A Wayland port would need a different mechanism (wlr-layer-shell or similar) and is out of scope.
- **Video editing** — Float is playback only. It doesn't modify or re-encode your files.
- **Audio playback** — Videos play muted. Float captures system audio output for reactivity but doesn't route video audio.
- **Configuration GUI** — Settings live in `~/.config/float/settings.conf`. Editing the file is the intended workflow. The control panel handles runtime adjustments only.

## Success criteria

1. Videos play smoothly at low opacity (0.04-0.10) without noticeably impacting desktop usability or window interaction
2. Visual effects look intentional and pleasing, not glitchy or mechanical
3. Audio reactivity feels natural, responding to the music rather than any arbitrary audio event
4. Install on a fresh Ubuntu/Debian system works in under 5 minutes via `./install.sh`
