"""Scaler + clavier MIDI en lecture + selection (V3.27, 23 nov.).
cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tscale.py . v327.jsfx"""
import sys, math, re, importlib.util
sys.path.insert(0, sys.argv[1])
import bench, eel2py
from bench import SR, BLK
path = sys.argv[2]
# midirecv simule : file d'evenements en 13 900 000 (status / d1 / d2)
MQ = 13900000
pat = [("mem_budget = 120000000;", "mem_budget = 12000000;"), ("cl_mem = 120000500;", "cl_mem = 11700000;"),
       ("frz_l = 120100000; frz_max = 3600000;", "frz_l = 11800000; frz_max = 1000000;"),
       ("while (midirecv(mo_off, mo_m1, mo_m2, mo_m3)) (",
        "while (mq_i < mq_n ? ( mo_off = 0; mo_m1 = %d[mq_i * 3]; mo_m2 = %d[mq_i * 3 + 1]; mo_m3 = %d[mq_i * 3 + 2]; mq_i += 1; 1; ) : 0) (" % (MQ, MQ, MQ))]
code, al = eel2py.translate(path, patches=pat)
fn = '%s/_gen_tscale.py' % sys.argv[1]; open(fn, 'w').write(code)
spec = importlib.util.spec_from_file_location('gen_tscale', fn); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
A = m; GM = m.GM; M = m.M
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
T0 = 100.0; m._clock[0] = T0
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]
def step(k=1, ev=()):
    for j in range(k):
        n0 = N[0]; m._clock[0] = T0 + n0 / SR
        if j == 0 and ev:
            for q, (a, b, c) in enumerate(ev): M[MQ + q * 3] = a; M[MQ + q * 3 + 1] = b; M[MQ + q * 3 + 2] = c
            m.v_mq_n = float(len(ev)); m.v_mq_i = 0.0
        else: m.v_mq_n = 0.0; m.v_mq_i = 0.0
        m.sec_block()
        for i in range(BLK):
            n = n0 + i; m._clock[0] = T0 + n / SR
            x = 0.3 * math.sin(2 * math.pi * 220 * n / SR); m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
def cmd(c):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 48] = c; step(2)
def par(i, v):
    b = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200; GM[b + 181] = v; GM[b + 180] = i; step(2)
def on(n): return (144, n, 100)
def off(n): return (128, n, 0)
names = ['Free', 'Demi-ton', 'Par ton', 'Penta', 'Majeure', 'Min harm', 'Min mel', 'Dimin', 'Augm', 'Octave']
print('--- sc_snap(1.4) / sc_snap(-1.4) / sc_step(0,+1) x3 par gamme')
for g in range(10):
    m.v_pitch_scale = float(g)
    st = []; p = 0.0
    for _ in range(3): p = m.f_sc_step(p, 1.0) if hasattr(m, 'f_sc_step') else None; st.append(p)
    print('%-9s snap(1.4)=%5.1f snap(-1.4)=%5.1f  pas +1 : %s' % (names[g], m.f_sc_snap(1.4), m.f_sc_snap(-1.4), st))
m.v_pitch_scale = 0.0
cmd(1); step(int(2.0 * SR / BLK)); cmd(1); step(4)
print('--- boucle %.2f s, etat %d (lecture)' % (m.v_length / SR, m.v_state))
root = int(m.v_sampler_root)
step(2, [on(root + 2)]); print('Free, D3 (+2)            -> pitch %.2f' % m.v_pitch)
step(2, [off(root + 2)]); print('relache                  -> pitch %.2f (reste)' % m.v_pitch)
step(2, [on(root + 7), on(root + 4), on(root + 12)]); print('accord +4 +7 +12         -> pitch %.2f (la plus grave)' % m.v_pitch)
step(2, [off(root + 4)]); print('relache +4 (tient 7 12)  -> pitch %.2f' % m.v_pitch)
step(2, [off(root + 7), off(root + 12)])
par(70, 4); print('rush scale maj (param 70) -> gamme %d, pitch %.2f (inchange)' % (m.v_pitch_scale, m.v_pitch))
step(2, [on(root + 6)]); step(2, [off(root + 6)]); print('Majeure, F#3 (+6)        -> pitch %.2f' % m.v_pitch)
step(2, [on(root - 1)]); step(2, [off(root - 1)]); print('Majeure, B2 (-1)         -> pitch %.2f' % m.v_pitch)
par(4, 2.6); print('Twister / MIDI Learn 2.6 -> pitch %.2f' % m.v_pitch)
par(69, 3.5); print('rush pitch 3.5 (69)      -> pitch %.2f (absolu)' % m.v_pitch)
b = 1000 + int(m.v_inst_idx) * 600; GM[b + 49] = 1; GM[b + 48] = 21; step(2); print('pas +1 (cmd 21)          -> pitch %.2f' % m.v_pitch)
# selection : Launchpad present, L2 selectionne (masque 2) -> L1 ignore les notes
GM[6060] = 2; GM[6061] = m._clock[0]; step(2, [on(root)]); step(2, [off(root)])
print('LP : L2 selectionne, C3  -> pitch %.2f (ignore)' % m.v_pitch)
GM[6060] = 1 | 4; GM[6061] = m._clock[0]; step(2, [on(root)]); step(2, [off(root)])
print('LP : L1 dans la selection -> pitch %.2f' % m.v_pitch)
GM[6060] = 2; GM[6061] = m._clock[0] - 5; step(2, [on(root + 5)]); step(2, [off(root + 5)])
print('LP arrete (5 s)          -> pitch %.2f (accepte)' % m.v_pitch)
# spreads en gamme
m.v_pitch_scale = 3.0; m.v_slicer_pitch_spread = 60.0; m.f_update_slicer_pitches(32.0)
vals = sorted(set(int(M[int(m.v_slice_pitch_mem) + i]) for i in range(32)))
print('Penta, Slicer Pitch Spread 60%% -> hauteurs : %s' % vals)
cv = sorted(set(int(m.f_calc_cloud_pitch(100.0)) for _ in range(400)))
print('Penta, Cloud Pitch Spread 100%% -> hauteurs : %s' % cv)
m.v_pitch_scale = 9.0; cv = sorted(set(int(m.f_calc_cloud_pitch(100.0)) for _ in range(400)))
print('Octave, Cloud Pitch Spread 100%% -> hauteurs : %s' % cv)
# arret : sampler seulement si selectionne
cmd(3); step(4); GM[6060] = 2; GM[6061] = m._clock[0]; step(2, [on(root)])
print('arret, L1 hors selection -> voix sampler actives : %d' % sum(1 for v in range(int(m.v_smp_nv)) if M[int(m.v_smp_voice) + v * int(m.v_smp_vs)] == 1))
step(2, [off(root)]); GM[6060] = 1; GM[6061] = m._clock[0]; step(2, [on(root)])
print('arret, L1 selectionne    -> voix sampler actives : %d' % sum(1 for v in range(int(m.v_smp_nv)) if M[int(m.v_smp_voice) + v * int(m.v_smp_vs)] == 1))
