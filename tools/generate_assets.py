#!/usr/bin/env python3
"""Gera os recursos visuais e sonoros do Idle City.

- Ícones da interface (PNG, desenhados em 4x e reduzidos com antialiasing).
- Ícone do aplicativo (legado + adaptativo Android).
- Efeitos sonoros e música ambiente (WAV 16-bit mono, sintetizados).

Uso: python3 tools/generate_assets.py  (a partir da raiz do projeto)
"""
import math
import os
import random
import struct
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "icons")
AUDIO = os.path.join(ROOT, "assets", "audio")
ANDROID = os.path.join(ROOT, "assets", "launcher")
FONT = os.path.join(ROOT, "assets", "fonts", "Fredoka-Bold.woff")

S = 4  # fator de supersampling
OUT = 96  # tamanho final dos ícones


def canvas(size=OUT):
    img = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, name, size=OUT):
    img = img.resize((size, size), Image.LANCZOS)
    img.save(os.path.join(ICONS, name + ".png"))


def P(*v):
    return [c * S for c in v]


def outline_ellipse(d, box, fill, outline=(40, 44, 60, 255), w=5):
    d.ellipse(P(*box), fill=outline)
    d.ellipse(P(box[0] + w, box[1] + w, box[2] - w, box[3] - w), fill=fill)


def font(size):
    return ImageFont.truetype(FONT, size * S)


DARK = (38, 44, 66, 255)


# ----------------------------------------------------------------------------
# Ícones
# ----------------------------------------------------------------------------

def icon_coin():
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), (247, 196, 49, 255))
    d.ellipse(P(16, 16, 80, 80), fill=(255, 216, 92, 255))
    d.arc(P(16, 16, 80, 80), 200, 340, fill=(255, 240, 180, 255), width=4 * S)
    f = font(34)
    d.text((48 * S, 50 * S), "R$", font=f, fill=(196, 128, 18, 255), anchor="mm")
    save(img, "coin")


def icon_people():
    img, d = canvas()
    # pessoa de trás
    outline_ellipse(d, (50, 14, 80, 44), (120, 180, 240, 255))
    d.rounded_rectangle(P(40, 44, 90, 88), radius=18 * S, fill=DARK)
    d.rounded_rectangle(P(45, 49, 85, 88), radius=15 * S, fill=(120, 180, 240, 255))
    # pessoa da frente
    outline_ellipse(d, (18, 22, 52, 56), (255, 205, 150, 255))
    d.rounded_rectangle(P(6, 56, 64, 94), radius=20 * S, fill=DARK)
    d.rounded_rectangle(P(11, 61, 59, 94), radius=17 * S, fill=(76, 140, 230, 255))
    save(img, "people")


def face(name, color, mouth):
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), color)
    d.ellipse(P(30, 32, 40, 46), fill=DARK)
    d.ellipse(P(56, 32, 66, 46), fill=DARK)
    if mouth == "smile":
        d.arc(P(26, 34, 70, 74), 20, 160, fill=DARK, width=6 * S)
    elif mouth == "flat":
        d.line(P(32, 64, 64, 64), fill=DARK, width=6 * S)
    else:
        d.arc(P(28, 58, 68, 88), 200, 340, fill=DARK, width=6 * S)
    d.ellipse(P(18, 50, 30, 60), fill=(255, 140, 140, 140))
    d.ellipse(P(66, 50, 78, 60), fill=(255, 140, 140, 140))
    save(img, name)


def icon_hammer():
    img, d = canvas()
    # cabo
    d.polygon(P(30, 86, 22, 78, 58, 42, 66, 50), fill=DARK)
    d.polygon(P(31, 81, 27, 77, 58, 46, 62, 50), fill=(196, 132, 74, 255))
    # cabeça
    d.polygon(P(44, 30, 64, 10, 90, 36, 70, 56), fill=DARK)
    d.polygon(P(50, 30, 64, 16, 84, 36, 70, 50), fill=(150, 160, 180, 255))
    d.polygon(P(64, 16, 84, 36, 80, 40, 60, 20), fill=(205, 212, 226, 255))
    save(img, "build")


def icon_arrow_up():
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), (60, 200, 110, 255))
    d.polygon(P(48, 18, 76, 50, 60, 50, 60, 78, 36, 78, 36, 50, 20, 50), fill=(255, 255, 255, 255))
    save(img, "upgrade")


def icon_missions():
    img, d = canvas()
    d.rounded_rectangle(P(14, 12, 82, 92), radius=10 * S, fill=DARK)
    d.rounded_rectangle(P(19, 17, 77, 87), radius=7 * S, fill=(255, 250, 235, 255))
    d.rounded_rectangle(P(32, 6, 64, 22), radius=5 * S, fill=DARK)
    d.rounded_rectangle(P(36, 9, 60, 19), radius=3 * S, fill=(230, 120, 80, 255))
    for i, y in enumerate((34, 52, 70)):
        d.line(P(28, y, 34, y + 6), fill=(40, 180, 90, 255), width=5 * S)
        d.line(P(34, y + 6, 42, y - 4), fill=(40, 180, 90, 255), width=5 * S)
        d.rounded_rectangle(P(48, y - 2, 70, y + 4), radius=3 * S, fill=(150, 160, 180, 255))
    save(img, "missions")


def icon_map():
    img, d = canvas()
    pts = [(8, 22), (34, 12), (62, 22), (88, 12), (88, 76), (62, 86), (34, 76), (8, 86)]
    d.polygon(P(*sum(pts, ())), fill=DARK)
    d.polygon(P(13, 25, 34, 17, 34, 72, 13, 80), fill=(120, 200, 120, 255))
    d.polygon(P(34, 17, 62, 26, 62, 81, 34, 72), fill=(160, 220, 140, 255))
    d.polygon(P(62, 26, 83, 17, 83, 72, 62, 81), fill=(120, 200, 120, 255))
    d.line(P(20, 60, 40, 40, 56, 54, 76, 32), fill=(240, 90, 80, 255), width=4 * S)
    d.ellipse(P(68, 22, 84, 38), fill=(240, 90, 80, 255))
    save(img, "map")


def icon_gear():
    img, d = canvas()
    cx, cy = 48, 48
    pts = []
    for i in range(16):
        a = i / 16 * math.tau
        r = 42 if i % 2 == 0 else 32
        pts += [cx + math.cos(a - 0.12) * r, cy + math.sin(a - 0.12) * r, cx + math.cos(a + 0.12) * r, cy + math.sin(a + 0.12) * r]
    d.polygon(P(*pts), fill=DARK)
    pts2 = []
    for i in range(16):
        a = i / 16 * math.tau
        r = 37 if i % 2 == 0 else 28
        pts2 += [cx + math.cos(a - 0.1) * r, cy + math.sin(a - 0.1) * r, cx + math.cos(a + 0.1) * r, cy + math.sin(a + 0.1) * r]
    d.polygon(P(*pts2), fill=(170, 182, 204, 255))
    outline_ellipse(d, (34, 34, 62, 62), (238, 242, 250, 255))
    save(img, "settings")


def star_points(cx, cy, r1, r2, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = rot + i * math.pi / n
        pts += [cx + math.cos(a) * r, cy + math.sin(a) * r]
    return pts


def icon_star():
    img, d = canvas()
    d.polygon(P(*star_points(48, 52, 46, 20)), fill=DARK)
    d.polygon(P(*star_points(48, 52, 38, 16)), fill=(255, 200, 40, 255))
    d.polygon(P(*star_points(44, 46, 16, 7)), fill=(255, 236, 150, 255))
    save(img, "star")


def icon_trophy():
    img, d = canvas()
    d.arc(P(6, 18, 40, 52), 90, 270, fill=DARK, width=7 * S)
    d.arc(P(56, 18, 90, 52), 270, 90, fill=DARK, width=7 * S)
    d.polygon(P(20, 10, 76, 10, 70, 50, 48, 62, 26, 50), fill=DARK)
    d.polygon(P(25, 15, 71, 15, 66, 47, 48, 57, 30, 47), fill=(255, 196, 40, 255))
    d.rectangle(P(42, 58, 54, 74), fill=DARK)
    d.rounded_rectangle(P(24, 72, 72, 90), radius=4 * S, fill=DARK)
    d.rounded_rectangle(P(29, 76, 67, 86), radius=3 * S, fill=(196, 128, 40, 255))
    d.polygon(P(*star_points(48, 32, 12, 5)), fill=(255, 245, 200, 255))
    save(img, "trophy")


def icon_clock():
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), (250, 250, 255, 255))
    d.line(P(48, 48, 48, 22), fill=DARK, width=6 * S)
    d.line(P(48, 48, 66, 58), fill=DARK, width=6 * S)
    d.ellipse(P(42, 42, 54, 54), fill=(230, 90, 80, 255))
    save(img, "clock")


def icon_lock():
    img, d = canvas()
    d.arc(P(24, 6, 72, 60), 180, 360, fill=DARK, width=10 * S)
    d.rounded_rectangle(P(14, 38, 82, 92), radius=10 * S, fill=DARK)
    d.rounded_rectangle(P(19, 43, 77, 87), radius=7 * S, fill=(250, 196, 60, 255))
    d.ellipse(P(41, 54, 55, 68), fill=DARK)
    d.rectangle(P(45, 62, 51, 78), fill=DARK)
    save(img, "lock")


def icon_close():
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), (235, 90, 80, 255))
    d.line(P(32, 32, 64, 64), fill=(255, 255, 255, 255), width=10 * S)
    d.line(P(64, 32, 32, 64), fill=(255, 255, 255, 255), width=10 * S)
    save(img, "close")


def icon_check():
    img, d = canvas()
    outline_ellipse(d, (6, 6, 90, 90), (60, 200, 110, 255))
    d.line(P(26, 50, 42, 66), fill=(255, 255, 255, 255), width=10 * S)
    d.line(P(40, 66, 70, 32), fill=(255, 255, 255, 255), width=10 * S)
    save(img, "check")


def icon_income():
    img, d = canvas()
    d.rounded_rectangle(P(8, 8, 88, 88), radius=14 * S, fill=DARK)
    d.rounded_rectangle(P(13, 13, 83, 83), radius=11 * S, fill=(235, 248, 240, 255))
    for i, h in enumerate((20, 34, 48)):
        x = 22 + i * 20
        d.rectangle(P(x, 74 - h, x + 12, 74), fill=(60, 190, 110, 255))
    d.line(P(20, 50, 40, 36, 54, 42, 76, 20), fill=(240, 150, 40, 255), width=5 * S)
    save(img, "income")


def icon_home():
    img, d = canvas()
    d.polygon(P(48, 6, 92, 46, 80, 46, 80, 90, 16, 90, 16, 46, 4, 46), fill=DARK)
    d.polygon(P(48, 13, 84, 45, 75, 45, 75, 85, 21, 85, 21, 45, 12, 45), fill=(255, 240, 210, 255))
    d.polygon(P(48, 13, 84, 45, 12, 45), fill=(230, 90, 80, 255))
    d.rounded_rectangle(P(40, 58, 56, 85), radius=3 * S, fill=(80, 130, 210, 255))
    save(img, "home")


def icon_demolish():
    img, d = canvas()
    d.rounded_rectangle(P(20, 26, 76, 92), radius=8 * S, fill=DARK)
    d.rounded_rectangle(P(25, 31, 71, 87), radius=6 * S, fill=(235, 238, 245, 255))
    d.rounded_rectangle(P(12, 14, 84, 28), radius=5 * S, fill=DARK)
    d.rounded_rectangle(P(36, 6, 60, 18), radius=4 * S, fill=DARK)
    for x in (36, 48, 60):
        d.line(P(x, 40, x, 78), fill=(150, 160, 180, 255), width=5 * S)
    save(img, "demolish")


def icon_menu():
    img, d = canvas()
    for y in (22, 46, 70):
        d.rounded_rectangle(P(12, y - 7, 84, y + 7), radius=6 * S, fill=(255, 255, 255, 255))
    save(img, "menu")


def make_icons():
    os.makedirs(ICONS, exist_ok=True)
    icon_coin()
    icon_people()
    face("happy", (255, 210, 70, 255), "smile")
    face("neutral", (255, 200, 90, 255), "flat")
    face("sad", (250, 160, 90, 255), "sad")
    icon_hammer()
    icon_arrow_up()
    icon_missions()
    icon_map()
    icon_gear()
    icon_star()
    icon_trophy()
    icon_clock()
    icon_lock()
    icon_close()
    icon_check()
    icon_income()
    icon_home()
    icon_demolish()
    icon_menu()


# ----------------------------------------------------------------------------
# Ícone do aplicativo
# ----------------------------------------------------------------------------

def skyline(d, size, scale, offset_y):
    """Desenha uma pequena cidade cartoon (coordenadas em 0..432)."""
    k = size / 432.0
    def R(x0, y0, x1, y1):
        return [x0 * k, (y0 + offset_y) * k, x1 * k, (y1 + offset_y) * k]
    buildings = [
        (96, 210, 150, 330, (79, 163, 224)),
        (146, 150, 212, 330, (142, 111, 216)),
        (208, 120, 270, 330, (240, 140, 60)),
        (266, 180, 330, 330, (63, 191, 111)),
        (120, 250, 190, 330, (224, 90, 90)),
        (250, 240, 320, 330, (247, 196, 49)),
    ]
    for x0, y0, x1, y1, c in buildings:
        d.rounded_rectangle(R(x0, y0, x1, y1), radius=8 * k, fill=(38, 44, 66, 255))
        d.rounded_rectangle(R(x0 + 6, y0 + 6, x1 - 6, y1), radius=6 * k, fill=c + (255,))
        rows = int((y1 - y0 - 24) / 26)
        cols = max(1, int((x1 - x0 - 16) / 20))
        for r in range(rows):
            for cc in range(cols):
                wx = x0 + 12 + cc * ((x1 - x0 - 24) / cols)
                wy = y0 + 16 + r * 26
                d.rounded_rectangle(R(wx, wy, wx + 10, wy + 14), radius=2 * k, fill=(255, 238, 150, 255))
    # antena
    d.rectangle(R(236, 84, 242, 122), fill=(38, 44, 66, 255))
    d.ellipse(R(230, 72, 248, 90), fill=(235, 90, 80, 255))
    # chão
    d.rounded_rectangle(R(80, 326, 352, 344), radius=8 * k, fill=(38, 44, 66, 255))


def make_app_icons():
    os.makedirs(ANDROID, exist_ok=True)
    big = 432 * 2
    # Fundo adaptativo: céu em degradê.
    bg = Image.new("RGBA", (big, big))
    px = bg.load()
    top = np.array([80, 170, 245])
    bot = np.array([170, 225, 255])
    for y in range(big):
        t = y / (big - 1)
        c = tuple(int(v) for v in (top * (1 - t) + bot * t))
        for x in range(big):
            px[x, y] = c + (255,)
    dbg = ImageDraw.Draw(bg)
    for cx, cy, r in ((200, 250, 70), (290, 230, 90), (650, 300, 80), (560, 280, 60)):
        dbg.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=(255, 255, 255, 230))
    dbg.ellipse([-200, 640, big + 200, 1100], fill=(110, 200, 110, 255))
    bg_small = bg.resize((432, 432), Image.LANCZOS)
    bg_small.save(os.path.join(ANDROID, "icon_background_432.png"))
    # Primeiro plano adaptativo: cidade centralizada na zona segura.
    fg = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    skyline(ImageDraw.Draw(fg), big, 1.0, 0)
    fg_small = fg.resize((432, 432), Image.LANCZOS)
    fg_small.save(os.path.join(ANDROID, "icon_foreground_432.png"))
    # Ícone completo (legado e do projeto) com cantos arredondados.
    full = Image.alpha_composite(bg, fg)
    d = ImageDraw.Draw(full)
    f = ImageFont.truetype(FONT, 92)
    text = "IDLE CITY"
    for dx in range(-6, 7, 3):
        for dy in range(-6, 7, 3):
            d.text((big / 2 + dx, 770 + dy), text, font=f, fill=(38, 44, 66, 255), anchor="mm")
    d.text((big / 2, 770), text, font=f, fill=(255, 215, 60, 255), anchor="mm")
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, big - 1, big - 1], radius=150, fill=255)
    full.putalpha(mask)
    full.resize((192, 192), Image.LANCZOS).save(os.path.join(ANDROID, "icon_192.png"))
    full.resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, "icon.png"))
    full.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "assets", "sprites", "logo_icon.png"))


# ----------------------------------------------------------------------------
# Áudio
# ----------------------------------------------------------------------------

RATE = 22050


def write_wav(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    data = (samples * 32000).astype(np.int16)
    with wave.open(os.path.join(AUDIO, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def tone(freq, dur, kind="sine", vol=0.5, attack=0.005, decay=None):
    t = np.arange(int(RATE * dur)) / RATE
    if kind == "sine":
        w = np.sin(2 * np.pi * freq * t)
    elif kind == "square":
        w = np.sign(np.sin(2 * np.pi * freq * t)) * 0.5
    elif kind == "tri":
        w = 2 * np.abs(2 * ((freq * t) % 1) - 1) - 1
    else:
        w = np.random.uniform(-1, 1, t.size)
    env = np.minimum(1.0, t / max(attack, 1e-4))
    decay = decay or dur
    env *= np.exp(-t / (decay / 4))
    return w * env * vol


def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(RATE * gap)))
    return np.concatenate(out)


def mix(*arrays):
    n = max(a.size for a in arrays)
    out = np.zeros(n)
    for a in arrays:
        out[: a.size] += a
    return out


def make_audio():
    os.makedirs(AUDIO, exist_ok=True)
    np.random.seed(7)
    write_wav("click", mix(tone(880, 0.06, "sine", 0.35), tone(1320, 0.05, "sine", 0.15)))
    write_wav("coin", seq([tone(988, 0.07, "square", 0.25), mix(tone(1319, 0.28, "square", 0.25), tone(2637, 0.2, "sine", 0.08))]))
    thump = mix(tone(90, 0.25, "sine", 0.8), tone(0, 0.12, "noise", 0.25))
    chime = seq([tone(523, 0.1, "tri", 0.4), tone(659, 0.1, "tri", 0.4), tone(784, 0.25, "tri", 0.45)])
    write_wav("build", mix(thump, np.concatenate([np.zeros(int(RATE * 0.12)), chime])))
    write_wav("upgrade", seq([tone(f, 0.07, "tri", 0.4) for f in (523, 659, 784, 1047)] + [tone(1319, 0.25, "sine", 0.35)]))
    fan = seq([tone(523, 0.14, "square", 0.22), tone(659, 0.14, "square", 0.22), tone(784, 0.14, "square", 0.22)])
    final = mix(tone(1047, 0.6, "square", 0.22), tone(784, 0.6, "tri", 0.25), tone(523, 0.6, "tri", 0.25))
    write_wav("unlock", np.concatenate([fan, final]))
    write_wav("mission", seq([tone(784, 0.1, "tri", 0.4), tone(988, 0.1, "tri", 0.4), mix(tone(1175, 0.4, "tri", 0.4), tone(1568, 0.4, "sine", 0.15))]))
    write_wav("error", seq([tone(196, 0.1, "square", 0.3), tone(147, 0.18, "square", 0.3)]))
    write_wav("music", make_music())


def make_music():
    """Loop calmo de 32 compassos curtos (acordes + arpejo pentatônico)."""
    bpm = 96
    beat = 60 / bpm
    total_beats = 64
    n = int(RATE * beat * total_beats)
    out = np.zeros(n)
    chords = [
        (261.63, 329.63, 392.00),  # C
        (220.00, 261.63, 329.63),  # Am
        (174.61, 220.00, 261.63),  # F
        (196.00, 246.94, 293.66),  # G
    ]
    t_beat = int(RATE * beat)
    rng = random.Random(3)
    scale = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.5]
    for bar in range(total_beats // 4):
        ch = chords[bar % 4]
        start = bar * 4 * t_beat
        dur = 4 * beat
        t = np.arange(int(RATE * dur)) / RATE
        env = np.minimum(1, t / 0.3) * np.minimum(1, (dur - t) / 0.4)
        pad = sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t) for f in ch) * 0.045 * env
        bass = np.sin(2 * np.pi * ch[0] / 2 * t) * 0.09 * env
        seg = pad + bass
        end = min(n, start + seg.size)
        out[start:end] += seg[: end - start]
        for i in range(8):
            if rng.random() < 0.75:
                f = rng.choice(scale)
                note = tone(f, beat * 0.9, "tri", 0.07, attack=0.01, decay=beat * 1.2)
                s = start + i * t_beat // 2
                e = min(n, s + note.size)
                out[s:e] += note[: e - s]
    # leve fade nas bordas para o loop não estalar
    fade = int(RATE * 0.05)
    out[:fade] *= np.linspace(0, 1, fade)
    out[-fade:] *= np.linspace(1, 0, fade)
    return out


if __name__ == "__main__":
    make_icons()
    make_app_icons()
    make_audio()
    print("Recursos gerados.")
