"""Stretch : vitesse x10 et changements de vitesse. Clics dans le signal + temps de calcul par bloc.
python3 tstretch2.py . v327.jsfx"""
import sys, math, re, time
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
A = load(path, 'st2' + str(abs(hash(path)) % 1000)); GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = 128.0; m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
A._clock[0] = 100.0; m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]
def step(k, rec=None, tim=None):
    for _ in range(k):
        n0 = N[0]; t = time.perf_counter(); m.sec_block()
        for i in range(128):
            n = n0 + i; x = 0.3 * math.sin(2 * math.pi * 220 * n / SR) + 0.15 * math.sin(2 * math.pi * 331 * n / SR)
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
            if rec is not None: rec.append(m.v_spl0)
        if tim is not None: tim.append(time.perf_counter() - t)
        N[0] = n0 + 128
def cmd(c): GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
cmd(1); step(int(2 * SR / 128)); cmd(1); step(20)
m.v_mix = 1.0; m.v_link_on = 0.0; m.sec_slider()
base = []; step(200, None, base); med = sorted(base)[len(base) // 2]
def phase(tag, sp, nblk):
    m.v_speed = sp; m.sec_slider()
    out, tim = [], []; step(nblk, out, tim)
    d2 = [abs(out[i] - 2 * out[i - 1] + out[i - 2]) for i in range(2, len(out))]
    s = sorted(d2); md = s[len(s) // 2]
    big = [i for i, v in enumerate(d2) if v > 0.05]
    print('%-28s clics (saut > 0.05) : %4d, 1er a %s ms | bloc max %.1fx, moyenne %.1fx' % (tag, len(big),
          '%.0f' % (big[0] * 1000 / SR) if big else '-', max(tim) / med, sum(tim) / len(tim) / med))
phase('vitesse 1 (reference)', 1.0, 150)
phase('passage 1 -> 10', 10.0, 40)
phase('vitesse 10 tenue', 10.0, 150)
phase('passage 10 -> 1', 1.0, 40)
phase('passage 1 -> 0.25', 0.25, 40)
phase('vitesse 0.25 tenue', 0.25, 150)
# --- comptage
CNT = {'pick': 0}
orig = m.f_rd_pick
def wrap(*a):
    CNT['pick'] += 1; return orig(*a)
m.f_rd_pick = wrap
for sp in (1.0, 10.0):
    m.v_speed = sp; m.sec_slider(); step(100)
    CNT['pick'] = 0; act = []
    for _ in range(int(SR / 128)):
        step(1)
        act.append(sum(1 for g in range(16) if m.M[int(m.v_grain_mem) + g * int(m.v_grain_data_size) + 2] == 1))
    print('vitesse %4.1f : recherches/s %d, grains actifs moyen %.1f max %d, duree grain %.0f ms, ecart %.0f' % (sp, CNT['pick'], sum(act) / len(act), max(act), m.v_grain_dur * 1000 / SR, m.v_gt))
