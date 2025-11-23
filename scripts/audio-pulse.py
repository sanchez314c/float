#!/usr/bin/env python3
"""audio-pulse.py — Real-time audio energy and beat detection for Float.

Captures system audio output via PulseAudio/PipeWire monitor source,
computes RMS energy + simple beat detection, writes to /tmp/float-audio
for the dream-collage lua script to read.

Output format (single line, updated ~30fps):
    energy bass mid high beat

    energy: 0.0-1.0 overall RMS energy (smoothed)
    bass:   0.0-1.0 low frequency energy (20-250Hz)
    mid:    0.0-1.0 mid frequency energy (250-4000Hz)
    high:   0.0-1.0 high frequency energy (4000-20000Hz)
    beat:   0 or 1 (1 = beat detected this frame)
"""

import subprocess
import struct
import sys
import os
import math
import signal
import time

OUTPUT_FILE = "/tmp/float-audio"
SAMPLE_RATE = 48000
CHANNELS = 2
FRAME_SIZE = 2  # s16le = 2 bytes per sample
CHUNK_SAMPLES = 1600  # ~33ms at 48kHz (30fps)
CHUNK_BYTES = CHUNK_SAMPLES * CHANNELS * FRAME_SIZE

# Beat detection
BEAT_THRESHOLD = 1.6  # energy must be this many times the average to count as beat
ENERGY_HISTORY_SIZE = 45  # ~1.5 seconds of history at 30fps
energy_history = []

# Smoothing
smooth_energy = 0.0
smooth_bass = 0.0
smooth_mid = 0.0
smooth_high = 0.0
SMOOTH_UP = 0.4    # fast attack
SMOOTH_DOWN = 0.08  # slow decay


def find_monitor_source():
    """Find the running monitor source for system audio capture."""
    try:
        result = subprocess.run(
            ["pactl", "list", "short", "sources"],
            capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.splitlines():
            if "monitor" in line.lower() and "RUNNING" in line:
                return line.split()[1]
        # Fallback: use default sink monitor
        result2 = subprocess.run(
            ["pactl", "get-default-sink"],
            capture_output=True, text=True, timeout=5
        )
        return result2.stdout.strip() + ".monitor"
    except Exception:
        # Generic fallback: default sink's monitor source
        return "default.monitor"


def smooth(current, target, up_rate, down_rate):
    """Asymmetric smoothing — fast attack, slow decay."""
    if target > current:
        return current + (target - current) * up_rate
    else:
        return current + (target - current) * down_rate


def compute_rms(samples):
    """Compute RMS of sample array."""
    if not samples:
        return 0.0
    sum_sq = sum(s * s for s in samples)
    return math.sqrt(sum_sq / len(samples)) / 32768.0


def simple_fft_bands(samples, sample_rate):
    """Poor man's frequency band energy using zero-crossing rate and filters.

    Real FFT would be better but we avoid numpy dependency.
    Instead we use a simple approach: difference filter for high freq,
    moving average for low freq.
    """
    n = len(samples)
    if n < 4:
        return 0.0, 0.0, 0.0

    # Bass: low-pass via moving average (window=24 samples ~ 2kHz cutoff at 48k)
    window = 24
    bass_samples = []
    for i in range(window, n):
        avg = sum(samples[i - window:i]) / window
        bass_samples.append(avg)
    bass = compute_rms(bass_samples) * 2.5

    # High: high-pass via difference filter
    high_samples = [samples[i] - samples[i - 1] for i in range(1, n)]
    high = compute_rms(high_samples) * 1.5

    # Mid: original minus bass and high (approximation)
    mid = max(0.0, compute_rms(samples) * 1.8 - bass * 0.3 - high * 0.3)

    return min(1.0, bass), min(1.0, mid), min(1.0, high)


def detect_beat(energy):
    """Simple beat detection: is current energy significantly above recent average?"""
    energy_history.append(energy)
    if len(energy_history) > ENERGY_HISTORY_SIZE:
        energy_history.pop(0)

    if len(energy_history) < 10:
        return 0

    avg = sum(energy_history) / len(energy_history)
    if avg < 0.01:
        return 0

    return 1 if energy > avg * BEAT_THRESHOLD else 0


def main():
    global smooth_energy, smooth_bass, smooth_mid, smooth_high

    source = find_monitor_source()
    print(f"float audio-pulse: capturing from {source}", flush=True)

    # Start parec to capture audio
    proc = subprocess.Popen(
        [
            "parec",
            "--rate", str(SAMPLE_RATE),
            "--channels", str(CHANNELS),
            "--format", "s16le",
            "--device", source,
            "--raw",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    def cleanup(sig, frame):
        proc.kill()
        try:
            os.unlink(OUTPUT_FILE)
        except OSError:
            pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    try:
        while True:
            data = proc.stdout.read(CHUNK_BYTES)
            if not data or len(data) < CHUNK_BYTES:
                break

            # Decode s16le samples, mix stereo to mono
            num_samples = len(data) // FRAME_SIZE
            raw = struct.unpack(f"<{num_samples}h", data)
            mono = [(raw[i] + raw[i + 1]) / 2.0 for i in range(0, num_samples, 2)]

            # Compute energy
            raw_energy = compute_rms(mono)
            bass, mid, high = simple_fft_bands(mono, SAMPLE_RATE)

            # Smooth
            smooth_energy = smooth(smooth_energy, raw_energy, SMOOTH_UP, SMOOTH_DOWN)
            smooth_bass = smooth(smooth_bass, bass, SMOOTH_UP, SMOOTH_DOWN)
            smooth_mid = smooth(smooth_mid, mid, SMOOTH_UP, SMOOTH_DOWN)
            smooth_high = smooth(smooth_high, high, SMOOTH_UP, SMOOTH_DOWN)

            # Beat detection on raw (unsmoothed) energy
            beat = detect_beat(raw_energy)

            # Write to file atomically
            tmp = OUTPUT_FILE + ".tmp"
            with open(tmp, "w") as f:
                f.write(f"{smooth_energy:.4f} {smooth_bass:.4f} {smooth_mid:.4f} {smooth_high:.4f} {beat}\n")
            os.replace(tmp, OUTPUT_FILE)

    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        proc.kill()
        try:
            os.unlink(OUTPUT_FILE)
        except OSError:
            pass


if __name__ == "__main__":
    main()
