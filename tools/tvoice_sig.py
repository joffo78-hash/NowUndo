import math
from bench import SR
GAIN = 0.18
def voice(n):
    t = n / SR
    f0 = 196 * (1 + 0.006 * math.sin(2 * math.pi * 5.5 * t))       # vibrato
    ph = 2 * math.pi * 196 * t - 0.006 * 196 / 5.5 * math.cos(2 * math.pi * 5.5 * t)
    s = 0
    for h in range(1, 16):
        a = (1.0 / h) * (1.6 if 3 <= h <= 5 else 1.0)                 # formant grossier
        s += a * math.sin(h * ph + h * 0.7)
    return GAIN * s
