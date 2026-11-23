"""Calibration partagee : L1 calibre (23 ms), L2 en Auto la prend ; nouveau chargement (gmem vide) -> republiee.
python3 tcal2.py . v327.jsfx"""
import sys, math, re, random
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
A = load(path, 'cal2a'); B = load(path, 'cal2b'); B.GM = A.GM; B._clock = A._clock; GM = A.GM
for m, k in ((A, 1), (B, 2)):
    m.v_srate = float(SR); m.v_samplesblock = 128.0; m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
    for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
        setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
    A._clock[0] = 100.0; m.v_manual_id = float(k); m.sec_init(); m.sec_slider()
D = int(23 * SR / 1000); hist = [0.0] * (D + 1); rnd = random.Random(1)
A.f_cal_start(); n = 0
while A.v_cal_on > 0.5 and n < SR * 10:
    if n % 128 == 0: A.sec_block(); B.sec_block()
    A.v_spl0 = A.v_spl1 = hist[n % (D + 1)] * 0.05 + (rnd.random() * 2 - 1) * 0.002; A.sec_sample(); hist[n % (D + 1)] = A.v_spl0
    B.v_spl0 = B.v_spl1 = 0.0; B.sec_sample(); n += 1
for _ in range(3): A.sec_block(); B.sec_block()
print('apres CAL sur L1 : gmem958 %.2f ms | L1 LAT %d, lat_samps %d | L2 LAT %d, lat_samps %d, slider71 %.2f' % (GM[958], A.v_lat_own, A.v_lat_samps, B.v_lat_own, B.v_lat_samps, B.v_cal_sv_ms))
for i in range(len(GM)) if False else (958, 959): GM[i] = 0.0          # REAPER redemarre : gmem vide, sliders gardes
B.sec_block(); A.sec_block()
print('redemarrage : gmem958 republie = %.2f ms, L1 lat_samps %d' % (GM[958], A.v_lat_samps))
