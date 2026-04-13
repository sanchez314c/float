-- dream-collage.lua — Chaotic dreamy real-time video manipulation
-- Now with audio-reactive modulation via /tmp/float-audio

-- Use time + PID so instances launched in the same second get different seeds
math.randomseed(os.time() + (tonumber(tostring({}):match("0x(%x+)")) or 0))

-- === EFFECT PARAMETERS ===
local fps = 30
local step = 1.0 / fps
local elapsed = 0

-- Each effect has its own cycle speed (prime-ish numbers so they never sync up)
local zoom_cycle = 45.6
local pan_x_cycle = 73.2
local pan_y_cycle = 57.2
local hue_cycle = 73.2
local sat_cycle = 49.6
local bright_cycle = 60.2
local contrast_cycle = 42.6
local speed_cycle = 97.6
local rotation_cycle = 110.8

-- Effect intensity ranges
local zoom_min = -0.025
local zoom_max = 0.2
local pan_range = 0.225
local hue_range = 40
local sat_min = -20
local sat_max = 30
local bright_min = -8
local bright_max = 8
local contrast_min = -10
local contrast_max = 15
local speed_min = 0.7
local speed_max = 1.3

-- === CHAOS ENGINE ===
local zoom_phase = math.random() * math.pi * 2
local pan_x_phase = math.random() * math.pi * 2
local pan_y_phase = math.random() * math.pi * 2
local hue_phase = math.random() * math.pi * 2
local sat_phase = math.random() * math.pi * 2
local bright_phase = math.random() * math.pi * 2
local contrast_phase = math.random() * math.pi * 2
local speed_phase = math.random() * math.pi * 2
local rotation_phase = math.random() * math.pi * 2

-- Drift targets
local drift_x_target = 0
local drift_y_target = 0
local drift_x_current = 0
local drift_y_current = 0
local drift_smoothing = 0.001

-- Mode system
local modes = { "dream", "drift", "pulse", "chaos", "calm", "vortex", "glitch" }
local current_mode = "dream"
local mode_timer = 0
local mode_duration = 0

-- Glitch state
local glitch_active = false
local glitch_timer = 0
local glitch_interval = 0

-- === AUDIO REACTIVE ===
local audio_energy = 0
local audio_bass = 0
local audio_mid = 0
local audio_high = 0
local audio_beat = 0
local audio_read_counter = 0
local AUDIO_FILE = "/tmp/float-audio"

-- Beat accumulator for smooth pulse effects
local beat_pulse = 0
local beat_decay = 0.92  -- how fast beat pulse fades

-- === LUT ROTATION ===
local LUT_LIST_FILE = "/tmp/float-luts.list"
local LUT_INTERVAL_FILE = "/tmp/float-lut-interval"
local lut_files = {}
local lut_index = 0
local lut_timer = 0
local lut_interval = 20  -- seconds between LUT changes
local lut_loaded = false
local current_lut = ""

function load_lut_list()
    -- Read LUT interval
    local fi = io.open(LUT_INTERVAL_FILE, "r")
    if fi then
        local val = fi:read("*line")
        fi:close()
        if val then lut_interval = tonumber(val) or 20 end
    end

    -- Read LUT file list
    local f = io.open(LUT_LIST_FILE, "r")
    if not f then return end
    lut_files = {}
    for line in f:lines() do
        if line ~= "" then
            table.insert(lut_files, line)
        end
    end
    f:close()

    -- Shuffle the LUT list
    for i = #lut_files, 2, -1 do
        local j = math.random(i)
        lut_files[i], lut_files[j] = lut_files[j], lut_files[i]
    end

    lut_loaded = #lut_files > 0
end

function apply_next_lut()
    if not lut_loaded or #lut_files == 0 then return end

    lut_index = lut_index + 1
    if lut_index > #lut_files then
        -- Reshuffle when we've gone through all of them
        for i = #lut_files, 2, -1 do
            local j = math.random(i)
            lut_files[i], lut_files[j] = lut_files[j], lut_files[i]
        end
        lut_index = 1
    end

    local lut_path = lut_files[lut_index]
    if lut_path ~= current_lut then
        current_lut = lut_path
        mp.command("no-osd vf set lut3d=\"" .. lut_path .. "\"")
    end
end

function update_lut()
    if not lut_loaded then return end

    lut_timer = lut_timer + step
    if lut_timer >= lut_interval then
        lut_timer = 0
        apply_next_lut()
    end
end

function read_audio()
    -- Read every 2 frames (~15fps) to reduce file I/O
    audio_read_counter = audio_read_counter + 1
    if audio_read_counter % 2 ~= 0 then return end

    local f = io.open(AUDIO_FILE, "r")
    if not f then return end
    local line = f:read("*line")
    f:close()
    if not line then return end

    local e, b, m, h, bt = line:match("([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s+(%d)")
    if e then
        audio_energy = tonumber(e) or 0
        audio_bass = tonumber(b) or 0
        audio_mid = tonumber(m) or 0
        audio_high = tonumber(h) or 0
        audio_beat = tonumber(bt) or 0
    end
end

function pick_mode()
    current_mode = modes[math.random(#modes)]
    mode_duration = 10 + math.random() * 25
    mode_timer = 0

    if current_mode == "glitch" then
        glitch_interval = 0.5 + math.random() * 2
        glitch_timer = 0
    end
end

function sine(t, cycle, phase)
    return math.sin(2 * math.pi * (t / cycle) + phase)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function remap(val, out_min, out_max)
    return out_min + (val + 1) * 0.5 * (out_max - out_min)
end

function update_drift()
    if math.random() < 0.002 then
        drift_x_target = (math.random() - 0.5) * 2 * pan_range
        drift_y_target = (math.random() - 0.5) * 2 * pan_range
    end
    drift_x_current = lerp(drift_x_current, drift_x_target, drift_smoothing)
    drift_y_current = lerp(drift_y_current, drift_y_target, drift_smoothing)
end

function update()
    elapsed = elapsed + step
    mode_timer = mode_timer + step

    -- Read audio data
    read_audio()

    -- Rotate LUTs on timer
    update_lut()

    -- Update beat pulse (spikes on beat, decays smoothly)
    if audio_beat == 1 then
        beat_pulse = 1.0
    else
        beat_pulse = beat_pulse * beat_decay
    end

    -- Switch modes when timer expires
    -- Audio can trigger early mode switch on strong beats
    if mode_timer >= mode_duration then
        pick_mode()
    elseif audio_beat == 1 and mode_timer > 8 and math.random() < 0.08 then
        pick_mode()  -- occasional beat-triggered mode switch
    end

    update_drift()

    local zoom = 0
    local pan_x = 0
    local pan_y = 0
    local hue = 0
    local sat = 0
    local bright = 0
    local contrast = 0
    local spd = 1.0
    local rotation = 0

    -- Base oscillations
    local zoom_wave = sine(elapsed, zoom_cycle, zoom_phase)
    local pan_x_wave = sine(elapsed, pan_x_cycle, pan_x_phase)
    local pan_y_wave = sine(elapsed, pan_y_cycle, pan_y_phase)
    local hue_wave = sine(elapsed, hue_cycle, hue_phase)
    local sat_wave = sine(elapsed, sat_cycle, sat_phase)
    local bright_wave = sine(elapsed, bright_cycle, bright_phase)
    local contrast_wave = sine(elapsed, contrast_cycle, contrast_phase)
    local speed_wave = sine(elapsed, speed_cycle, speed_phase)
    local rotation_wave = sine(elapsed, rotation_cycle, rotation_phase)

    -- Audio reactivity multipliers (scale 0-1 range to useful modulation)
    local a_energy = audio_energy * 3.0   -- amplify since raw values are often small
    local a_bass = audio_bass * 4.0
    local a_mid = audio_mid * 3.0
    local a_high = audio_high * 3.0
    a_energy = math.min(1.0, a_energy)
    a_bass = math.min(1.0, a_bass)
    a_mid = math.min(1.0, a_mid)
    a_high = math.min(1.0, a_high)

    if current_mode == "dream" then
        zoom = remap(zoom_wave, zoom_min, zoom_max * 0.6)
        pan_x = drift_x_current + pan_x_wave * pan_range * 0.5
        pan_y = drift_y_current + pan_y_wave * pan_range * 0.5
        hue = hue_wave * hue_range
        sat = remap(sat_wave, sat_min * 0.5, sat_max * 0.5)
        bright = remap(bright_wave, bright_min * 0.3, bright_max * 0.3)
        spd = remap(speed_wave, 0.85, 1.15)

        rotation = rotation_wave * 3  -- dream: -3 to +3 degrees

        -- Audio: bass pumps zoom, beats push brightness
        zoom = zoom + a_bass * 0.12
        bright = bright + beat_pulse * 6
        sat = sat + a_energy * 15
        rotation = rotation + beat_pulse * 4  -- beats bump rotation

    elseif current_mode == "drift" then
        zoom = remap(zoom_wave, 0.1, 0.2)
        pan_x = drift_x_current + pan_x_wave * pan_range
        pan_y = drift_y_current + pan_y_wave * pan_range
        hue = 0
        sat = 0
        spd = 1.0

        rotation = rotation_wave * 2  -- drift: -2 to +2 degrees

        -- Audio: energy modulates drift speed
        pan_x = pan_x + a_bass * pan_range * 0.5
        pan_y = pan_y + a_mid * pan_range * 0.3
        zoom = zoom + beat_pulse * 0.08
        rotation = rotation + beat_pulse * 3

    elseif current_mode == "pulse" then
        zoom = remap(zoom_wave, 0, zoom_max * 0.3)
        pan_x = drift_x_current * 0.3
        pan_y = drift_y_current * 0.3
        hue = hue_wave * hue_range * 1.5
        sat = remap(sat_wave, sat_min, sat_max)
        bright = remap(bright_wave, bright_min, bright_max)
        contrast = remap(contrast_wave, contrast_min, contrast_max)
        spd = 1.0

        rotation = rotation_wave * 5  -- pulse: -5 to +5 degrees

        -- Audio: full color pump on beats, hue shifts with high freq
        bright = bright + beat_pulse * 10
        contrast = contrast + beat_pulse * 8
        sat = sat + a_energy * 25
        hue = hue + a_high * 30
        rotation = rotation + beat_pulse * 6

    elseif current_mode == "chaos" then
        zoom = remap(zoom_wave, zoom_min, zoom_max)
        pan_x = drift_x_current + pan_x_wave * pan_range * 1.5
        pan_y = drift_y_current + pan_y_wave * pan_range * 1.5
        hue = hue_wave * hue_range * 2
        sat = remap(sat_wave, sat_min * 1.5, sat_max * 1.5)
        bright = remap(bright_wave, bright_min, bright_max)
        contrast = remap(contrast_wave, contrast_min, contrast_max)
        spd = remap(speed_wave, speed_min, speed_max)

        rotation = rotation_wave * 12  -- chaos: -12 to +12 degrees

        -- Audio: everything reacts, bass drives zoom, beats drive all
        zoom = zoom + a_bass * 0.2
        pan_x = pan_x + beat_pulse * (math.random() - 0.5) * pan_range
        pan_y = pan_y + beat_pulse * (math.random() - 0.5) * pan_range
        hue = hue + a_high * 40
        bright = bright + beat_pulse * 8
        spd = spd + a_energy * 0.4
        rotation = rotation + beat_pulse * (math.random() - 0.5) * 15

    elseif current_mode == "calm" then
        zoom = remap(zoom_wave, 0, 0.08)
        pan_x = drift_x_current * 0.1
        pan_y = drift_y_current * 0.1
        hue = 0
        sat = 0
        bright = 0
        contrast = 0
        spd = remap(speed_wave, 0.9, 1.0)

        rotation = rotation_wave * 1  -- calm: -1 to +1 degrees

        -- Audio: very subtle, just gentle breathing with energy
        zoom = zoom + a_energy * 0.05
        bright = bright + a_bass * 3
        sat = sat + a_mid * 8
        rotation = rotation + beat_pulse * 1.5

    elseif current_mode == "vortex" then
        local vortex_t = elapsed * 0.24
        zoom = remap(zoom_wave, 0.15, zoom_max)
        pan_x = math.sin(vortex_t) * pan_range * 0.8
        pan_y = math.cos(vortex_t) * pan_range * 0.8
        hue = hue_wave * hue_range * 0.5
        sat = remap(sat_wave, 0, sat_max)
        spd = remap(speed_wave, 0.6, 1.0)

        -- Vortex: continuous slow spin, -8 to +8 degrees
        rotation = rotation_wave * 8

        -- Audio: bass deepens zoom, energy speeds vortex spin
        zoom = zoom + a_bass * 0.15
        -- Modulate vortex speed with energy
        local audio_vortex = elapsed * (0.24 + a_energy * 0.15)
        pan_x = math.sin(audio_vortex) * pan_range * (0.8 + a_energy * 0.4)
        pan_y = math.cos(audio_vortex) * pan_range * (0.8 + a_energy * 0.4)
        hue = hue + a_high * 20
        rotation = rotation + a_energy * 5

    elseif current_mode == "glitch" then
        glitch_timer = glitch_timer + step
        zoom = remap(zoom_wave, 0, 0.1)
        pan_x = drift_x_current * 0.2
        pan_y = drift_y_current * 0.2

        -- Audio: beats trigger glitches instead of timer
        if audio_beat == 1 or glitch_timer >= glitch_interval then
            glitch_timer = 0
            glitch_interval = 0.3 + math.random() * 3
            glitch_active = not glitch_active
        end

        if glitch_active then
            local intensity = 0.5 + a_energy * 0.5  -- scale glitch with volume
            zoom = zoom + (math.random() - 0.3) * 0.5 * intensity
            pan_x = (math.random() - 0.5) * pan_range * 3 * intensity
            pan_y = (math.random() - 0.5) * pan_range * 3 * intensity
            hue = (math.random() - 0.5) * 180 * intensity
            sat = (math.random() - 0.5) * 80 * intensity
            bright = (math.random() - 0.5) * 20 * intensity
            contrast = (math.random() - 0.5) * 30 * intensity
            spd = 0.3 + math.random() * 2.5
            rotation = (math.random() - 0.5) * 40  -- glitch: random snaps -20 to +20
        end
    end

    -- Clamp values to safe ranges
    zoom = math.max(-0.1, math.min(0.5, zoom))
    pan_x = math.max(-0.8, math.min(0.8, pan_x))
    pan_y = math.max(-0.8, math.min(0.8, pan_y))
    hue = math.max(-180, math.min(180, hue))
    sat = math.max(-100, math.min(100, sat))
    bright = math.max(-20, math.min(20, bright))
    contrast = math.max(-20, math.min(20, contrast))
    spd = math.max(0.3, math.min(3.0, spd))
    rotation = math.max(-25, math.min(25, rotation))

    -- Apply everything
    mp.set_property_number("video-zoom", zoom)
    mp.set_property_number("video-pan-x", pan_x)
    mp.set_property_number("video-pan-y", pan_y)
    mp.set_property_number("hue", math.floor(hue))
    mp.set_property_number("saturation", math.floor(sat))
    mp.set_property_number("brightness", math.floor(bright))
    mp.set_property_number("contrast", math.floor(contrast))
    mp.set_property_number("speed", spd)
end

-- Initialize
pick_mode()
load_lut_list()

local timer = nil
mp.observe_property("vid", "string", function(_, val)
    if val and not timer then
        -- Apply first LUT immediately
        if lut_loaded then apply_next_lut() end
        timer = mp.add_periodic_timer(step, update)
    end
end)

-- Apply a new random LUT every time a new video starts
mp.register_event("start-file", function()
    if lut_loaded then
        apply_next_lut()
        lut_timer = 0  -- reset the timer so it counts from the new video start
    end
    -- Also pick a fresh mode for each video
    pick_mode()
end)
