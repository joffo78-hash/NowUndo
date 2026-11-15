"""V3.24 : test du DROP de groupe avec 2 instances qui partagent gmem.
A (id 1) enregistre ~2 s (maitre), B (id 2) enregistre ~1 s en esclave (+ reverse / vitesse en option).
Drop : B est mixe dans A. On compare la sortie de A apres le drop a la somme A + B d'avant, a la meme phase.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.24.jsfx v324.jsfx && python3 tdrop.py . [base|rev|speed]
(le raccord de la cible est exclu de la mesure : son fondu de 10 ms s'applique aussi au contenu ajoute, comme un overdub)"""
import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *

path = 'v324.jsfx'
A = load(path, 'drA'); bench.jsfx_path_of[A] = path
B = load(path, 'drB'); bench.jsfx_path_of[B] = path
B.GM = A.GM; B._clock = A._clock          # gmem et horloge communs
GM = A.GM

def sigA(n): return 0.25 * math.sin(2 * math.pi * 110 * n / SR)
def sigB(n): return 0.3 * sig_drums(n)

class R(Run):
    def __init__(s, m, sig, ident):
        s.m = m; s.sig = sig; s.n = 0; s.out = []; s.events = []
        m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 1.0
        m.v_beat_position = 0.0
        import re
        src = open(path, encoding='utf-8').read()
        for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', src, re.M):
            setattr(m, 'v_' + mm.group(1), float(mm.group(2)))
        m.v_manual_id = float(ident)
        m.sec_init(); m.sec_slider()

ra, rb = R(A, sigA, 1), R(B, sigB, 2)
feed = {'A': True, 'B': True}

def step(nblk=1):
    for _ in range(nblk):
        n0 = ra.n
        A._clock[0] = n0 / SR
        for r in (ra, rb):
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
                r.out.append((m.v_spl0, m.v_spl1))
            r.n = n0 + BLK
        A._clock[0] = ra.n / SR

def base(m): return 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200
def cmd(m, c, arg=None):
    b = base(m)
    if arg is not None: GM[b + 49] = arg
    GM[b + 48] = c

def secs(t): return int(t * SR / BLK)

def scenario(revB=False, speedB=1.0):
    # A : REC 2 s
    cmd(A, 1); step(secs(2.0)); cmd(A, 1); step(2)
    print('A length', A.v_length, 'state', A.v_state, 'master', GM[0], GM[1], GM[2])
    # B : REC ~0.9 s en esclave (arrondi par la synchro)
    feed['A'] = False
    cmd(B, 1); step(secs(0.9)); cmd(B, 1); step(secs(1.2))
    feed['B'] = False
    print('B length', B.v_length, 'state', B.v_state)
    if revB: cmd(B, 4); step(2)
    if speedB != 1.0: B.v_speed = speedB; B.v_link_on = 1.0; B.sec_slider()
    step(secs(1.0))
    LA = int(A.v_length)
    # reference : sortie A + B sur le dernier cycle de A avant le drop
    nref = ra.n
    step(int(math.ceil(LA / BLK)) + 1)
    # DROP (comme le script) : instantane -> ajout de B -> commit dans A
    tok = 7
    nsnap = ra.n
    cmd(A, 34, tok); cmd(B, 34, tok); step(1)
    assert GM[300] == tok and GM[310] == tok, (GM[300], GM[310])
    print('lecture simple A %d B %d' % (GM[309], GM[319]))
    print('snap A pos %.0f mref %.0f w %.0f | B pos %.0f mref %.0f w %.0f' % (GM[301], GM[302], GM[305], GM[311], GM[312], GM[315]))
    GM[381] = 1; GM[382] = 1; cmd(B, 35, tok)
    k = 0
    while GM[310] != tok + 0.25 and k < 2000: step(1); k += 1
    print('add B : %d blocs, ack %s' % (k, GM[310]))
    cmd(A, 36, tok)
    k = 0
    while GM[380] != tok + 0.5 and k < 2000: step(1); k += 1
    ndrop = ra.n
    print('commit A : %d blocs, signal %s ; A undo %d' % (k, GM[380], A.v_hist_undo))
    step(3)
    print('B state apres drop', B.v_state)
    step(int(math.ceil(LA / BLK)) * 2 + 4)
    # comparaison : apres le drop (B arrete apres ~8 ms de fondu), A seul doit valoir A + B d'avant (meme phase, periode LA)
    err = 0.0; ref = 0.0; at = 0
    s0 = ndrop + 4 * BLK
    for n in range(s0, s0 + LA):
        c = (n - nref) // LA
        nb = n - (c + 1) * LA if n - c * LA >= nref + LA else n - c * LA
        nb = n - ((n - nref) // LA) * LA
        pa = (GM[301] + (n - nsnap)) % LA          # position de A : on saute son propre raccord (fondu de 10 ms de la cible)
        if min(pa, LA - pa) < 0.0105 * SR + 64: continue
        for ch in (0, 1):
            want = ra.out[nb][ch] + rb.out[nb][ch]
            got = ra.out[n][ch]
            d = abs(got - want)
            if d > err: err = d; at = n
            ref = max(ref, abs(want))
    print('ecart max A(apres) - (A+B)(avant) = %.5f (crete %.3f) a n=%d' % (err, ref, at))
    # Undo : A revient a sa boucle d'origine
    cmd(A, 14); step(2)
    e2 = 0.0
    s1 = ra.n + 2 * BLK
    step(int(math.ceil(LA / BLK)) + 4)
    for n in range(s1, s1 + LA // 2):
        nb = n - ((n - nref) // LA) * LA
        e2 = max(e2, abs(ra.out[n][0] - ra.out[nb][0]))
    print('apres Undo : ecart A / A d\'origine = %.5f' % e2)
    return err

which = sys.argv[2] if len(sys.argv) > 2 else 'base'
if which == 'rev': scenario(revB=True)
elif which == 'speed': scenario(speedB=2.0)
else: scenario()
