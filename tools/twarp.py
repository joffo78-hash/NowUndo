"""Test du WARP (V3.26) : attaques calees sur la grille, longueur intacte, ON/OFF, recalcul, overdub qui fige.
Usage : cd tools && python3 twarp.py . fichier.jsfx [tag] [--play]
--play : rejoue aussi la boucle (@sample) pendant les bascules pour mesurer les clics (plus lent)."""
import sys, math, random
sys.path.insert(0, sys.argv[1])
import bench
from bench import load, Run, SR, BLK, clicks

JS = sys.argv[2]; TAG = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3].startswith('-') else 'warp'
PLAY = '--play' in sys.argv
GAP = 40 if PLAY else 3   # en lecture : ~0,2 s entre deux manips (un humain)
m = load(JS, TAG); bench.jsfx_path_of[m] = JS
M = m.M; GM = m.GM
rnd = random.Random(3)

def hit(buf, at, amp, f, dec, noise=False):
    n = int(SR * dec * 6)
    for i in range(n):
        k = at + i
        if k >= len(buf): k -= len(buf)
        env = (1 - math.exp(-i / (SR * 0.0007))) * math.exp(-i / (SR * dec))
        v = (rnd.random() * 2 - 1) if noise else math.sin(2 * math.pi * f * i / SR)
        buf[k] += amp * env * v

# boucle de 4 s (120 bpm, 8 temps) : une attaque par croche (0,25 s), jouee avec un decalage de -35..+35 ms,
# + une basse tenue qui change de note tous les 2 temps (attaques aussi, decalees)
L = 4 * SR
GRID = SR // 4
buf = [0.0] * L
src_pos, want = [], []
for k in range(16):
    off = 0 if k == 0 else int(rnd.uniform(-0.035, 0.035) * SR)
    at = k * GRID + off
    hit(buf, at, 0.7 if k % 2 == 0 else 0.45, 180 if k % 4 == 0 else 420, 0.04, noise=(k % 2 == 1 and not PLAY))
    src_pos.append(at); want.append(k * GRID)
for i in range(L):
    buf[i] += 0.12 * math.sin(2 * math.pi * 97 * i / SR)

r = Run(m, lambda n: 0.0)
gb = 1000 + int(m.v_inst_idx) * 600

def load_loop():
    lb = int(m.v_left_buf); rb = int(m.v_right_buf)
    for i in range(L):
        M[lb + i] = buf[i]; M[rb + i] = buf[i] * 0.97
    m.v_length = float(L); m.v_loop_start = 0.0; m.v_loop_width = float(L); m.v_state = 2.0; m.v_state_target = 2.0
    m.v_last_state_target = 2.0; m.v_hist_len = m.v_hist_len; M[int(m.v_hist_len)] = float(L)
    m.v_base_loop_length = float(L); m.v_clk_len_ref = float(L); m.v_smooth_start = 0.0; m.v_smooth_width = float(L)

def blocks(n, play=False):
    if play:
        r.run(n * BLK)
    else:
        for _ in range(n):
            r.n += BLK; m._clock[0] = r.n / SR; m.sec_block()

def wait(cond, maxb=20000, play=False):
    k = 0
    while not cond() and k < maxb:
        blocks(1, play); k += 1
    return k

def cur():
    lb = int(m.v_left_buf); rb = int(m.v_right_buf)
    return [M[lb + i] for i in range(int(m.v_length))], [M[rb + i] for i in range(int(m.v_length))]

def onsets(x, refs, amp_of):
    """position mesuree de chaque attaque : 1er echantillon > 30 % de son amplitude dans [-60, +60] ms autour du repere"""
    res = []
    for k, t in enumerate(refs):
        a = amp_of[k] * 0.3; found = None
        for d in range(-int(SR * 0.06), int(SR * 0.06)):
            i = (t + d) % len(x)
            # on ne regarde que ce qui depasse nettement la basse (0,12)
            if abs(x[i]) > max(a, 0.2):
                found = d; break
        res.append(found)
    return res

amps = [0.7 if k % 2 == 0 else 0.45 for k in range(16)]
ok_all = True
def check(name, cond, info=''):
    global ok_all
    ok_all &= bool(cond)
    print('  [%s] %s %s' % ('OK ' if cond else 'BAD', name, info))

load_loop()
blocks(200)                       # analyse des slices du depart
x0, _ = cur()
e0 = onsets(x0, want, amps)
print('avant warp : ecart a la grille (ms) =', [round(e / SR * 1000, 1) if e is not None else None for e in e0])

# --- warp ON, grille 1/8, force 100 %
m.v_warp_grid = 1.0; m.v_warp_force = 100.0; m.v_warp_on = 1.0
nb = wait(lambda: GM[gb + 156] == 1, play=PLAY)
print('calcul : %d blocs (%.2f s)' % (nb, nb * BLK / SR), '| couche', m.v_active_history_idx, '| undo', m.v_hist_undo, '| attaques trouvees', int(m.v_wp_mn), 'gardees', int(m.v_wp_n))
x1, y1 = cur()
e1 = onsets(x1, want, amps)
print('apres warp : ecart a la grille (ms) =', [round(e / SR * 1000, 1) if e is not None else None for e in e1])
check('longueur intacte', len(x1) == L)
check('attaques sur la grille (< 2 ms)', all(e is not None and abs(e) <= SR * 0.002 for e in e1))
# cassures : on compare a l'original sur la partie "basse seule" (apres la fin de chaque coup, 100 ms apres l'attaque)
def calm(x, refs):
    return max(abs(x[i] - 2 * x[i - 1] + x[i - 2]) for k in range(16) for i in range(refs[k] + int(SR * 0.1), refs[k] + int(SR * 0.2)))
mx0 = calm(x0, src_pos); mx = calm(x1, want)
check('pas de cassure entre les coups', mx < mx0 * 1.5 + 0.002, '(2e difference max %.4f, original %.4f)' % (mx, mx0))
P = int(m.v_wp_orig); W = int(m.v_wp_wsl)

# --- OFF : retour a l'original, ON : retour instantane a la version calee
m.v_warp_on = 0.0; blocks(GAP, PLAY)
xo, _ = cur()
check('OFF = original exact', int(m.v_active_history_idx) == P and max(abs(a - b) for a, b in zip(xo, x0)) < 1e-9)
m.v_warp_on = 1.0; nb = wait(lambda: GM[gb + 156] == 1, play=PLAY)
xw, _ = cur()
check('ON = version calee sans recalcul', nb <= 2 or PLAY and max(abs(a - b) for a, b in zip(xw, x1)) < 1e-9, '(%d blocs)' % nb)

# --- undo / redo de l'utilisateur pilotent ON / OFF
m.f_undo_state(); blocks(GAP, PLAY)
check('Undo -> Warp OFF', m.v_warp_on == 0 and int(m.v_active_history_idx) == P)
m.f_redo_state(); blocks(GAP, PLAY)
check('Redo -> Warp ON', m.v_warp_on == 1 and GM[gb + 156] == 1)

# --- force 50 % : recalcul depuis l'original
m.v_warp_force = 50.0
for _ in range(int(0.3 * SR / BLK) + 2): blocks(1, PLAY)
nb = wait(lambda: GM[gb + 156] == 1 and m.v_wp_busy == 0, play=PLAY)
x2, _ = cur()
e2 = onsets(x2, want, amps)
half = [round((b if b is not None else 0) / SR * 1000, 1) for b in e2]
print('force 50 % : ecart (ms) =', half)
okh = all(e2[k] is not None and abs(e2[k] - e0[k] / 2) <= SR * 0.003 for k in range(16) if e0[k] is not None)
check('force 50 % = moitie du chemin (+-3 ms)', okh)
check('recalcul : on rejoue la couche du warp', int(m.v_active_history_idx) == W and int(m.v_hist_undo) >= 1)
m.v_warp_on = 0.0; blocks(GAP, PLAY)
xo2, _ = cur()
check('OFF apres recalcul = original exact', max(abs(a - b) for a, b in zip(xo2, x0)) < 1e-9)

# --- overdub sur la version calee : le warp est fige, Undo revient a la version calee (warp reglable)
m.v_warp_on = 1.0; wait(lambda: GM[gb + 156] == 1, play=PLAY)
m.f_push_new_history_state(); blocks(GAP, PLAY)
check('overdub fige le warp (Warp OFF, contenu cale garde)', m.v_warp_on == 0 and m.v_wp_live == 0)
xf, _ = cur()
check('couche figee = version calee', max(abs(a - b) for a, b in zip(xf, x2)) < 1e-9)

if PLAY:
    mx, at, cnt = clicks(r.out, int(SR * 0.1), len(r.out))
    print('  lecture : 2e difference max %.4f a %.3f s (%d depassements)' % (mx, at / SR, cnt))
print('RESULTAT :', 'tout bon' if ok_all else 'ECHEC')
if PLAY and '-v' in sys.argv:
    out = r.out; ev = []
    for i in range(2, len(out)):
        d = abs(out[i][0] - 2 * out[i-1][0] + out[i-2][0])
        if d > 0.02: ev.append((round(i / SR, 4), round(d, 3)))
    print('  depassements :', ev[:20])
