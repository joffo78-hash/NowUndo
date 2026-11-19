"""Clics du Slicer / Beat Repeat pousses (voix) : cd tools && python3 tslc.py . fichier.jsfx"""
import sys, numpy as np
sys.path.insert(0, '.')
import bench
from bench import *
bench.BLK = 128
from scipy.io import wavfile
sr, d = wavfile.read('/tmp/aud3/direct.wav'); d = d.astype(np.float64) / 2147483648.0
dl = d[:, 0]
JS = sys.argv[2]
def jumps(out):
    out = np.asarray(out); mid = 0.5 * (out[:-2] + out[2:]); dev = np.abs(out[1:-1] - mid)
    loc = np.convolve(dev, np.ones(64) / 64, 'same'); s = np.where(dev > 8 * loc + 0.005)[0] + 1; ev = []
    for i in s:
        if not ev or i - ev[-1] > 50: ev.append(i)
    return ev, dev
def case(label, setup, act=None, T=3.0):
    m = load(JS, 'z' + JS[1:4]); bench.jsfx_path_of[m] = JS
    r = Run(m, lambda n: float(dl[n % len(dl)]))
    b = 1000 + int(m.v_inst_idx) * 600
    m.GM[b+48] = 1; r.run(int(SR*3.9)); m.GM[b+48] = 1; r.run(SR // 2)
    r.sig = lambda n: 0.0
    r.set(**setup)
    if act: act(m, b, r)
    a = len(r.out); r.run(int(SR * T))
    ev, dev = jumps([o[0] for o in r.out[a:]])
    print('  %-42s sauts %3d / %.0f s  %s' % (label, len(ev), T, [(round(i / SR, 3), round(float(dev[i-1]), 3)) for i in ev[:5]]), flush=True)
def slc(m, b, r): m.GM[b+48] = 6; r.run(BLK * 2)
def br(m, b, r): m.GM[b+48] = 33; r.run(BLK * 2)
def toggles(m, b, r):
    slc(m, b, r)
    for k in range(8): m.GM[b+48] = 33; r.run(int(SR * 0.17))
case('BR 1/16 + slicer 1/16 All', {'loop_quant': 7, 'slicer_sub': 3}, lambda m, b, r: (slc(m, b, r), br(m, b, r)))
case('BR 1/64 + slicer 1/32 Random Grid', {'loop_quant': 9, 'slicer_sub': 5, 'slicer_mode': 0, 'slicer_src': 1, 'src_auto': 0}, lambda m, b, r: (slc(m, b, r), br(m, b, r)))
case('slicer 1/32 + BR on/off x8', {'loop_quant': 8, 'slicer_sub': 5, 'slicer_mode': 0}, toggles)
case('BR 1/32 + slicer + reverse', {'loop_quant': 8, 'slicer_sub': 5, 'slicer_mode': 0}, lambda m, b, r: (slc(m, b, r), br(m, b, r), m.GM.__setitem__(b+48, 4), r.run(BLK*2)))
