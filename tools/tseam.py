"""Raccord de boucle / sortie de REC (son grave tenu) : cd tools && python3 tseam.py . fichier.jsfx [fade_ms]"""
import sys, math
sys.path.insert(0, '.')
import bench
from bench import *
JS = sys.argv[2]; FADE = float(sys.argv[3]) if len(sys.argv) > 3 else 0
def bass(n):                       # basse qui decroit + coups toutes les 0,45 s (comme l'enregistrement)
    t = n / SR; tp = t % 0.45
    return 0.25 * math.exp(-tp * 6) * math.sin(2 * math.pi * 55 * tp)
m = load(JS, 's' + JS[1:4]); bench.jsfx_path_of[m] = JS
r = Run(m, bass); b = 1000 + int(m.v_inst_idx) * 600
r.set(fade_ms=FADE)
r.run(int(SR * 0.2))                          # REC lance au milieu d'une note
m.GM[b+48] = 1; r.run(int(SR * 2.03)); t_exit = len(r.out)
m.GM[b+48] = 1; r.run(SR * 6)
L = int(m.GM[b+46])
o = [s[0] for s in r.out]
def steps(a, z):
    ev = []
    for i in range(max(a, 3), z):
        d2 = abs(o[i] - 2*o[i-1] + o[i-2]); loc = max(abs(o[j] - 2*o[j-1] + o[j-2]) for j in range(i-40, i-2))
        if d2 > 4 * loc + 0.003: ev.append((round(i / SR, 4), round(d2, 4)))
    return ev
print('Fade %g ms : longueur %.4f s, sortie du REC a %.4f s' % (FADE, L / SR, t_exit / SR))
ev = [e for e in steps(int(SR*0.3), len(o)) if e[1] > 0.02]
print('  marches > 0.02 :', ev[:12])
