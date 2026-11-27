"""Auto-Replace sans signal d'entree : la boucle ne doit PAS changer. Variantes : base, pitch (granulaire), D, link, slicer, rev, speed.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tautorep.py . [variante] [bruit]"""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
var = sys.argv[2] if len(sys.argv) > 2 else 'base'
noise = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
path = 'v327.jsfx'
A = load(path, 'ar_' + var); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m.v_manual_id = 1.0; m.sec_init()
if len(sys.argv) > 4: m.v_trans_sens = float(sys.argv[4])
m.sec_slider()
N = [0]; inp = [True]
import random
random.seed(1)
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; A._clock[0] = n / SR
            x = ((0.4 * math.sin(2 * math.pi * 220 * n / SR) * (1 if (n % 24000) < 12000 else 0)) if inp[0] else 0.0) + noise * (random.random() * 2 - 1)
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
b = 1000 + int(m.v_inst_idx) * 600
def cmd(c, a=None):
    if a is not None: GM[b + 49] = a
    GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
cmd(1); step(secs(1.0)); cmd(1); step(4); inp[0] = False; step(secs(0.3))
L = int(m.v_length)
if var == 'pitch': m.v_pitch = 5.0; m.sec_slider()
if var == 'd': m.v_pitch = 5.0; m.v_dub_raw = 1.0; m.v_slider68 = 1.0; m.sec_slider()
if var == 'link': m.v_pitch = 5.0; m.v_link_on = 1.0; m.sec_slider()
if var == 'speed': m.v_speed = 2.0; m.sec_slider()
if var == 'slicer': cmd(6); step(2)
if var == 'rev': cmd(4); step(2)
step(secs(0.6))
def snap():
    base = int(m.v_left_buf); return [A.M[base + k] for k in range(L)]
before = snap()
RC = 9 if var.startswith('auto') else 10
if RC == 9: cmd(19); step(2)   # bouton Auto du looper
cmd(RC); step(secs(3.0))
st = m.v_state
cmd(RC); step(secs(0.3))
after = snap()
diff = max(abs(a - c) for a, c in zip(before, after))
# puis on JOUE pendant l'auto-replace (doit remplacer) : note forte dans un trou de la boucle
before2 = after
inp[0] = True; cmd(RC); step(secs(1.0)); cmd(RC); inp[0] = False; step(secs(0.2))
after2 = snap()
d2 = max(abs(a - c) for a, c in zip(before2, after2))
print("   jeu pendant l'auto-replace : ecart %.3f" % d2, "OK (remplace)" if d2 > 0.1 else "RIEN REMPLACE")
print(var, "bruit", noise, "| etat pendant :", st, "| ecart max dans la boucle : %.4f" % diff, "OK" if diff < 1e-3 else "ECRASE")
