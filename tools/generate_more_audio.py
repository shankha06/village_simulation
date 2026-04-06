"""Generate additional audio assets for The Hollow Village RPG.

Uses only Python stdlib (wave, struct, math, random) -- no external deps.
Run with: uv run python tools/generate_more_audio.py
"""

import math
import os
import random
import struct
import wave

BASE_DIR = os.path.join(os.path.dirname(__file__), "..")
SFX_DIR = os.path.join(BASE_DIR, "assets", "audio", "sfx")
AMB_DIR = os.path.join(BASE_DIR, "assets", "audio", "ambience")
MUS_DIR = os.path.join(BASE_DIR, "assets", "audio", "music")

SFX_RATE = 22050
MUSIC_RATE = 44100


def ensure_dirs():
    for d in (SFX_DIR, AMB_DIR, MUS_DIR):
        os.makedirs(d, exist_ok=True)


def write_wav(path: str, samples: list[int], sample_rate: int = SFX_RATE):
    """Write mono 16-bit WAV."""
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        data = b"".join(struct.pack("<h", max(-32768, min(32767, s))) for s in samples)
        w.writeframes(data)
    print(f"  Written: {os.path.relpath(path, BASE_DIR)}")


def clamp16(v: float) -> int:
    return max(-32768, min(32767, int(v)))


def fade_env(i: int, total: int, fade_in: int, fade_out: int) -> float:
    """Linear fade-in / fade-out envelope."""
    if i < fade_in:
        return i / max(fade_in, 1)
    if i > total - fade_out:
        return (total - i) / max(fade_out, 1)
    return 1.0


# ---------------------------------------------------------------------------
# Sound Effects
# ---------------------------------------------------------------------------

def gen_ghost_whisper(path: str):
    """Ethereal breathy whisper, 300ms, high-frequency with reverb-like decay."""
    random.seed(666)
    dur = int(SFX_RATE * 0.3)
    samples = []
    # Simple delay buffer for reverb-like effect
    delay_len = int(SFX_RATE * 0.05)
    delay_buf = [0.0] * delay_len
    delay_idx = 0

    for i in range(dur):
        env = fade_env(i, dur, int(dur * 0.1), int(dur * 0.6))
        t = i / SFX_RATE

        # Breathy noise filtered to high frequencies
        noise = random.uniform(-1, 1)
        # High-pass approximation: subtract smoothed version
        high_noise = noise * 0.6

        # Ethereal tone: multiple high-frequency sines with vibrato
        vibrato = math.sin(2 * math.pi * 6 * t) * 20
        tone1 = math.sin(2 * math.pi * (2000 + vibrato) * t) * 0.15
        tone2 = math.sin(2 * math.pi * (2800 + vibrato * 1.3) * t) * 0.1
        tone3 = math.sin(2 * math.pi * (3500 - vibrato) * t) * 0.05

        # Whisper formant: shaped noise
        formant_mod = math.sin(2 * math.pi * 12 * t) * 0.3 + 0.7
        whisper = high_noise * formant_mod * 0.25

        dry = (tone1 + tone2 + tone3 + whisper) * env

        # Simple feedback delay for reverb
        wet = delay_buf[delay_idx] * 0.4
        delay_buf[delay_idx] = dry + wet * 0.3
        delay_idx = (delay_idx + 1) % delay_len

        val = dry * 0.7 + wet * 0.3
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_root_pulse(path: str):
    """Deep bass throb, 500ms, like a heartbeat underground (40-60Hz sine)."""
    dur = int(SFX_RATE * 0.5)
    samples = []

    for i in range(dur):
        t = i / SFX_RATE
        progress = i / dur

        # Two-beat heartbeat pattern
        beat1_center = 0.15
        beat2_center = 0.35
        beat1_env = math.exp(-((progress - beat1_center) ** 2) / 0.003)
        beat2_env = math.exp(-((progress - beat2_center) ** 2) / 0.005) * 0.7

        combined_env = beat1_env + beat2_env

        # Deep bass: 50Hz fundamental with subtle harmonics
        bass = math.sin(2 * math.pi * 50 * t) * 0.6
        bass += math.sin(2 * math.pi * 40 * t) * 0.2
        bass += math.sin(2 * math.pi * 60 * t) * 0.15
        # Sub-harmonic rumble
        sub = math.sin(2 * math.pi * 25 * t) * 0.1

        val = (bass + sub) * combined_env
        # Overall fade out
        val *= fade_env(i, dur, 10, int(dur * 0.2))
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_compass_spin(path: str):
    """Metallic ticking that accelerates, 400ms."""
    dur = int(SFX_RATE * 0.4)
    samples = []
    random.seed(42)

    for i in range(dur):
        t = i / SFX_RATE
        progress = i / dur
        env = fade_env(i, dur, 5, int(dur * 0.15))

        # Accelerating tick rate: starts at 4Hz, ends at 40Hz
        tick_freq = 4 + 36 * (progress ** 2)
        # Sharp tick using rectified sine
        tick_wave = max(0, math.sin(2 * math.pi * tick_freq * t))
        tick_sharp = 1.0 if tick_wave > 0.95 else 0.0

        # Metallic ring on each tick
        ring_freq = 3200 + 800 * math.sin(2 * math.pi * 0.5 * t)
        ring = math.sin(2 * math.pi * ring_freq * t) * tick_sharp * 0.4
        ring2 = math.sin(2 * math.pi * 4800 * t) * tick_sharp * 0.15

        # Subtle mechanical noise
        mech = random.uniform(-1, 1) * tick_sharp * 0.1

        val = (ring + ring2 + mech) * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_parchment_rustle(path: str):
    """Dry scratchy sound, 200ms (filtered white noise)."""
    random.seed(123)
    dur = int(SFX_RATE * 0.2)
    samples = []
    prev = 0.0

    for i in range(dur):
        env = fade_env(i, dur, int(dur * 0.05), int(dur * 0.4))
        t = i / SFX_RATE

        # White noise
        noise = random.uniform(-1, 1)

        # Band-pass approximation: high-pass then low-pass
        # Simple high-pass: subtract running average
        hp = noise - prev * 0.3
        prev = noise

        # Crinkle modulation: intermittent bursts
        crinkle = abs(math.sin(2 * math.pi * 25 * t)) ** 4
        crinkle2 = abs(math.sin(2 * math.pi * 40 * t + 1.5)) ** 6

        modulator = max(crinkle, crinkle2)

        val = hp * modulator * env * 0.6
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_bell_toll(path: str):
    """Single deep bell, 1000ms, slow decay (100Hz + harmonics)."""
    dur = int(SFX_RATE * 1.0)
    samples = []

    for i in range(dur):
        t = i / SFX_RATE
        progress = i / dur

        # Bell strike envelope: sharp attack, long exponential decay
        strike_env = math.exp(-t * 3.0)

        # Fundamental: 100Hz
        fundamental = math.sin(2 * math.pi * 100 * t) * 0.35

        # Bell harmonics (non-integer ratios give bell-like quality)
        h1 = math.sin(2 * math.pi * 200.3 * t) * 0.25 * math.exp(-t * 3.5)
        h2 = math.sin(2 * math.pi * 303.7 * t) * 0.18 * math.exp(-t * 4.0)
        h3 = math.sin(2 * math.pi * 512.2 * t) * 0.12 * math.exp(-t * 5.0)
        h4 = math.sin(2 * math.pi * 698.5 * t) * 0.08 * math.exp(-t * 6.0)
        h5 = math.sin(2 * math.pi * 1047.0 * t) * 0.04 * math.exp(-t * 8.0)

        # Initial strike transient
        strike = 0.0
        if t < 0.01:
            strike = random.uniform(-1, 1) * (1 - t / 0.01) * 0.3

        val = (fundamental + h1 + h2 + h3 + h4 + h5) * strike_env + strike
        val *= fade_env(i, dur, 5, int(dur * 0.05))
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


# ---------------------------------------------------------------------------
# Ambient Sounds
# ---------------------------------------------------------------------------

def gen_catacombs(path: str):
    """10 seconds: dripping water, distant echoes, faint breathing (very creepy)."""
    random.seed(333)
    dur = SFX_RATE * 10
    fade_len = SFX_RATE  # 1 second fades
    samples = []

    # Pre-generate drip timings
    drip_events = []
    t_pos = random.uniform(0.5, 2.0)
    while t_pos < 9.5:
        drip_events.append(int(t_pos * SFX_RATE))
        t_pos += random.uniform(0.8, 3.0)

    # Echo events (distant thuds/groans)
    echo_events = []
    for _ in range(4):
        start = random.randint(SFX_RATE * 2, dur - SFX_RATE * 2)
        freq = random.uniform(60, 120)
        echo_events.append((start, freq))

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / SFX_RATE

        # Base: very low rumble, almost felt not heard
        rumble = math.sin(2 * math.pi * 30 * t) * 0.03
        rumble += random.uniform(-1, 1) * 0.015

        # Dripping water
        drip = 0.0
        drip_dur_samples = int(SFX_RATE * 0.04)
        for ds in drip_events:
            if ds <= i < ds + drip_dur_samples:
                local_i = i - ds
                local_t = local_i / SFX_RATE
                drip_env = fade_env(local_i, drip_dur_samples, 3, int(drip_dur_samples * 0.7))
                # High-pitched plop
                drip += math.sin(2 * math.pi * 2500 * local_t) * 0.12 * drip_env
                drip += math.sin(2 * math.pi * 3800 * local_t) * 0.06 * drip_env
            # Echo of drip
            echo_delay = int(SFX_RATE * 0.15)
            if ds + echo_delay <= i < ds + echo_delay + drip_dur_samples:
                local_i = i - ds - echo_delay
                local_t = local_i / SFX_RATE
                drip_env = fade_env(local_i, drip_dur_samples, 3, int(drip_dur_samples * 0.7))
                drip += math.sin(2 * math.pi * 2500 * local_t) * 0.04 * drip_env

        # Faint breathing: slow sine modulation of noise
        breath_rate = 0.22  # ~13 breaths per minute, slow and creepy
        breath_mod = max(0, math.sin(2 * math.pi * breath_rate * t))
        breathing = random.uniform(-1, 1) * breath_mod * 0.02

        # Distant echoes/groans
        echo = 0.0
        echo_dur_samples = int(SFX_RATE * 0.8)
        for (es, ef) in echo_events:
            if es <= i < es + echo_dur_samples:
                local_i = i - es
                local_t = local_i / SFX_RATE
                echo_env = fade_env(local_i, echo_dur_samples, int(echo_dur_samples * 0.3), int(echo_dur_samples * 0.5))
                echo += math.sin(2 * math.pi * ef * local_t) * 0.04 * echo_env
                echo += math.sin(2 * math.pi * ef * 1.5 * local_t) * 0.02 * echo_env

        val = (rumble + drip + breathing + echo) * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_heartwood_clearing(path: str):
    """10 seconds: deep bass drone, bird-like whistles, wind through giant leaves."""
    random.seed(777)
    dur = SFX_RATE * 10
    fade_len = SFX_RATE
    samples = []

    # Bird whistle events (forest communication)
    bird_events = []
    for _ in range(8):
        start = random.randint(SFX_RATE, dur - SFX_RATE)
        base_freq = random.uniform(1800, 3500)
        length = random.randint(int(SFX_RATE * 0.1), int(SFX_RATE * 0.3))
        sweep = random.uniform(-500, 500)  # Frequency sweep
        bird_events.append((start, base_freq, length, sweep))

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / SFX_RATE

        # Deep bass drone: 55Hz (A1) with slow LFO
        lfo = math.sin(2 * math.pi * 0.06 * t) * 0.3 + 0.7
        drone = math.sin(2 * math.pi * 55 * t) * 0.2 * lfo
        drone += math.sin(2 * math.pi * 82.5 * t) * 0.08 * lfo  # Fifth
        drone += math.sin(2 * math.pi * 110 * t) * 0.05 * lfo  # Octave

        # Root pulse: very slow, deep
        root_pulse = math.sin(2 * math.pi * 0.5 * t)
        root_bass = math.sin(2 * math.pi * 35 * t) * 0.06 * max(0, root_pulse)

        # Wind through giant leaves: filtered noise with slow modulation
        wind_mod = math.sin(2 * math.pi * 0.12 * t) * 0.4 + 0.5
        wind = random.uniform(-1, 1) * wind_mod * 0.08
        # Leaf rustle: higher frequency bursts
        rustle_mod = max(0, math.sin(2 * math.pi * 0.3 * t + 2.0)) ** 3
        rustle = random.uniform(-1, 1) * rustle_mod * 0.04

        # Bird-like whistles (forest communication)
        bird = 0.0
        for (bs, bf, bl, bsweep) in bird_events:
            if bs <= i < bs + bl:
                local_i = i - bs
                local_t = local_i / SFX_RATE
                progress = local_i / bl
                bird_env = fade_env(local_i, bl, int(bl * 0.1), int(bl * 0.3))
                freq = bf + bsweep * progress
                bird += math.sin(2 * math.pi * freq * local_t) * 0.07 * bird_env
                bird += math.sin(2 * math.pi * freq * 2.01 * local_t) * 0.02 * bird_env

        val = (drone + root_bass + wind + rustle + bird) * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------

def gen_thornwood_theme(path: str):
    """30 seconds: darker ashvale_theme, lower register, minor key,
    with occasional high-frequency 'bird calls' (forest communication).
    44100Hz."""
    dur = MUSIC_RATE * 30
    fade_len = MUSIC_RATE * 2
    random.seed(999)
    samples = []

    # Pre-generate forest call events
    call_events = []
    for _ in range(12):
        start = random.randint(MUSIC_RATE * 3, dur - MUSIC_RATE * 3)
        freq = random.uniform(2500, 4500)
        length = random.randint(int(MUSIC_RATE * 0.08), int(MUSIC_RATE * 0.25))
        sweep_dir = random.choice([-1, 1])
        call_events.append((start, freq, length, sweep_dir))

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / MUSIC_RATE

        # Slow LFO for breathing feel -- slower and deeper than ashvale
        lfo = math.sin(2 * math.pi * 0.05 * t) * 0.35 + 0.65

        # Base drone: D2 (73.42 Hz) -- lower and darker
        base = math.sin(2 * math.pi * 73.42 * t) * 0.28

        # Minor third: F2 (87.31 Hz)
        minor_env = math.sin(2 * math.pi * 0.025 * t + 0.5) * 0.5 + 0.5
        minor = math.sin(2 * math.pi * 87.31 * t) * 0.12 * minor_env

        # Fifth: A2 (110 Hz), fading in and out
        fifth_env = math.sin(2 * math.pi * 0.04 * t) * 0.5 + 0.5
        fifth = math.sin(2 * math.pi * 110 * t) * 0.1 * fifth_env

        # Sub-bass: D1 (36.71 Hz)
        sub = math.sin(2 * math.pi * 36.71 * t) * 0.15

        # Diminished tension: Ab2 (103.83 Hz), very subtle, appearing periodically
        dim_env = max(0, math.sin(2 * math.pi * 0.02 * t + 2.0)) ** 4
        dim = math.sin(2 * math.pi * 103.83 * t) * 0.06 * dim_env

        # Dark shimmer: lower frequency range than ashvale, detuned
        shimmer = 0.0
        for freq in [1100, 1500, 1900, 2300]:
            s_lfo = math.sin(2 * math.pi * (0.08 + freq * 0.00008) * t)
            shimmer += math.sin(2 * math.pi * freq * t) * 0.006 * max(0, s_lfo)

        # Forest communication calls
        calls = 0.0
        for (cs, cf, cl, sd) in call_events:
            if cs <= i < cs + cl:
                local_i = i - cs
                local_t = local_i / MUSIC_RATE
                progress = local_i / cl
                call_env = fade_env(local_i, cl, int(cl * 0.1), int(cl * 0.4))
                call_freq = cf + sd * 300 * progress
                calls += math.sin(2 * math.pi * call_freq * local_t) * 0.025 * call_env
                calls += math.sin(2 * math.pi * call_freq * 1.5 * local_t) * 0.008 * call_env

        # Noise texture: slightly more present than ashvale
        noise = random.uniform(-1, 1) * 0.02

        # Root pulse: very slow deep throb unique to thornwood
        root_pulse = max(0, math.sin(2 * math.pi * 0.15 * t)) ** 8
        root = math.sin(2 * math.pi * 30 * t) * 0.08 * root_pulse

        val = (base + minor + fifth + sub + dim + shimmer + calls + noise + root) * lfo * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples, MUSIC_RATE)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ensure_dirs()

    print("Generating new sound effects...")
    gen_ghost_whisper(os.path.join(SFX_DIR, "ghost_whisper.wav"))
    gen_root_pulse(os.path.join(SFX_DIR, "root_pulse.wav"))
    gen_compass_spin(os.path.join(SFX_DIR, "compass_spin.wav"))
    gen_parchment_rustle(os.path.join(SFX_DIR, "parchment_rustle.wav"))
    gen_bell_toll(os.path.join(SFX_DIR, "bell_toll.wav"))

    print("\nGenerating new ambient sounds...")
    gen_catacombs(os.path.join(AMB_DIR, "catacombs.wav"))
    gen_heartwood_clearing(os.path.join(AMB_DIR, "heartwood_clearing.wav"))

    print("\nGenerating new music...")
    gen_thornwood_theme(os.path.join(MUS_DIR, "thornwood_theme.wav"))

    print("\nDone! All additional audio assets generated.")


if __name__ == "__main__":
    main()
