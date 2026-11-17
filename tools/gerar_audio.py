"""
Gera os sons e músicas provisórios do Vale do Pequi (síntese, sem samples).
Uso: python3 tools/gerar_audio.py  (precisa de numpy)

  assets/audio/sfx/*.wav     efeitos curtos (22050 Hz, mono)
  assets/audio/musica/*.wav  loops: dia (viola caipira), noite, mina, festa (forró de festa junina)

As músicas levam um bloco "smpl" com o ponto de loop, para o Godot repetir sem emenda.
"""
import os
import struct
import wave

import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(7)


def out(path):
    p = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def save(path, x, loop=False):
    x = np.clip(x, -1.0, 1.0)
    pcm = (x * 32000).astype("<i2").tobytes()
    with wave.open(out(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    if loop:
        # bloco smpl com um loop do começo ao fim (lido pelo importador do Godot)
        n = len(x)
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        with open(out(path), "r+b") as f:
            data = f.read()
            data += b"smpl" + struct.pack("<I", len(smpl)) + smpl
            data = data[:4] + struct.pack("<I", len(data) - 8) + data[8:]
            f.seek(0)
            f.write(data)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=None):
    e = np.ones(n)
    na = max(1, int(SR * a))
    e[:na] = np.linspace(0, 1, na)
    if r is None:
        e[na:] = np.exp(-np.linspace(0, 6, n - na))
    return e


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def lowpass(x, k=0.1):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def sweep(f0, f1, d, wave_="sine"):
    tt = t(d)
    f = np.linspace(f0, f1, len(tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) if wave_ == "sine" else np.sign(np.sin(ph)) * 0.6


def pluck(freq, d, bright=0.5, decay=0.996):
    """Karplus-Strong: corda dedilhada (viola)."""
    n = int(SR * d)
    p = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, p) * 0.8
    out_ = np.zeros(n)
    for i in range(n):
        j = i % p
        v = buf[j]
        out_[i] = v
        buf[j] = decay * (bright * v + (1 - bright) * 0.5 * (v + buf[(j + 1) % p]))
    return out_


def note(name):
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    n, o = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[n] + (o - 4) * 12) / 12)


# --- efeitos -----------------------------------------------------------------

def sfx():
    def capinar():
        x = lowpass(noise(0.14), 0.25) * env(int(SR * 0.14)) * 1.6
        x[:len(t(0.08))] += np.sin(2 * np.pi * 90 * t(0.08)) * env(len(t(0.08))) * 0.6
        return x
    def regar():
        n = int(SR * 0.35)
        return lowpass(noise(0.35), 0.5) * np.sin(np.linspace(0, np.pi, n)) * 0.35
    def pegar():
        a = np.sin(2 * np.pi * note("E6") * t(0.06)) * env(len(t(0.06)))
        b = np.sin(2 * np.pi * note("A6") * t(0.09)) * env(len(t(0.09)))
        return np.concatenate([a, b]) * 0.35
    def moeda():
        a = sweep(note("B5"), note("B5"), 0.06, "square") * env(len(t(0.06)))
        b = sweep(note("E6"), note("E6"), 0.18, "square") * env(len(t(0.18)))
        return np.concatenate([a, b]) * 0.25
    def golpe():
        n = int(SR * 0.12)
        return lowpass(noise(0.12), 0.6) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.5
    def acerto():
        x = np.sin(2 * np.pi * np.linspace(160, 60, int(SR * 0.1)).cumsum() / SR) * env(int(SR * 0.1))
        return (x * 0.7 + lowpass(noise(0.1), 0.4) * env(int(SR * 0.1)) * 0.5)
    def dano():
        return sweep(440, 160, 0.22, "square") * env(int(SR * 0.22), r=None) * 0.6
    def picareta():
        tt = t(0.18)
        x = (np.sin(2 * np.pi * 1800 * tt) + 0.6 * np.sin(2 * np.pi * 2650 * tt)) * np.exp(-tt * 30)
        return x * 0.3 + lowpass(noise(0.18), 0.5) * np.exp(-tt * 40) * 0.4
    def pedra_quebra():
        n = int(SR * 0.3)
        return lowpass(noise(0.3), 0.35) * np.exp(-np.linspace(0, 5, n)) * 1.2
    def comer():
        parts = []
        for i in range(3):
            parts.append(lowpass(noise(0.06), 0.5) * env(int(SR * 0.06)) * 0.6)
            parts.append(np.zeros(int(SR * 0.06)))
        return np.concatenate(parts)
    def agua():
        tt = t(0.3)
        x = np.zeros_like(tt)
        for k in range(5):
            s = int(SR * 0.05 * k)
            b = np.sin(2 * np.pi * np.linspace(500 + 120 * k, 1200 + 150 * k, len(tt) - s).cumsum() / SR)
            x[s:] += b * np.exp(-np.linspace(0, 12, len(tt) - s)) * 0.25
        return x + lowpass(noise(0.3), 0.3) * np.exp(-tt * 8) * 0.3
    def nivel():
        notes = ["C5", "E5", "G5", "C6"]
        return np.concatenate([pluck(note(n), 0.14, 0.7) for n in notes[:-1]] + [pluck(note(notes[-1]), 0.4, 0.7)]) * 0.6
    def missao():
        seq = [("G4", 0.12), ("B4", 0.12), ("D5", 0.12), ("G5", 0.5)]
        return np.concatenate([pluck(note(n), d, 0.6) + 0.3 * pluck(note(n) / 2, d, 0.6) for n, d in seq]) * 0.55
    def porta():
        x = np.zeros(int(SR * 0.3))
        for s in (0, int(SR * 0.13)):
            k = lowpass(noise(0.07), 0.3) * env(int(SR * 0.07)) + np.sin(2 * np.pi * 180 * t(0.07)) * env(int(SR * 0.07))
            x[s:s + len(k)] += k * 0.6
        return x
    def clique():
        return np.sin(2 * np.pi * 1400 * t(0.03)) * env(int(SR * 0.03)) * 0.25
    def dialogo():
        return np.sign(np.sin(2 * np.pi * 620 * t(0.035))) * env(int(SR * 0.035)) * 0.08
    def chefe():
        tt = t(0.9)
        saw = 2 * ((55 * tt + 0.5 * np.sin(2 * np.pi * 3 * tt)) % 1.0) - 1
        return (lowpass(saw, 0.08) * 0.9 + lowpass(noise(0.9), 0.05) * 1.5) * np.sin(np.linspace(0, np.pi, len(tt))) * 0.8
    for name, fn in [("capinar", capinar), ("regar", regar), ("pegar", pegar), ("moeda", moeda), ("golpe", golpe),
                     ("acerto", acerto), ("dano", dano), ("picareta", picareta), ("pedra_quebra", pedra_quebra),
                     ("comer", comer), ("agua", agua), ("nivel", nivel), ("missao", missao), ("porta", porta),
                     ("clique", clique), ("dialogo", dialogo), ("chefe", chefe)]:
        save(f"assets/audio/sfx/{name}.wav", fn())


# --- músicas -----------------------------------------------------------------

CHORDS = {
    "G": ["G2", "D3", "G3", "B3", "D4"], "C": ["C3", "G3", "C4", "E4", "G4"], "D": ["D3", "A3", "D4", "F#4", "A4"],
    "Em": ["E2", "B2", "E3", "G3", "B3"], "Am": ["A2", "E3", "A3", "C4", "E4"], "B7": ["B2", "F#3", "A3", "B3", "D#4"],
}
SCALE_G = ["G4", "A4", "B4", "D5", "E5", "G5", "A5"]   # pentatônica de sol


def level(buf, rms):
    """Ajusta o volume pela média (RMS) e segura os picos sem estourar."""
    buf = buf * (rms / max(1e-6, np.sqrt((buf ** 2).mean())))
    return np.tanh(buf * 1.2) / 1.2


def mix(buf, x, at, gain=1.0):
    s = int(at * SR) % len(buf)
    end = s + len(x)
    if end <= len(buf):
        buf[s:end] += x * gain
    else:  # dá a volta: o rabo da nota entra no começo (loop sem emenda)
        k = len(buf) - s
        buf[s:] += x[:k] * gain
        buf[:end - len(buf)] += x[k:] * gain


def viola_track(prog, bpm, bars_per_chord, melody_density, seed, name, gain=0.5):
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm
    total = len(prog) * bars_per_chord * 4 * beat
    buf = np.zeros(int(total * SR))
    pattern = [0, 2, 3, 4, 3, 2, 3, 1]  # dedilhado de viola em colcheias
    tbar = 0.0
    for ch in prog:
        notes = CHORDS[ch]
        for bar in range(bars_per_chord):
            for i, idx in enumerate(pattern):
                mix(buf, pluck(note(notes[idx]), beat * 1.6, 0.55), tbar + i * beat / 2, 0.22)
            mix(buf, pluck(note(notes[0]) / 2, beat * 3, 0.3, 0.998), tbar, 0.35)
            mix(buf, pluck(note(notes[1]) / 2, beat * 2, 0.3, 0.998), tbar + 2 * beat, 0.25)
            # melodia (duas violas em terças, como dupla caipira)
            for i in range(8):
                if r.random() < melody_density:
                    k = r.integers(0, len(SCALE_G) - 2)
                    f = note(SCALE_G[k])
                    mix(buf, pluck(f, beat * 1.2, 0.7), tbar + i * beat / 2, 0.18)
                    mix(buf, pluck(f * 2 ** (4 / 12), beat * 1.2, 0.7), tbar + i * beat / 2, 0.10)
            tbar += 4 * beat
    buf = level(buf, 0.09 * gain / 0.5)
    save(f"assets/audio/musica/{name}.wav", buf, loop=True)


def mina_track():
    total = 24.0
    tt = np.arange(int(total * SR)) / SR
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * tt / total * 2)
    drone = (np.sin(2 * np.pi * 55 * tt) + 0.5 * np.sin(2 * np.pi * 82.5 * tt) + 0.25 * np.sin(2 * np.pi * 110.3 * tt)) * (0.25 + 0.2 * lfo)
    buf = drone * 0.5
    r = np.random.default_rng(3)
    for k in range(18):  # gotas d'água ecoando
        at = r.uniform(0, total)
        f = note(r.choice(["E5", "G5", "B5", "D6", "E6"]))
        drop = pluck(f, 1.5, 0.8, 0.997)
        mix(buf, drop, at, 0.12)
        mix(buf, drop, at + 0.35, 0.05)
    buf = level(buf, 0.07)
    save("assets/audio/musica/mina.wav", buf, loop=True)


def festa_track():
    bpm = 132
    beat = 60.0 / bpm
    prog = ["G", "G", "D", "D", "D", "D", "G", "G"]
    total = len(prog) * 4 * beat
    buf = np.zeros(int(total * SR))
    r = np.random.default_rng(5)
    kick = np.sin(2 * np.pi * np.linspace(120, 45, int(SR * 0.18)).cumsum() / SR) * env(int(SR * 0.18))
    tri = np.sin(2 * np.pi * 4200 * t(0.05)) * np.exp(-t(0.05) * 60)
    for b, ch in enumerate(prog):
        t0 = b * 4 * beat
        for q in range(16):  # triângulo em semicolcheias
            mix(buf, tri, t0 + q * beat / 4, 0.12 if q % 2 else 0.2)
        for at in (0, 1.5, 2, 3.5):  # zabumba
            mix(buf, kick, t0 + at * beat, 0.6)
        notes = CHORDS[ch]
        for at in (0.5, 1, 2.5, 3):  # sanfona (acorde "quadradinho")
            tt = t(beat * 0.45)
            chord = sum(np.sign(np.sin(2 * np.pi * note(n) * tt)) for n in notes[2:]) / 3
            mix(buf, lowpass(chord, 0.25) * np.sin(np.linspace(0, np.pi, len(tt))), t0 + at * beat, 0.18)
        for i in range(8):  # melodia de sanfona
            if r.random() < 0.6:
                f = note(SCALE_G[r.integers(0, len(SCALE_G))])
                tt = t(beat * 0.45)
                mix(buf, lowpass(np.sign(np.sin(2 * np.pi * f * tt)), 0.3) * env(len(tt), 0.01), t0 + i * beat / 2, 0.12)
    buf = level(buf, 0.09)
    save("assets/audio/musica/festa.wav", buf, loop=True)


if __name__ == "__main__":
    sfx()
    viola_track(["G", "C", "D", "G", "Em", "C", "D", "G"], 96, 1, 0.35, 11, "dia")
    viola_track(["Em", "Am", "C", "B7", "Em", "C", "Am", "B7"], 66, 1, 0.18, 12, "noite", 0.4)
    mina_track()
    festa_track()
    print("Áudio gerado.")
