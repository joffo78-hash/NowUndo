"""Clic a la sortie du REC (voix) : cd tools && python3 trecx.py . fichier.jsfx"""
import sys
sys.path.insert(0, '.')
import bench
from bench import *
from tvoice_sig import voice
from tcloud3 import detect
JS = sys.argv[2]
m = load(JS, 'x' + JS[1:4]); bench.jsfx_path_of[m] = JS
r = Run(m, voice); b = 1000 + int(m.v_inst_idx) * 600
r.set(mix=1.0) if False else None
m.GM[b+48] = 1; r.run(int(SR*2.0)); t_exit = len(r.out) / SR
m.GM[b+48] = 1; r.run(SR*5)
L = m.GM[b+46]
print('longueur %.4f s, sortie du REC a %.3f s' % (L / SR, t_exit))
ev = detect(r.out, int(SR * 1.0))
print('pics anormaux :', [(round(t, 3), round(v, 3)) for t, v in ev])
