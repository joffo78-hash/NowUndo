"""REC synchro Host (REAPER en lecture) + compensation de latence : calage des attaques et saut a la sortie du REC.
cd tools && python3 thost.py . fichier.jsfx [latence_samples]"""
import sys, numpy as np
sys.path.insert(0, '.')
import bench
from bench import *
JS = sys.argv[2]; L = int(sys.argv[3]) if len(sys.argv) > 3 else 700; MODE = sys.argv[4] if len(sys.argv) > 4 else 'host'
BEAT = SR // 2                                   # 120 BPM
def inp(n):                                      # coup joue pile sur le temps, arrive en retard de L (aller-retour)
    k = (n - L) % BEAT
    return 0.6 * np.exp(-k / 300.0) * np.sin(2 * np.pi * 180 * k / SR) if n >= L else 0.0
m = load(JS, 'h' + JS[1:4]); bench.jsfx_path_of[m] = JS
m.GM[0] = 2 if MODE == 'host' else 0; m.GM[955] = L; m.GM[956] = 0; m.GM[957] = 0       # Master Sync = Host, latence auto = L
r = Run(m, inp); b = 1000 + int(m.v_inst_idx) * 600
r.run(int(SR * 0.5) if MODE != 'host' else int(SR * 0.3)); m.GM[b+48] = 1                          # REC (libre : appui pile sur un temps)
r.run(int(SR * 2.0) if MODE != 'host' else int(SR * 2.4)); m.GM[b+48] = 1                          # fin du REC (attend la fin de mesure)
r.sig = lambda n: 0.0                                          # plus d'entree : on n'entend que la boucle
r.run(int(SR * 6))
o = np.array([s[0] for s in r.out]); st = m.GM[b+2]
print('etat %d, longueur %.3f s' % (st, m.GM[b+46] / SR))
# attaques de la boucle jouee (apres la sortie du REC)
e = np.abs(o); hits = []; i = int(SR * 4.0)
while i < len(o):
    if e[i] > 0.15:
        j = i
        while j > 0 and e[j-1] > 0.003 and i - j < 200: j -= 1
        hits.append(j); i += int(SR * 0.3)
    i += 1
print('attaques vs temps de REAPER (ms) :', ' '.join('%+.1f' % (((h + BEAT/2) % BEAT - BEAT/2) / SR * 1000) for h in hits[:12]))
d2 = np.abs(o[2:] - 2 * o[1:-1] + o[:-2])
big = [(round((k + 1) / SR, 4), round(float(d2[k]), 3)) for k in range(int(SR * 3.9), int(SR * 4.6)) if d2[k] > 0.05]
print('ruptures autour de la sortie du REC :', big[:10])
