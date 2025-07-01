# Build and Compile

## Float Itself

Float has no build step. The component languages are all interpreted at runtime:

| Component | Language | Runtime |
|-----------|----------|---------|
| `float` | Bash | bash |
| `scripts/dream-collage.lua` | Lua | mpv's built-in LuaJIT |
| `scripts/audio-pulse.py` | Python 3 | python3 |
| `scripts/float-control.py` | Python 3 | python3 |
| `scripts/float-drift.sh` | Bash | bash |
| `scripts/rounded-corners.glsl` | GLSL | mpv (GPU, runtime) |

You edit a file, you run float, changes are live. No compile step, no cache to clear.

---

## xwinwrap

xwinwrap is the one component that must be compiled. It is not packaged in any major distro's repository, so `install.sh` builds it from source automatically.

### What install.sh does for xwinwrap

```bash
git clone https://github.com/ujjwal96/xwinwrap /tmp/xwinwrap-build
cd /tmp/xwinwrap-build
make
sudo cp xwinwrap /usr/local/bin/
```

### Build requirements

The following packages must be present before the build:

```bash
sudo apt install gcc make libx11-dev libxext-dev libxrender-dev
```

`build-essential` covers `gcc` and `make`. The X11 development headers (`libx11-dev`, `libxext-dev`, `libxrender-dev`) are needed to compile against the X11 libraries that xwinwrap uses for window management.

### Manual build

If you want to build xwinwrap yourself without running `install.sh`:

```bash
git clone https://github.com/ujjwal96/xwinwrap
cd xwinwrap
make
sudo cp xwinwrap /usr/local/bin/
```

Verify:

```bash
which xwinwrap
xwinwrap --help
```

---

## GLSL Shader

`scripts/rounded-corners.glsl` is a GLSL program that runs on your GPU. It does not need to be compiled separately. mpv loads it as an output hook shader and compiles it via the GPU driver at startup. If there is a syntax error in the shader, mpv will log an error and skip it.

To test that the shader loads correctly:

```bash
mpv --glsl-shader=scripts/rounded-corners.glsl <video>
```

mpv will print a warning or error to stderr if the shader fails to compile.
