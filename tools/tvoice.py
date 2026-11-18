"""Cloud sur voix tenue forte (crete ~0.9) : ecretage / clics a forte densite. cd tools && python3 tvoice.py . fichier.jsfx 0.43"""
import sys, math
sys.path.insert(0, '.')
import bench
from bench import *
JS = sys.argv[2]
GAIN = float(sys.argv[3]) if len(sys.argv) > 3 else 0.18
def voice(n):
    t = n / SR
    f0 = 196 * (1 + 0.006 * math.sin(2 * math.pi * 5.5 * t))       # vibrato
    ph = 2 * math.pi * 196 * t - 0.006 * 196 / 5.5 * math.cos(2 * math.pi * 5.5 * t)
    s = 0
    for h in range(1, 16):
        a = (1.0 / h) * (1.6 if 3 <= h <= 5 else 1.0)                 # formant grossier
        s += a * math.sin(h * ph + h * 0.7)
    return GAIN * s
def case(label, **kw):
    m = load(JS, 'v' + JS[1:4]); bench.jsfx_path_of[m] = JS
    r = Run(m, voice)
    b = 1000 + int(m.v_inst_idx) * 600
    m.GM[b+48] = 1; r.run(SR*2); m.GM[b+48] = 1; r.run(SR//2)
    a0 = len(r.out); r.run(SR//2)
    dry, _, _ = clicks(r.out, a0 + 100, len(r.out))
    r.set(cloud_on=1, **kw); a = len(r.out); r.run(SR*3)
    out = r.out
    # clic = 2e difference anormale par rapport au voisinage (+-5 ms)
    d2 = [abs(out[i][0] - 2*out[i-1][0] + out[i-2][0]) for i in range(a + SR//10, len(out))]
    ev = []
    W = 240
    for i in range(W, len(d2) - W, 1):
        loc = sorted(d2[i-W:i+W])[int(2*W*0.9)]
        if d2[i] > 4 * loc + 0.004: ev.append(((a + SR//10 + i) / SR, d2[i], loc))
    pk0 = max(abs(o[0]) for o in out[a0:a]); pk = max(abs(o[0]) for o in out[a + SR//10:]); rm0 = (sum(o[0]**2 for o in out[a0:a])/(a-a0))**.5; rm = (sum(o[0]**2 for o in out[a+SR//10:])/(len(out)-a-SR//10))**.5
    over = sum(1 for o in out[a+SR//10:] if abs(o[0]) > 0.95)
    print('    > 0.95 (ecrete) : %d echantillons' % over)
    print('    crete seche %.3f nuage %.3f | rms seche %.3f nuage %.3f' % (pk0, pk, rm0, rm))
    print('  %-30s seche %.4f | nuage max %.4f | pics anormaux %d %s' % (label, dry, max(d2), len(ev), [(round(e[0],3), round(e[1],3)) for e in ev[:4]]))
    return m, r
case('densite 95%', cloud_density=0.95)
case('densite 50%', cloud_density=0.5)
case('densite 95% Link', cloud_density=0.95, cloud_pos_mode=0)
