"""Clics du Beat Repeat (V3.26) sur une voix : cd tools && python3 tbr.py . fichier.jsfx <loop_quant 0..9> (source = /tmp/aud3/direct.wav, a remplacer)"""
import sys, numpy as np
sys.path.insert(0, '.')
import bench
from bench import *
bench.BLK = 128
from scipy.io import wavfile
sr, d = wavfile.read('/tmp/aud3/direct.wav'); d = d.astype(np.float64) / 2147483648.0
dl = d[:, 0]
JS = sys.argv[2]; Q = float(sys.argv[3])
def sig(n): return float(dl[n % len(dl)])
m = load(JS, 'b' + JS[1:4]); bench.jsfx_path_of[m] = JS
r = Run(m, sig)
b = 1000 + int(m.v_inst_idx) * 600
m.GM[b+48] = 1; r.run(int(SR*3.9)); m.GM[b+48] = 1; r.run(SR // 2)
r.set(loop_quant=Q)
r.sig = lambda n: 0.0
a = len(r.out)
for k in range(6):
    m.GM[b+48] = 33; r.run(int(SR * 0.37)); m.GM[b+48] = 33; r.run(int(SR * 0.29))
out = np.array([o[0] for o in r.out[a:]])
mid = 0.5 * (out[:-2] + out[2:]); dev = np.abs(out[1:-1] - mid); loc = np.convolve(dev, np.ones(64) / 64, 'same')
s = np.where(dev > 8 * loc + 0.005)[0] + 1; ev = []
for i in s:
    if not ev or i - ev[-1] > 50: ev.append(i)
d2 = np.abs(np.diff(out, 2))
print('quant %d : sauts %d | 2e diff max %.4f (voix seule ~%.4f) %s' % (Q, len(ev), d2.max(), np.abs(np.diff(dl, 2)).max(), [(round(i / SR, 3), round(float(dev[i-1]), 3)) for i in ev[:10]]))
