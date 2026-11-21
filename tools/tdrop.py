"""V3.25 : test du DROP de groupe ENREGISTRE (2 loopers + piste "NU Drop" avec NU_DropCapture, gmem partage).
A (id 1) enregistre ~2 s (maitre), B (id 2) ~1 s en esclave. La piste de B a un "effet" (filtre + saturation) applique
apres le JSFX. NU_DropCapture est en bout de chaine de la piste de A (canaux 1/2) et recoit effet(B) sur 2 canaux ajoutes (3/4).
Apres la bascule, A seul (sans effet, B efface) doit sonner comme A + effet(B) d'avant, a la meme phase.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.25.jsfx v325.jsfx && cp ../NowUndo/NU_DropCapture.jsfx cap.jsfx
        && python3 tdrop.py . [base|arev|gran|speed]
  base  : B normal + effet          arev : A en reverse (la cible est remise a plat apres le drop)
  gran  : B vitesse x2 SANS Link (granulaire)      speed : A vitesse x2 avec Link (passage = moitie de sa boucle)
  solo  : DROP SOLO (V3.27) : A seul en reverse, pas de send ni de source ; B continue sans etre touche
  slc / slcp : DROP SOLO de A en SLICER (slcp : pitch -5) ; fidelite = apres la bascule, A rejoue exactement ce qu'il
         faisait entendre pendant la capture au meme instant du cycle (V3.27 : duree / phase prises sur l'horloge)"""
import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
import eel2py

path = 'v325.jsfx'
A = load(path, 'drA'); bench.jsfx_path_of[A] = path
B = load(path, 'drB'); bench.jsfx_path_of[B] = path
import importlib.util
_code, _al = eel2py.translate('cap.jsfx'); open('_gen_drC.py', 'w').write(_code)
_sp = importlib.util.spec_from_file_location('gen_drC', '_gen_drC.py'); C = importlib.util.module_from_spec(_sp); _sp.loader.exec_module(C)
bench.jsfx_path_of[C] = 'cap.jsfx'
B.GM = A.GM; B._clock = A._clock; C.GM = A.GM; C._clock = A._clock
GM = A.GM

SLC = len(sys.argv) > 2 and sys.argv[2] in ('slc', 'slcp')
def sigA(n): return 0.3 * sig_drums(n) if SLC else 0.25 * math.sin(2 * math.pi * 110 * n / SR)   # slicer : des attaques
def sigB(n): return 0.3 * sig_drums(n)

class R(Run):
    def __init__(s, m, sig, ident, src):
        s.m = m; s.sig = sig; s.n = 0; s.out = []; s.events = []
        m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 1.0
        m.v_beat_position = 0.0
        import re
        for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(src, encoding='utf-8').read(), re.M):
            setattr(m, 'v_' + mm.group(1), float(mm.group(2)))
        m.v_manual_id = float(ident)
        m.sec_init()
        if hasattr(m, "sec_slider"): m.sec_slider()

ra, rb, rc = R(A, sigA, 1, path), R(B, sigB, 2, path), R(C, lambda n: 0.0, 0, 'cap.jsfx')
feed = {'A': True, 'B': True}
fx = {'on': True, 'z': [0.0, 0.0]}
SOLO = len(sys.argv) > 2 and sys.argv[2] in ('solo', 'slc', 'slcp')      # drop solo : aucun send vers la piste cible
outB = []          # sortie de la piste B APRES son effet

def fxB(x, ch):
    if not fx['on']: return x
    z = fx['z']; z[ch] += 0.15 * (x - z[ch])                 # passe-bas
    return math.tanh(2.0 * z[ch]) * 0.6                       # saturation

def step(nblk=1):
    for _ in range(nblk):
        n0 = ra.n
        A._clock[0] = n0 / SR
        for r in (ra, rb, rc):
            r.m.v_beat_position = n0 / SR * 2.0
            r.m.sec_block()
        for r, k in ((ra, 'A'), (rb, 'B')):
            m = r.m
            for i in range(BLK):
                n = n0 + i
                A._clock[0] = n / SR
                x = r.sig(n) if feed[k] else 0.0
                m.v_spl0 = x; m.v_spl1 = x * 0.9
                m.sec_sample()
                o = (m.v_spl0, m.v_spl1)
                if k == 'B': o = (fxB(o[0], 0), fxB(o[1], 1)); outB.append(o)
                r.out.append(o)
            r.n = n0 + BLK
        m = C
        for i in range(BLK):
            A._clock[0] = (n0 + i) / SR
            m.v_spl0 = ra.out[n0 + i][0]; m.v_spl1 = ra.out[n0 + i][1]          # piste cible (apres ses effets)
            m.v_spl2 = 0.0 if SOLO else outB[n0 + i][0]; m.v_spl3 = 0.0 if SOLO else outB[n0 + i][1]   # autres loopers (sends)
            m.sec_sample()
        rc.n = n0 + BLK
        A._clock[0] = ra.n / SR

def base(m): return 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200
def cmd(m, c, arg=None):
    b = base(m)
    if arg is not None: GM[b + 49] = arg
    GM[b + 48] = c
def secs(t): return int(t * SR / BLK)
def wait(cond, maxblk=4000):
    k = 0
    while not cond() and k < maxblk: step(1); k += 1
    return k

def scenario(which):
    cmd(A, 1); step(secs(2.0)); cmd(A, 1); step(2)
    feed['A'] = False
    cmd(B, 1); step(secs(0.9)); cmd(B, 1); step(secs(1.2))
    feed['B'] = False
    print('A length', A.v_length, '| B length', B.v_length, 'state', B.v_state)
    if which in ('arev', 'solo'): cmd(A, 4); step(2)
    if which in ('slc', 'slcp'):
        cmd(A, 6); step(2)
        if which == 'slcp': GM[base(A) + 181] = -5; GM[base(A) + 180] = 4; step(2)
    if which == 'gran': B.v_speed = 2.0; B.sec_slider()
    if which == 'speed': A.v_speed = 2.0; A.v_link_on = 1.0; A.sec_slider()
    step(secs(1.5))
    LA = int(round(A.v_length / (2.0 if which == 'speed' else 1.0)))
    nref = ra.n
    step(int(math.ceil(LA / BLK)) + 1)
    step(int(math.ceil(LA / BLK)) + 1)
    print('reference periodique ? A %.5f  B %.5f' % (max(abs(ra.out[n][0] - ra.out[n - LA][0]) for n in range(nref + LA, nref + 2 * LA)), max(abs(rb.out[n][0] - rb.out[n - LA][0]) for n in range(nref + LA, nref + 2 * LA))))
    # ---- DROP (comme le script) ----
    tok = 11
    GM[380] = 0; GM[381] = 1; GM[395] = 1.0; GM[396] = 0
    cmd(A, 34, tok)
    if not SOLO: cmd(B, 35, tok)
    step(1)
    print('arm : A', GM[300], 'L', GM[305], '| B', GM[310])
    GM[393] = tok; ncap = ra.n
    print('debut de capture : instant', GM[301], '| duree demandee L', GM[305])
    # V3.27 : DROP ON -> la capture tourne ; DROP OFF un peu plus d'un cycle plus tard, a un instant quelconque
    L0 = int(GM[305]); step(int(math.ceil(2.5 * L0 / BLK)))   # ~2,5 tours captures avant DROP OFF
    GM[380] = tok + 0.25
    k = wait(lambda: GM[300] == tok + 0.5); print('DROP OFF -> bascule %d blocs plus tard | nouvelle longueur %d = %.2f tours | B state %d' % (k, int(A.v_length), A.v_length / L0, B.v_state))
    fx['on'] = False                      # le script coupe les effets de la piste cible apres l'accuse
    GM[380] = tok + 0.5
    nsw = ra.n - BLK                      # la cible a bascule au debut du dernier bloc
    A_pos_sw = A.v_pos - BLK; step(1)
    if which == 'speed':
        for _ in range(6):
            print('   pos %.1f master_pos %.1f len %d base %d sm_speed %.3f gmem2 %.0f gmem3 %.0f' % (A.v_pos, A.v_master_pos, A.v_length, A.v_base_loop_length, A.v_sm_speed, GM[2], GM[3]))
            step(40)
    if which in ('slc', 'slcp'):
        L = int(A.v_length); step(int(math.ceil(L / BLK)) + 4)
        e = 0.0; ref = 0.0; s1 = nsw
        for n in range(s1, s1 + L - 8 * BLK):
            nb = n - ((n - nsw) // L + 1) * L          # meme instant du dernier cycle capture (avant la bascule)
            e = max(e, abs(ra.out[n][0] - ra.out[nb][0])); ref = max(ref, abs(ra.out[nb][0]))
        def el(lag):
            ee = 0.0
            for n in range(s1, s1 + L - 8 * BLK, 3):
                nb = n - ((n - nsw) // L + 1) * L + lag
                ee = max(ee, abs(ra.out[n][0] - ra.out[nb][0]))
            return ee
        bl = min(range(-48, 49), key=el)
        zs = [n - s1 for n in range(s1, s1 + L - 8 * BLK) if abs(ra.out[n][0] - ra.out[n - ((n - nsw) // L + 1) * L][0]) > 0.005]
        print('  meilleur decalage %d -> ecart %.5f | zones d\'ecart (debut, fin, nb) : %s' % (bl, el(bl), (zs[0], zs[-1], len(zs)) if zs else None))
        print('SLICER : longueur capturee %d (cycle de l\'horloge = %d) | ecart apres bascule vs capture au meme instant = %.5f (crete %.3f) | A state %d slicer %d' % (
            L, int(A.v_loop_width / max(0.01, A.v_sm_speed)), e, ref, A.v_state, A.v_play_mode))
        return e
    print('apres bascule : A state %d length %d speed %.2f rev %d fade %.1f undo %d | B state %d length %d' % (
        A.v_state, A.v_length, A.v_speed, A.v_rev_on, A.v_fade_ms, A.v_hist_undo, B.v_state, B.v_length))
    step(int(math.ceil(LA / BLK)) * 2 + 4)
    err = 0.0; ref = 0.0; at = 0; s0 = nsw + 2 * BLK
    for n in range(s0, s0 + LA):
        nb = n - ((n - nref) // LA) * LA
        for ch in (0, 1):
            want = ra.out[nb][ch] + (0.0 if SOLO else rb.out[nb][ch])
            d = abs(ra.out[n][ch] - want)
            if d > err: err = d; at = n
            ref = max(ref, abs(want))
    cl = []; prev = None
    for n in range(s0, s0 + LA):
        nb = n - ((n - nref) // LA) * LA
        if abs(ra.out[n][0] - ra.out[nb][0] - (0.0 if SOLO else rb.out[nb][0])) > 0.002:
            if prev is None or n - prev > 64: cl.append([n, n])
            cl[-1][1] = n; prev = n
    print('zones d\'ecart (debut, longueur, index de A) :', [(c[0] - s0, c[1] - c[0], int((A_pos_sw + c[0] - nsw) % LA)) for c in cl][:3], 'nb zones', len(cl), 'derniere', (cl[-1][0]-s0, cl[-1][1]-cl[-1][0]) if cl else None)
    LAGS = list(range(-3, 4))
    if which == 'speed':
        def ce(lag):
            e = 0.0
            for n in range(s0 + 2000, s0 + 12000, 7):
                nb = n - ((n - nref) // LA) * LA + lag
                e += abs(ra.out[n][0] - ra.out[nb][0] - rb.out[nb][0])
            return e
        bl = min(range(-40, 41), key=ce); print('  recalage sur l\'horloge apres la bascule : %d samples' % bl); LAGS = [bl]
    for lag in LAGS:
        e = 0.0
        for n in range(s0 + 2000, s0 + LA - 2000):
            nb = n - ((n - nref) // LA) * LA + lag
            e = max(e, abs(ra.out[n][0] - ra.out[nb][0] - (0.0 if SOLO else rb.out[nb][0])))
        print('  lag', lag, 'ecart %.5f' % e)
    if which == 'speed':
        LD = 1000000; T0 = int(round(GM[301]))
        # contenu enregistre vs reference : l'instant tau(n) = (A_pos_sw + 1 + n - nsw) mod LA
        e1 = 0.0; e2 = 0.0
        for n in range(s0, s0 + 20000, 3):
            tau = int((A_pos_sw + 1 + n - nsw) % LA)
            nb = n - ((n - nref) // LA) * LA
            e1 = max(e1, abs(GM[LD + 16 + tau] - ra.out[nb][0] - rb.out[nb][0]))
            e2 = max(e2, abs(GM[LD + 16 + tau] - ra.out[n][0]))
        def co(o):
            e = 0.0
            for n in range(s0, s0 + 6000, 5):
                tau = int((A_pos_sw + 1 + n - nsw + o) % LA); nb = n - ((n - nref) // LA) * LA
                e += abs(GM[LD + 16 + tau] - ra.out[nb][0] - rb.out[nb][0])
            return e
        bo = min(range(-24000, 24000, 20), key=co); bo = min(range(bo - 25, bo + 26), key=co); print('  decalage capture', bo, co(bo))
        print('  capture vs reference %.5f | capture vs A apres %.5f' % (e1, e2))
    print('ecart max A(apres) - (A + effet(B))(avant) = %.5f (crete %.3f) a n=%d' % (err, ref, at))
    cmd(A, 14); step(3)
    print('apres Undo : A length %d' % A.v_length)
    return err

scenario(sys.argv[2] if len(sys.argv) > 2 else 'base')
