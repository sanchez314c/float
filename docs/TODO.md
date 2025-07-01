# TODO

## Open work items

- [ ] **Wayland support** — xwinwrap is X11 only. A Wayland equivalent would need wlr-layer-shell or the ext-session-lock protocol. This is a significant rewrite, not an incremental addition.

- [ ] **Per-tile visual mode assignment** — Currently all collage tiles cycle through the same random mode rotation. Assigning each tile its own independent mode would make collages more visually diverse.

- [ ] **Save and restore tile layouts** — Collage positions and sizes are randomized every cycle. An option to lock or save a layout you like would be useful.

- [ ] **GPU-accelerated frequency analysis** — The Python audio daemon does frequency separation in software with a moving-average filter. Replacing it with something GPU-accelerated (or at least FFTW-based) would give cleaner band separation and lower CPU overhead.

- [ ] **Configuration GUI** — Right now you edit `~/.config/float/settings.conf` by hand. Adding a settings panel to the GTK3 control window would make common changes (opacity, LUT path, panscan) accessible without a text editor.

- [ ] **Smooth LUT transitions** — LUT changes are currently hard cuts. Crossfading between LUTs over a few seconds would be less jarring.

- [ ] **Video filter presets** — A way to save and reload favorite combinations of effect parameters (specific mode bias, intensity, color ranges) for different moods or music types.

- [ ] **Systemd user service** — A `~/.config/systemd/user/float.service` unit so Float can auto-start on login and be managed with `systemctl --user start/stop float`.

- [ ] **Packaging** — AUR PKGBUILD, .deb, or Flatpak. Right now install requires git and running a shell script. A proper package would handle the xwinwrap build automatically.

- [ ] **float-drift.sh math performance** — The drift script currently calls `python3` every frame to compute sine values. This could use `bc` for math or precompute a lookup table of positions and iterate through it, avoiding a Python subprocess on every frame.
