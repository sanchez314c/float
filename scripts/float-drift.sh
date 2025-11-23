#!/bin/bash
# float-drift.sh — Smooth sine-wave drift for a single mpv floating window
# Each instance gets unique phase offsets so they all move differently
#
# Usage: float-drift.sh <window_id> <screen_w> <screen_h> <win_w> <win_h> <start_x> <start_y>

WID="$1"
SCREEN_W="$2"
SCREEN_H="$3"
WIN_W="$4"
WIN_H="$5"
START_X="$6"
START_Y="$7"

# Random phase offsets so each window drifts uniquely (use $RANDOM to avoid spawning python3)
PHASE_X=$(echo "scale=6; $RANDOM / 32768 * 6.28318" | bc)
PHASE_Y=$(echo "scale=6; $RANDOM / 32768 * 6.28318" | bc)

# Random drift speeds (different for each window)
SPEED_X=$(echo "scale=6; 0.008 + $RANDOM / 32768 * 0.012" | bc)
SPEED_Y=$(echo "scale=6; 0.006 + $RANDOM / 32768 * 0.009" | bc)

# Drift amplitude — how far from start position it can wander (pixels)
AMP_X=$(( (SCREEN_W - WIN_W) / 3 ))
AMP_Y=$(( (SCREEN_H - WIN_H) / 3 ))

# Center point to oscillate around
CENTER_X=$(( START_X ))
CENTER_Y=$(( START_Y ))

FRAME=0

while xdotool getwindowname "$WID" &>/dev/null; do
    # Sine wave position offset from center (use bc instead of spawning python3 per frame)
    ANGLE_X=$(echo "scale=6; $FRAME * $SPEED_X + $PHASE_X" | bc)
    ANGLE_Y=$(echo "scale=6; $FRAME * $SPEED_Y + $PHASE_Y" | bc)
    DX=$(echo "scale=0; $AMP_X * s($ANGLE_X) / 1" | bc -l)
    DY=$(echo "scale=0; $AMP_Y * s($ANGLE_Y) / 1" | bc -l)

    NEW_X=$(( CENTER_X + DX ))
    NEW_Y=$(( CENTER_Y + DY ))

    # Clamp to screen bounds
    if [ "$NEW_X" -lt 0 ]; then NEW_X=0; fi
    if [ "$NEW_Y" -lt 0 ]; then NEW_Y=0; fi
    MAX_X=$(( SCREEN_W - WIN_W ))
    MAX_Y=$(( SCREEN_H - WIN_H ))
    if [ "$NEW_X" -gt "$MAX_X" ]; then NEW_X=$MAX_X; fi
    if [ "$NEW_Y" -gt "$MAX_Y" ]; then NEW_Y=$MAX_Y; fi

    xdotool windowmove "$WID" "$NEW_X" "$NEW_Y" 2>/dev/null

    FRAME=$(( FRAME + 1 ))
    sleep 0.05
done
