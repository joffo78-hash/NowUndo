"""27 nov. : In / Out pre-regles sur un looper vide (longueur fictive publiee en 112000+..+4/5/6), appliques a la fin du 1er REC.
Usage : cd tools && cp ../NowUndo/NowUndo_V3.27.jsfx v327.jsfx && python3 tpreio.py ."""
import sys, math, re
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = 'v327.jsfx'
A = load(path, 'preio'); bench.jsfx_path_of[A] = path
GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]
def step(k=1):
    for _ in range(k):
        n0 = N[0]; A._clock[0] = n0 / SR; m.sec_block()
        for i in range(BLK):
            A._clock[0] = (n0 + i) / SR; x = 0.3 * math.sin(2 * math.pi * 220 * (n0 + i) / SR)
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
        N[0] = n0 + BLK
b = 1000 + int(m.v_inst_idx) * 600
x = 112000 + int(m.v_inst_idx) * 3 * 20
def cmd(c): GM[b + 48] = c
def edit(c, v1=None, v2=None):
    if v1 is not None: GM[b + 161] = v1
    if v2 is not None: GM[b + 162] = v2
    GM[b + 160] = c; step(2)
def secs(t): return int(t * SR / BLK)
fails = [0]
def chk(lbl, got, want, tol=0.002):
    ok = abs(got - want) <= tol; fails[0] += 0 if ok else 1
    print(("OK  " if ok else "FAUX"), lbl, round(got, 4), "" if ok else "(attendu %s)" % want)
step(4)
PL = GM[x + 4]; chk("longueur fictive publiee", PL, 1000000, 0.5)
chk("+46 reste 0 (looper vide)", GM[b + 46], 0, 0)
edit(1, 0.25 * PL); chk("In = 25 % (cmd 1)", GM[x + 5] / PL, 0.25)
edit(2, None, 0.75 * PL); chk("Out = 75 % (cmd 2, In reste)", (GM[x + 5] + GM[x + 6]) / PL, 0.75); chk("... In inchange", GM[x + 5] / PL, 0.25)
edit(5, 0.40 * PL); chk("cmd 5 : fenetre decalee (In 40 %)", GM[x + 5] / PL, 0.40); chk("... ecart garde (50 %)", GM[x + 6] / PL, 0.50)
edit(1, 0.10 * PL); chk("cmd 1 : In 10 %, Out reste a 90 %", (GM[x + 5] + GM[x + 6]) / PL, 0.90)
cmd(1); step(secs(2.0)); cmd(1); step(4)
L = m.v_length
chk("boucle de 2 s", L / SR, 2.0, 0.05)
chk("In applique = 10 % de la boucle", m.v_loop_start / L, 0.10, 0.003)
chk("Out applique = 90 %", (m.v_loop_start + m.v_loop_width) / L, 0.90, 0.003)
chk("plus de longueur fictive", GM[x + 4], 0, 0)
ins = True
for _ in range(secs(1.5)):
    step(1); p = m.v_pos
    if not (m.v_loop_start - 2 <= p <= m.v_loop_start + m.v_loop_width + 2): ins = False
chk("la tete reste dans la fenetre (1,5 s)", 1 if ins else 0, 1, 0)
cmd(2); step(4)
chk("apres Clear : fenetre fictive pleine", GM[x + 6] / GM[x + 4], 1.0)
edit(1, 0.3 * PL); cmd(2); step(4)
chk("Clear d'un looper vide : pre-reglage oublie", GM[x + 5], 0, 0)
cmd(1); step(secs(1.0)); cmd(1); step(4)
chk("sans pre-reglage : boucle pleine", m.v_loop_width / m.v_length, 1.0)
print("TOUT OK" if fails[0] == 0 else "%d ECHEC(S)" % fails[0])
