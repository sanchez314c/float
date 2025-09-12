# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.1.0  | Yes       |

Older versions are not maintained. Run the latest.

## What Float Does (and Doesn't Do)

Float is a local desktop tool. It opens no network ports, runs no servers, and requires no authentication. All processing happens on your machine.

**Process model:**
- `xwinwrap` runs with `-ni` (no input capture) and `-b` (below the desktop layer). It does not intercept mouse or keyboard input.
- `mpv` runs with `--no-input-default-bindings` to prevent it from consuming global hotkeys.
- `audio-pulse.py` reads only from PulseAudio/PipeWire monitor sources — the loopback of your system audio output. It does not access microphones or any input device.

**Temp files:**
- PID tracking: `/tmp/float.pids`
- mpv IPC sockets: `/tmp/mpv-float-*.sock`
- Audio sample data: written and read only within the daemon process, not persisted to disk.

None of these files contain sensitive data. Sockets are created with default umask permissions (owner read/write only on most Linux systems). If you're on a multi-user machine, verify your umask is restrictive.

**Network:**
- `fetch-freshluts.sh` downloads LUT files from an S3 bucket over HTTPS. It only runs when you explicitly call it. Float itself never makes network requests during playback.

## Reporting a Vulnerability

Open a GitHub issue at [github.com/sanchez314c/float](https://github.com/sanchez314c/float) and label it `security`. If you'd prefer private disclosure, email the maintainer directly (address in the GitHub profile).

Please include:
- What you found
- Steps to reproduce
- What system you're on (distro, PulseAudio vs PipeWire, xwinwrap version)

There's no SLA here — this is an open source desktop tool — but reports will be taken seriously and addressed promptly.
