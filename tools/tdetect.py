"""Test de la detection des slices (analyse du JSFX sur un buffer synthetique).
Usage : cd tools && python3 tdetect.py . fichier.jsfx [tag]
Pour chaque scenario : on remplit la boucle, on lance l'analyse, on liste les slices obtenues
et on les compare aux attaques reelles (vrais positifs, ratees, fausses, repartition)."""
import sys, math, random
sys.path.insert(0, sys.argv[1])
import bench
from bench import load, Run, SR, BLK

JS = sys.argv[2]; TAG = sys.argv[3] if len(sys.argv) > 3 else 'det'
m = load(JS, TAG); bench.jsfx_path_of[m] = JS
r = Run(m, lambda n: 0.0)
M = m.M

def hit(buf, at, amp, f, dec, kind='tone', rnd=None):
    n = int(SR * dec * 6)
    for i in range(n):
        k = at + i
        if k >= len(buf): break
        env = (1 - math.exp(-i / (SR * 0.0007))) * math.exp(-i / (SR * dec))
        v = math.sin(2 * math.pi * f * i / SR) if kind == 'tone' else (rnd.random() * 2 - 1)
        buf[k] += amp * env * v

def scenario(name, L, build):
    rnd = random.Random(7)
    buf = [0.0] * L
    truth = build(buf, rnd)
    return name, buf, truth

def run_case(name, buf, truth, N, hold=120, strict=1):
    L = len(buf)
    lb = int(m.v_left_buf); rb = int(m.v_right_buf)
    for i in range(L):
        M[lb + i] = buf[i]; M[rb + i] = buf[i] * 0.95
    m.v_length = float(L); m.v_loop_start = 0.0; m.v_loop_width = float(L); m.v_state = 2.0
    m.v_max_slices = float(N); m.v_last_max_sl = float(N); m.v_det_hold_ms = float(hold); m.v_last_det_h = float(hold)
    m.v_det_strict = float(strict); m.v_src_auto = 0.0; m.v_slicer_src = 0.0; m.v_last_slicer_src = 0.0
    m.v_an_win_last = math.floor(0) * 3 + math.floor(L) * 7 + L * 13
    m.f_start_analysis()
    k = 0
    while m.v_analysing != 0 and k < 20000:
        m.sec_block(); k += 1
    n = int(m.v_trans_count); tm = int(m.v_trans_mem)
    sl = sorted(M[tm + i] for i in range(n))
    tol = SR * 0.012
    tp = sum(1 for t in truth if any(abs(s - t) <= tol for s in sl))
    fp = sum(1 for s in sl if not any(abs(s - t) <= tol for t in truth))
    err = [min(abs(s - t) for t in truth) / SR * 1000 for s in sl if any(abs(s - t) <= tol for t in truth)]
    if '-v' in sys.argv:
        print('    fausses :', [round(s / SR, 3) for s in sl if not any(abs(s - t) <= tol for t in truth)])
        print('    ratees  :', [round(t / SR, 3) for t in truth if not any(abs(s - t) <= tol for s in sl)][:12])
        print('    ecarts  :', [round((s - min(truth, key=lambda t: abs(t - s))) / SR * 1000, 1) for s in sl][:16])
    q = [0] * 4
    for s in sl: q[min(3, int(4 * s / L))] += 1
    print('  %-34s N=%-2d -> %2d slices | justes %2d / %2d attaques | fausses %d | ecart moy %.1f ms | par quart de boucle %s'
          % (name, N, n, tp, len(truth), fp, (sum(err) / len(err)) if err else 0, q))
    return sl

B = int(SR * 0.5)   # un temps a 120 bpm

def s_loud_then_quiet(buf, rnd):
    # 8 s : 1er quart = coups forts (0.8), le reste = memes coups doux (0.12), une double-croche par 1/8 de temps
    t = []
    for k in range(64):
        at = k * (B // 2)
        if at + 400 >= len(buf): break
        amp = 0.8 if at < len(buf) // 4 else 0.12
        hit(buf, at + 400, amp, 180 if k % 2 == 0 else 420, 0.04); t.append(at + 400)
    return t

def s_bass_hats(buf, rnd):
    # basse tenue (60 Hz, 0.5) qui change de note tous les 2 temps + charleston doux (bruit 0.06) sur chaque croche
    t = []
    for i in range(len(buf)):
        f = 55 if (i // (2 * B)) % 2 == 0 else 73.4
        buf[i] += 0.5 * math.sin(2 * math.pi * f * i / SR)
    t += list(range(0, len(buf), 2 * B))      # changements de note de la basse (saut de phase = attaque audible)
    for k in range(len(buf) // (B // 2)):
        at = k * (B // 2) + 1000
        if at >= len(buf): break
        hit(buf, at, 0.06, 0, 0.012, 'noise', rnd); t.append(at)
    return t

def s_pluck_crescendo(buf, rnd):
    # notes pincees qui decroissent, jouees de plus en plus fort (0.05 -> 0.6), une par temps
    t = []
    nb = len(buf) // B
    for k in range(nb):
        amp = 0.05 + 0.55 * k / max(1, nb - 1)
        hit(buf, k * B + 300, amp, [220, 247, 262, 294][k % 4], 0.25); t.append(k * B + 300)
    return t

def s_sustain_noise(buf, rnd):
    # nappe tenue avec tremolo lent (pas d'attaque sauf au debut) : il ne faut PAS de slices partout
    for i in range(len(buf)):
        buf[i] += (0.3 + 0.1 * math.sin(2 * math.pi * 3 * i / SR)) * math.sin(2 * math.pi * 196 * i / SR)
    return [0]

L8 = 8 * SR - 8 * SR % 64
for name, build, N in (('fort au debut, doux ensuite', s_loud_then_quiet, 16),
                       ('basse (notes) + charley doux', s_bass_hats, 16),
                       ('crescendo de notes', s_pluck_crescendo, 8),
                       ('nappe avec tremolo', s_sustain_noise, 16)):
    nm, buf, truth = scenario(name, L8 if build is not s_sustain_noise else 4 * SR, build)
    run_case(nm, buf, truth, N)
    if build is s_loud_then_quiet:
        run_case(nm, buf, truth, 0)
