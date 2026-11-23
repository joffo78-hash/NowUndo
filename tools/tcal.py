"""Calibration de la latence (bouton CAL, V3.27) : retour simule = sortie retardee de <lat> ms, attenuee, + bruit.
python3 tcal.py . v327.jsfx <lat_ms> <gain> <bruit>"""
import sys, math, re, random
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]; lat = float(sys.argv[3]); gain = float(sys.argv[4]); noise = float(sys.argv[5])
A = load(path, 'cal'); GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = 128.0; m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
A._clock[0] = 100.0; m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
D = int(lat * SR / 1000); hist = [0.0] * (D + 1); rnd = random.Random(1)
m.f_cal_start()
n = 0
while m.v_cal_on > 0.5 and n < SR * 10:
    if n % 128 == 0: m.sec_block()
    x = hist[n % (D + 1)] * gain + (rnd.random() * 2 - 1) * noise      # ce qui revient a l'entree
    # petite reverb : echo 8 ms plus tard a moitie
    m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
    hist[n % (D + 1)] = m.v_spl0
    n += 1
print('latence simulee %.1f ms, gain %.3f, bruit %.4f -> message %d, mesure %.2f ms, LAT = %d (retours %d, %.1f s)' % (lat, gain, noise, m.v_cal_msg, m.v_cal_res, m.v_lat_own, m.v_cal_n, n / SR))
