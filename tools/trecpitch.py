"""1er REC avec Pitch +12, Link off : longueur de la boucle et hauteur restituee."""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]; mode = float(sys.argv[3]); link = float(sys.argv[4])
A = load(path, 'rp' + str(abs(hash((path, mode, link))))); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m.v_manual_id = 1.0; m.sec_init(); m.v_pitch = 12.0; m.v_dub_raw = mode; m.v_link_on = link; m.sec_slider()
out = []; N = [0]; rec = [True]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = n0 / SR; m.sec_block()
        for i in range(BLK):
            n = n0 + i; A._clock[0] = n / SR
            x = 0.3 * math.sin(2 * math.pi * 220 * n / SR) if rec[0] else 0.0
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample(); out.append(m.v_spl0)
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
step(secs(0.6))   # lissage du pitch
cmd(1); step(secs(1.0)); cmd(1); step(2); rec[0] = False
L = m.v_length; st = len(out); step(secs(0.8))
seg = out[st + int(0.2*SR):]
zc = sum(1 for a, b in zip(seg, seg[1:]) if a <= 0 < b) / (len(seg) / SR)
print("D" if mode else "A", "link", int(link), "| boucle %.2f s (en temps de lecture %.2f s) | hauteur restituee ~%.0f Hz" % (L / SR, L / SR / (m.v_varispeed if m.v_link_eff else m.v_sm_speed), zc))
