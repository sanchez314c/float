# Deployment

Float is a local desktop tool, not a server application. There is no network service to deploy, no daemon to configure, and no production environment in the traditional sense.

---

## Standard Install (Per User)

This is what most people should use:

```bash
git clone https://github.com/sanchez314c/float.git
cd float
./install.sh
```

This puts xwinwrap in `/usr/local/bin/` and symlinks `float` into `~/bin/`. Float runs as your user with your display session. No system service, no startup entry unless you add one yourself.

---

## System-Wide Install

To make float available to all users on the machine, symlink the `float` script to `/usr/local/bin/` instead of `~/bin/`:

```bash
sudo ln -sf /path/to/float/float /usr/local/bin/float
```

Each user still needs their own `~/.config/float/settings.conf` and their own display session for it to work. Float uses `$DISPLAY` and PulseAudio, both of which are per-session.

---

## Autostart

Float does not install any autostart entry. If you want it to start with your desktop session, add an entry to your desktop environment's autostart directory.

For GNOME/KDE or any XDG-compliant desktop, create `~/.config/autostart/float.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Float
Exec=/home/<user>/bin/float /home/<user>/Videos --collage --shuffle
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

Replace the path and flags with your actual setup. Float must be running inside an X11 session, so make sure your autostart runs after the X session is ready.

---

## Packaging

Float could be packaged as a `.deb` or an AUR package. The main considerations:

- xwinwrap would need to be a separate package or bundled binary since it is not in any official repo.
- The install destination for the `float` script would change from `~/bin/` to `/usr/local/bin/` or `/usr/bin/`.
- The `scripts/` directory would go somewhere like `/usr/share/float/scripts/` and the `float` script would need to reference that path instead of a relative `./scripts/` path.

No packaging files are currently included in the repo.

---

## Uninstall

```bash
# Remove the float symlink
rm ~/bin/float

# Remove xwinwrap
sudo rm /usr/local/bin/xwinwrap

# Remove config (optional)
rm -rf ~/.config/float

# Clean up any leftover temp files
rm -f /tmp/float.pids /tmp/float-audio /tmp/float-luts.list \
      /tmp/float-lut-interval /tmp/float-opacity \
      /tmp/float-audio-pulse.pid /tmp/float-collage.pid \
      /tmp/mpv-float-*.sock
```

The cloned repo directory can be removed with `rm -rf`.
