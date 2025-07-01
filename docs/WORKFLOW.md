# Development Workflow

## Day-to-day development

There's no build step. All files are interpreted (bash, Python, Lua, GLSL). Edit a file, run Float, see the result. That's the loop.

```bash
# Make a change to the Lua script
vim scripts/dream-collage.lua

# Kill any running instance
float --stop

# Test it
float ~/Videos --collage
```

For visual effect changes specifically, you'll want a second terminal to run `float --stop` quickly and iterate without hunting for the right window to close.

## Changing the Lua visual modes

The Lua script (`scripts/dream-collage.lua`) is hot-editable. mpv doesn't need to restart for Lua changes to take effect at the next mode switch (every 10-35 seconds). If you want to force a reload, kill and restart Float.

## Audio daemon development

Changes to `scripts/audio-pulse.py` require killing the existing Python process:

```bash
pkill -f audio-pulse.py
```

Float will respawn it automatically on next run, or you can run it standalone for debugging:

```bash
python3 scripts/audio-pulse.py &
watch -n 0.5 cat /tmp/float-audio
```

That gives you a live view of what the audio daemon is outputting.

## Testing

Manual and visual. There are no automated tests because the outputs are video effects on a desktop and there's no practical way to assert "this looks right." The test is: does it run, does it look good, does the control panel work.

For the audio daemon's numerical output, the standalone debug approach above is as close as you get to a unit test.

## Git branching

- `main` is stable and deployable
- Feature work goes on a branch: `git checkout -b feature/my-thing`
- Merge via PR to keep history clean

Commit messages follow the format: `type: description` where type is `feat`, `fix`, `refactor`, `docs`, or `chore`.

## Releasing

1. Update `CHANGELOG.md` with the date and a summary of changes
2. Commit: `git commit -m "chore: release vX.Y.Z"`
3. Tag: `git tag vX.Y.Z`
4. Push: `git push origin main --tags`

No CI/CD. The project is small enough that a manual check before tagging is sufficient.
