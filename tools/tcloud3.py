"""Cloud : clics quand on bouge les reglages en jouant (voix). cd tools && python3 tcloud3.py . fichier.jsfx"""
import sys, math
sys.path.insert(0, '.')
import bench
from bench import *
from tvoice_sig import voice
JS = sys.argv[2]
def detect(out, a):
    d2 = [abs(out[i][0] - 2*out[i-1][0] + out[i-2][0]) for i in range(a, len(out))]
    ev = []; W = 240; i = W
    while i < len(d2) - W:
        loc = sorted(d2[i-W:i+W:4])[int(W/2*0.9)]
        if d2[i] > 4 * loc + 0.004:
            ev.append(((a + i) / SR, d2[i])); i += 240
        i += 1
    return ev
def case(label, steps, base={}):
    m = load(JS, 'k' + JS[1:4]); bench.jsfx_path_of[m] = JS
    r = Run(m, voice)
    b = 1000 + int(m.v_inst_idx) * 600
    m.GM[b+48] = 1; r.run(SR*2); m.GM[b+48] = 1; r.run(SR//2)
    r.set(cloud_on=1, cloud_density=0.95, cloud_size=280, **base); r.run(SR//2)
    a = len(r.out)
    for kw, n in steps:
        if kw: r.set(**kw)
        r.run(n)
    ev = detect(r.out, a)
    print('  %-34s pics anormaux %3d %s' % (label, len(ev), [(round(t,3), round(v,3)) for t, v in ev[:5]]), flush=True)
B = SR // 100
case('rien ne bouge', [({}, SR*2)])
case('Cloud on/off toutes 0,4 s', [({'cloud_on': k % 2}, SR*2//5) for k in range(6)])
case('Freeze on/off toutes 0,4 s', [({'cloud_freeze': (k+1) % 2}, SR*2//5) for k in range(6)])
case('Size 280 -> 20 -> 280 (knob)', [({'cloud_size': 280 * (0.98 ** k)}, B) for k in range(130)] + [({'cloud_size': 20 * (1.02 ** k)}, B) for k in range(130)])
case('Pos 0 -> 100 % (knob, Free)', [({'cloud_pos_pct': k}, B) for k in range(0, 101)])
case('Densite 95 -> 20 % (knob)', [({'cloud_density': 0.95 - k * 0.005}, B) for k in range(150)])
case('Dry/Wet 100 -> 0 -> 100', [({'cloud_mix': abs(1 - k / 50)}, B) for k in range(101)])
case('Agitation 0 -> 100 %', [({'cloud_chaos': k / 100}, B) for k in range(101)])
case('Spread 0 -> 100 %', [({'cloud_spread': k / 100}, B) for k in range(101)])
