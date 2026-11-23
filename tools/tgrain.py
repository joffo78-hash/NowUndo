"""Stretch / pitch granulaire : modulation ajoutee par les grains (note grave tenue).
cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tgrain.py . v327.jsfx [pitch] [speed]"""
import sys, math, re, importlib.util
sys.path.insert(0, sys.argv[1])
import bench, eel2py
from bench import SR, BLK
path = sys.argv[2]
PITCH = float(sys.argv[3]) if len(sys.argv) > 3 else 3.0
SPEED = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
m = bench.load(path, 'tgrain' + str(abs(hash(path)) % 1000))
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m._clock[0] = 100.0; m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
F0 = 65.0
def sig(n):  # note grave tenue, riche (3 harmoniques), legerement vibree
    t = n / SR
    ph = 2 * math.pi * F0 * t
    return 0.3 * (math.sin(ph) + 0.5 * math.sin(2 * ph + 0.3) + 0.25 * math.sin(3 * ph + 1.1))
N = [0]; OUT = []
def step(k=1, feed=True, rec=False):
    for _ in range(k):
        n0 = N[0]; m._clock[0] = 100.0 + n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; m._clock[0] = 100.0 + n / SR
            x = sig(n) if feed else 0.0
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
            if rec: OUT.append(m.v_spl0)
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; m.GM[b + 48] = c; step(2)
cmd(1); step(int(2.0 * SR / BLK)); cmd(1); step(4)
m.v_mix = 1.0
def measure(gms, gf):
    m.v_grain_ms = gms; m.v_grain_fade = gf; m.v_pitch = PITCH; m.v_speed = SPEED; m.sec_slider()
    step(int(0.6 * SR / BLK), feed=False)
    del OUT[:]
    step(int(1.2 * SR / BLK), feed=False, rec=True)
    # enveloppe : RMS sur une periode de la note transposee
    f = F0 * 2 ** (PITCH / 12) / 1.0
    w = int(SR / f) * 2
    env = []
    for s in range(0, len(OUT) - w, w // 4):
        env.append(math.sqrt(sum(v * v for v in OUT[s:s + w]) / w))
    mu = sum(env) / len(env)
    sd = math.sqrt(sum((e - mu) ** 2 for e in env) / len(env))
    return 100 * sd / max(mu, 1e-9), mu
print('note %.0f Hz, pitch %+.1f, speed %.2f : modulation d\'enveloppe (ecart-type / moyenne, %%) -- plus bas = plus lisse' % (F0, PITCH, SPEED))
for gms in (40, 80, 150):
    row = []
    for gf in (5, 25, 50):
        r, mu = measure(gms, gf); row.append('fade %2d%% : %5.1f%% (niv %.3f)' % (gf, r, mu))
    print('grain %3d ms | %s' % (gms, ' | '.join(row)))
