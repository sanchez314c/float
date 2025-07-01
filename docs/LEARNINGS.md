# Learnings

Things discovered while building Float that aren't obvious from the code alone.

## xwinwrap flags are fragile

The combination `-fdt -ni -b -nf -un` is not arbitrary. Each flag targets a specific X11 behavior: click-through, below-desktop placement, no focus stealing, borderless, and undecorated. Removing or changing any one of them can break the experience in subtle ways, like windows that intercept mouse clicks or pop to the foreground when you switch workspaces. If you're experimenting with xwinwrap behavior, change one flag at a time and test on a real desktop session, not a nested X server.

## Each mpv instance needs time to seed differently

The Lua script uses `math.random()` seeded from `os.time()`. If you spawn two mpv instances back to back without a delay, they get the same seed and their visual modes become synchronized. A 200ms sleep between spawns is enough to guarantee different seeds. It's a small thing but it's why collage tiles don't all pulse together.

## PulseAudio monitor sources only run when audio is playing

Monitor sources show as `IDLE` when nothing is outputting audio. The audio daemon falls back to `default-sink.monitor` to stay attached to the right device, but reactivity is naturally flat when there's nothing to react to. This is expected behavior, not a bug. If you're testing audio reactivity, you need audio playing.

## Avoiding numpy was worth it

A real FFT would give cleaner frequency band separation, but it adds a hard dependency (numpy) that complicates installation. A moving-average filter on the PCM data for the low-frequency baseline, then the difference between current and baseline for mid/high energy, works well enough for visual effects. The effects don't need precise frequency isolation, they just need something that pumps with the music. The simpler approach passes that bar.

## Atomic writes prevent torn reads

The Lua script reads `/tmp/float-audio` at 15fps. The Python daemon writes it much more frequently. Without atomic writes, the Lua script would occasionally read a half-written file and get garbage values. Writing to `/tmp/float-audio.tmp` and using `os.replace()` to move it into place makes every read either the old complete value or the new complete value. Never partial.

## Prime-ish periods prevent visual repetition

The sinusoidal modulation in the Lua script uses cycle periods like 45.6, 73.2, and 57.2 seconds. These aren't round numbers on purpose. When periods are round numbers or simple multiples of each other (30, 60, 120), the combined waveform repeats on a predictable cycle and starts to look mechanical. Slightly irrational periods mean the interference pattern between multiple simultaneous modulations takes much longer to repeat, if ever.

## 30% flip adds variety without pattern

Horizontally flipping a tile in collage mode with 30% probability adds enough visual diversity that the grid doesn't look repetitive, but not so often that the mirroring becomes obvious as a technique. Higher flip rates start to look intentional and draw attention to it.

## Beat detection threshold: 1.6x rolling average

The beat detector in the audio daemon fires when the current energy exceeds 1.6 times the rolling average energy. Lower than 1.4 and it triggers constantly on any dynamic audio. Higher than 1.8 and subtle beats in quieter passages get missed. 1.6 is the sweet spot for visual effects that feel reactive without being spastic.
