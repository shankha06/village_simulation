"""Generate placeholder audio assets for The Hollow Village RPG.

Uses only Python stdlib (wave, struct, math, random) -- no external deps.
Run with: uv run python tools/generate_audio.py
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
        return i / fade_in
    if i > total - fade_out:
        return (total - i) / fade_out
    return 1.0


# ---------------------------------------------------------------------------
# Sound Effects
# ---------------------------------------------------------------------------

def gen_footstep(path: str, seed_val: int):
    """Short thud -- low frequency noise burst ~50ms."""
    random.seed(seed_val)
    dur = int(SFX_RATE * 0.05)
    fade_out_len = int(dur * 0.6)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 5, fade_out_len)
        noise = random.uniform(-1, 1)
        # Low-pass approximation: mix noise with a low sine
        low = math.sin(2 * math.pi * (60 + seed_val % 30) * i / SFX_RATE)
        val = (noise * 0.4 + low * 0.6) * env * 0.7
        samples.append(clamp16(val * 32767))
    write_wav(path, samples)


def gen_text_blip(path: str):
    """Short chirp ~30ms, medium pitch."""
    dur = int(SFX_RATE * 0.03)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 3, int(dur * 0.5))
        t = i / SFX_RATE
        val = math.sin(2 * math.pi * 440 * t) * 0.5
        val += math.sin(2 * math.pi * 880 * t) * 0.15
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


def gen_menu_select(path: str):
    """UI click ~40ms, clean tone."""
    dur = int(SFX_RATE * 0.04)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 3, int(dur * 0.5))
        t = i / SFX_RATE
        val = math.sin(2 * math.pi * 600 * t) * 0.6
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


def gen_menu_hover(path: str):
    """Softer UI hover ~30ms."""
    dur = int(SFX_RATE * 0.03)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 3, int(dur * 0.5))
        t = i / SFX_RATE
        val = math.sin(2 * math.pi * 500 * t) * 0.35
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


def gen_item_pickup(path: str):
    """Rising tone ~100ms, positive feeling."""
    dur = int(SFX_RATE * 0.1)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 5, int(dur * 0.3))
        t = i / SFX_RATE
        freq = 400 + 600 * (i / dur)  # Rise from 400 to 1000 Hz
        val = math.sin(2 * math.pi * freq * t) * 0.5
        val += math.sin(2 * math.pi * freq * 2 * t) * 0.15
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


def gen_door_open(path: str):
    """Creaky sound ~200ms, low frequency sweep."""
    random.seed(42)
    dur = int(SFX_RATE * 0.2)
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 10, int(dur * 0.3))
        t = i / SFX_RATE
        # Low sweep with noise for creak
        freq = 80 + 120 * (i / dur)
        creak = math.sin(2 * math.pi * freq * t)
        noise = random.uniform(-1, 1) * 0.3
        # Modulate noise with a slow oscillation for creaky feel
        mod = math.sin(2 * math.pi * 15 * t) * 0.5 + 0.5
        val = (creak * 0.5 + noise * mod * 0.5) * env * 0.6
        samples.append(clamp16(val * 32767))
    write_wav(path, samples)


def gen_notification(path: str):
    """Two-tone chime ~150ms."""
    dur = int(SFX_RATE * 0.15)
    half = dur // 2
    samples = []
    for i in range(dur):
        env = fade_env(i, dur, 5, int(dur * 0.25))
        t = i / SFX_RATE
        freq = 523.25 if i < half else 659.25  # C5 then E5
        val = math.sin(2 * math.pi * freq * t) * 0.5
        val += math.sin(2 * math.pi * freq * 2 * t) * 0.1
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


def gen_quest_update(path: str):
    """Triumphant short fanfare ~300ms."""
    dur = int(SFX_RATE * 0.3)
    third = dur // 3
    samples = []
    # Three ascending notes: C5, E5, G5
    freqs = [523.25, 659.25, 783.99]
    for i in range(dur):
        env = fade_env(i, dur, 10, int(dur * 0.2))
        t = i / SFX_RATE
        note_idx = min(i // third, 2)
        freq = freqs[note_idx]
        val = math.sin(2 * math.pi * freq * t) * 0.45
        val += math.sin(2 * math.pi * freq * 1.5 * t) * 0.15  # Fifth harmonic
        val += math.sin(2 * math.pi * freq * 2 * t) * 0.1
        samples.append(clamp16(val * env * 32767))
    write_wav(path, samples)


# ---------------------------------------------------------------------------
# Ambient Sounds
# ---------------------------------------------------------------------------

def gen_village_day(path: str):
    """10 seconds: wind, distant bird calls, subtle rustling."""
    random.seed(123)
    dur = SFX_RATE * 10
    fade_len = SFX_RATE  # 1 second fades
    samples = []

    # Pre-generate bird call timings (short chirps at random times)
    bird_events = []
    for _ in range(15):
        start = random.randint(SFX_RATE, dur - SFX_RATE)
        freq = random.uniform(2000, 4000)
        length = random.randint(int(SFX_RATE * 0.05), int(SFX_RATE * 0.15))
        bird_events.append((start, freq, length))

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / SFX_RATE

        # Wind: filtered noise with slow modulation
        wind_mod = math.sin(2 * math.pi * 0.15 * t) * 0.3 + 0.5
        wind = random.uniform(-1, 1) * wind_mod * 0.12

        # Rustling: higher freq noise, intermittent
        rustle_mod = max(0, math.sin(2 * math.pi * 0.4 * t + 1.0))
        rustle = random.uniform(-1, 1) * rustle_mod * 0.05

        # Bird calls
        bird = 0.0
        for (bs, bf, bl) in bird_events:
            if bs <= i < bs + bl:
                local_t = (i - bs) / SFX_RATE
                bird_env = fade_env(i - bs, bl, 10, bl // 3)
                bird += math.sin(2 * math.pi * bf * local_t) * 0.08 * bird_env

        val = (wind + rustle + bird) * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


def gen_village_night(path: str):
    """10 seconds: crickets, wind, occasional owl hoot."""
    random.seed(456)
    dur = SFX_RATE * 10
    fade_len = SFX_RATE
    samples = []

    # Owl hoots
    owl_events = []
    for _ in range(3):
        start = random.randint(SFX_RATE * 2, dur - SFX_RATE * 2)
        owl_events.append(start)

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / SFX_RATE

        # Wind (darker, lower)
        wind_mod = math.sin(2 * math.pi * 0.1 * t) * 0.25 + 0.4
        wind = random.uniform(-1, 1) * wind_mod * 0.1

        # Crickets: high-freq pulsing
        cricket_pulse = max(0, math.sin(2 * math.pi * 8 * t))  # 8 Hz pulse
        cricket = math.sin(2 * math.pi * 4500 * t) * cricket_pulse * 0.06

        # Owl hoots (low tone ~300 Hz, ~0.3s)
        owl = 0.0
        hoot_dur = int(SFX_RATE * 0.3)
        for os_start in owl_events:
            if os_start <= i < os_start + hoot_dur:
                local_t = (i - os_start) / SFX_RATE
                owl_env = fade_env(i - os_start, hoot_dur, int(hoot_dur * 0.15), int(hoot_dur * 0.5))
                owl += math.sin(2 * math.pi * 300 * local_t) * 0.15 * owl_env
            # Second hoot shortly after
            second = os_start + int(SFX_RATE * 0.5)
            if second <= i < second + hoot_dur:
                local_t = (i - second) / SFX_RATE
                owl_env = fade_env(i - second, hoot_dur, int(hoot_dur * 0.15), int(hoot_dur * 0.5))
                owl += math.sin(2 * math.pi * 280 * local_t) * 0.12 * owl_env

        val = (wind + cricket + owl) * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples)


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------

def gen_ashvale_theme(path: str):
    """30 seconds of dark ambient minor key drone."""
    dur = MUSIC_RATE * 30
    fade_len = MUSIC_RATE * 2  # 2 second fades
    random.seed(789)
    samples = []

    for i in range(dur):
        env = fade_env(i, dur, fade_len, fade_len)
        t = i / MUSIC_RATE

        # LFO for breathing feel
        lfo = math.sin(2 * math.pi * 0.08 * t) * 0.3 + 0.7  # Slow pulse

        # Base drone: A2 (110 Hz)
        base = math.sin(2 * math.pi * 110 * t) * 0.25

        # Fifth: E3 (165 Hz), fading in/out with slower LFO
        fifth_env = math.sin(2 * math.pi * 0.05 * t) * 0.5 + 0.5
        fifth = math.sin(2 * math.pi * 165 * t) * 0.15 * fifth_env

        # Minor third: C3 (130.8 Hz), very subtle
        minor_env = math.sin(2 * math.pi * 0.03 * t + 1.0) * 0.5 + 0.5
        minor = math.sin(2 * math.pi * 130.8 * t) * 0.08 * minor_env

        # Sub-bass octave below: A1 (55 Hz), subtle
        sub = math.sin(2 * math.pi * 55 * t) * 0.1

        # High-frequency shimmer (2000-4000 Hz), very low volume
        shimmer = 0.0
        # Multiple detuned high partials
        for freq in [2200, 2800, 3300, 3900]:
            shimmer_lfo = math.sin(2 * math.pi * (0.1 + freq * 0.0001) * t)
            shimmer += math.sin(2 * math.pi * freq * t) * 0.008 * max(0, shimmer_lfo)

        # Occasional subtle noise texture
        noise = random.uniform(-1, 1) * 0.015

        val = (base + fifth + minor + sub + shimmer + noise) * lfo * env
        samples.append(clamp16(val * 32767))

    write_wav(path, samples, MUSIC_RATE)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ensure_dirs()
    print("Generating sound effects...")
    gen_footstep(os.path.join(SFX_DIR, "footstep_1.wav"), 1)
    gen_footstep(os.path.join(SFX_DIR, "footstep_2.wav"), 2)
    gen_footstep(os.path.join(SFX_DIR, "footstep_3.wav"), 3)
    gen_text_blip(os.path.join(SFX_DIR, "text_blip.wav"))
    gen_menu_select(os.path.join(SFX_DIR, "menu_select.wav"))
    gen_menu_hover(os.path.join(SFX_DIR, "menu_hover.wav"))
    gen_item_pickup(os.path.join(SFX_DIR, "item_pickup.wav"))
    gen_door_open(os.path.join(SFX_DIR, "door_open.wav"))
    gen_notification(os.path.join(SFX_DIR, "notification.wav"))
    gen_quest_update(os.path.join(SFX_DIR, "quest_update.wav"))

    print("\nGenerating ambient sounds...")
    gen_village_day(os.path.join(AMB_DIR, "village_day.wav"))
    gen_village_night(os.path.join(AMB_DIR, "village_night.wav"))

    print("\nGenerating music...")
    gen_ashvale_theme(os.path.join(MUS_DIR, "ashvale_theme.wav"))

    print("\nDone! All audio assets generated.")


if __name__ == "__main__":
    main()
