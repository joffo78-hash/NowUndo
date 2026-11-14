import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
T1, T2 = int(SR*0.5), int(SR*2.5)
def sig(n):
    t = n / SR
    bed = 0.05 * math.sin(2*math.pi*97*t)
    for T in (T1, T2):
        if 0 <= n - T < 480: bed += 0.8 * math.exp(-(n-T)/80.0) * math.sin(2*math.pi*800*(n-T)/SR)
    return bed
for tag, path in (('321','v321.jsfx'), ('322','v322.jsfx')):
    m = load(path, 'lat'+tag); bench.jsfx_path_of[m] = path
    r = Run(m, sig)
    base = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200
    def press(Tpress, delay):
        target = Tpress + int(delay * SR)
        target = (target // BLK + 1) * BLK          # la commande est lue au bloc suivant
        r.run(target - r.n)
        m.GM[950] = Tpress / SR; m.GM[951] = base + 48; m.GM[base + 48] = 1
        return target
    a = press(T1, 0.030)
    b = press(T2, 0.025)
    r.run(SR // 4)
    L = int(m.v_length); lb = int(m.v_left_buf)
    buf = m.M[lb:lb + L]
    pk = max(range(min(L, 6000)), key=lambda i: abs(buf[i]))
    print(tag, 'cmd REC a', a - T1, 'samples apres le coup ; STOP a', b - T2,
          '| longueur', L, '(attendu', T2 - T1, ', ecart', L - (T2 - T1), ') | pic du coup dans la boucle a l\'index', pk,
          'amplitude', round(abs(buf[pk]), 3), '| pos lecture', round(m.v_pos), 'etat', m.v_state)
