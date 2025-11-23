#!/usr/bin/python3
"""float-control — Tiny floating glass control panel for float"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import os
import signal

FLOAT_BIN = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "float")
OPACITY_STEP = 0.01
OPACITY_MIN = 0.01
OPACITY_MAX = 1.0
OPACITY_FILE = "/tmp/float-opacity"

class FloatControl(Gtk.Window):
    def __init__(self):
        super().__init__(title="float-ctrl")

        # Read current opacity
        self.opacity = 0.07
        try:
            with open(OPACITY_FILE, "r") as f:
                self.opacity = float(f.read().strip())
        except (OSError, ValueError):
            pass

        # Transparent window
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        self.connect("draw", self.on_draw)

        # Window properties
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.stick()  # visible on all workspaces

        # Position bottom-right
        display = Gdk.Display.get_default()
        monitor = display.get_primary_monitor()
        geom = monitor.get_geometry()
        self.set_default_size(200, 44)
        self.move(geom.x + geom.width // 2 - 100, geom.y + 50)

        # Layout
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        box.set_margin_start(8)
        box.set_margin_end(8)
        box.set_margin_top(6)
        box.set_margin_bottom(6)

        # Hold-repeat state
        self._hold_timer = None
        self._hold_action = None

        # Buttons
        btn_prev = self.make_button("◀", "Previous video", self.on_prev)
        btn_next = self.make_button("▶", "Next video", self.on_next)
        btn_down = self.make_hold_button("−", "Opacity down (hold to scrub)", self.on_opacity_down)
        btn_up = self.make_hold_button("+", "Opacity up (hold to scrub)", self.on_opacity_up)

        self.label = Gtk.Label()
        self.label.set_markup(f'<span color="#66ffcc" font="9">{self.opacity:.2f}</span>')

        box.pack_start(btn_prev, False, False, 0)
        box.pack_start(btn_next, False, False, 0)
        box.pack_start(Gtk.Separator(), False, False, 4)
        box.pack_start(btn_down, False, False, 0)
        box.pack_start(self.label, False, False, 2)
        box.pack_start(btn_up, False, False, 0)

        self.add(box)

        # CSS
        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window {
                background: transparent;
            }
            button {
                background: rgba(20, 20, 25, 0.7);
                border: 1px solid rgba(102, 255, 204, 0.25);
                border-radius: 6px;
                color: #66ffcc;
                font-size: 14px;
                min-width: 32px;
                min-height: 32px;
                padding: 0 6px;
            }
            button:hover {
                background: rgba(102, 255, 204, 0.15);
                border-color: rgba(102, 255, 204, 0.5);
            }
            button:active {
                background: rgba(102, 255, 204, 0.25);
            }
            separator {
                background: rgba(102, 255, 204, 0.15);
                min-width: 1px;
            }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Keyboard controls
        self.connect("key-press-event", self.on_key_press)

        # Draggable — use an event box around the whole window
        # but only initiate drag if the click target is the window itself, not a button
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect("button-press-event", self.on_mouse_press)

        self.show_all()

    def make_button(self, label, tooltip, callback):
        btn = Gtk.Button(label=label)
        btn.set_tooltip_text(tooltip)
        btn.connect("clicked", callback)
        return btn

    def make_hold_button(self, label, tooltip, action):
        btn = Gtk.Button(label=label)
        btn.set_tooltip_text(tooltip)
        btn.connect("pressed", self._on_hold_start, action)
        btn.connect("released", self._on_hold_stop)
        btn.connect("leave-notify-event", lambda *a: self._on_hold_stop(None))
        return btn

    def _on_hold_start(self, btn, action):
        action(None)  # fire immediately on press
        self._hold_action = action
        # Start repeating after 300ms, then every 60ms
        self._hold_timer = GLib.timeout_add(300, self._hold_repeat_start)

    def _hold_repeat_start(self):
        self._hold_timer = GLib.timeout_add(60, self._hold_tick)
        return False  # don't repeat this initial delay

    def _hold_tick(self):
        if self._hold_action:
            self._hold_action(None)
            return True  # keep repeating
        return False

    def _on_hold_stop(self, *args):
        if self._hold_timer:
            GLib.source_remove(self._hold_timer)
            self._hold_timer = None
        self._hold_action = None

    def on_draw(self, widget, cr):
        cr.set_source_rgba(12/255, 12/255, 18/255, 0.65)
        cr.set_operator(0)  # cairo.OPERATOR_CLEAR
        cr.paint()
        cr.set_operator(2)  # cairo.OPERATOR_OVER
        # Rounded rectangle background
        w = widget.get_allocated_width()
        h = widget.get_allocated_height()
        r = 12
        cr.new_sub_path()
        cr.arc(w - r, r, r, -1.5708, 0)
        cr.arc(w - r, h - r, r, 0, 1.5708)
        cr.arc(r, h - r, r, 1.5708, 3.14159)
        cr.arc(r, r, r, 3.14159, 4.71239)
        cr.close_path()
        cr.set_source_rgba(12/255, 12/255, 18/255, 0.65)
        cr.fill_preserve()
        cr.set_source_rgba(102/255, 255/255, 204/255, 0.2)
        cr.set_line_width(1)
        cr.stroke()
        return False

    def on_key_press(self, widget, event):
        key = Gdk.keyval_name(event.keyval)
        if key == "Left":
            self.on_prev(None)
            return True
        elif key == "Right":
            self.on_next(None)
            return True
        elif key == "Up":
            self.on_opacity_up(None)
            return True
        elif key == "Down":
            self.on_opacity_down(None)
            return True
        elif key in ("q", "Escape"):
            Gtk.main_quit()
            return True
        return False

    def on_mouse_press(self, widget, event):
        # Only drag if clicking empty space (not a button)
        target = Gtk.get_event_widget(event)
        if event.button == 1 and target == self:
            self.begin_move_drag(event.button, int(event.x_root), int(event.y_root), event.time)

    def _send_mpv_command(self, cmd):
        import glob
        for sock in glob.glob("/tmp/mpv-float-*.sock"):
            subprocess.run(
                ["socat", "-", sock],
                input=(cmd + "\n").encode(),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

    def on_prev(self, btn):
        self._send_mpv_command('{"command":["playlist-prev"]}')

    def on_next(self, btn):
        self._send_mpv_command('{"command":["playlist-next"]}')

    def on_opacity_up(self, _btn):
        self.opacity = round(min(OPACITY_MAX, self.opacity + OPACITY_STEP), 2)
        self.apply_opacity()

    def on_opacity_down(self, _btn):
        self.opacity = round(max(OPACITY_MIN, self.opacity - OPACITY_STEP), 2)
        self.apply_opacity()

    def get_xwinwrap_wids(self):
        """Extract xwinwrap window IDs from mpv --wid=0xNNN args"""
        import re
        wids = []
        try:
            result = subprocess.run(
                ["pgrep", "-a", "mpv"],
                capture_output=True, text=True
            )
            for line in result.stdout.strip().split("\n"):
                m = re.search(r'--wid=(0x[0-9a-fA-F]+)', line)
                if m:
                    wids.append(m.group(1))
        except Exception:
            pass
        return wids

    def apply_opacity(self):
        self.label.set_markup(f'<span color="#66ffcc" font="9">{self.opacity:.2f}</span>')
        with open(OPACITY_FILE, "w") as f:
            f.write(f"{self.opacity:.2f}")
        opacity_val = int(self.opacity * 0xFFFFFFFF)
        for wid in self.get_xwinwrap_wids():
            subprocess.Popen(
                ["xprop", "-id", wid, "-f", "_NET_WM_WINDOW_OPACITY", "32c",
                 "-set", "_NET_WM_WINDOW_OPACITY", str(opacity_val)],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )


def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    win = FloatControl()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()

if __name__ == "__main__":
    main()
