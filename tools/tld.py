import sys
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
m = load('v323.jsfx', 'ld'); bench.jsfx_path_of[m] = 'v323.jsfx'
r = Run(m, lambda n: 0.0)
LD = int(m.v_LD_BASE)
base = 1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200
m.GM[0] = 1; m.GM[1] = 77; m.GM[2] = 96000          # un autre looper est maitre, boucle de 96000 samples
for ratio in (0.3, 0.52, 0.6, 0.8, 1.6):
    m.GM[LD+1] = int(ratio * 96000); m.GM[LD+2] = 5; m.GM[base+48] = 32
    r.run(BLK)
    print('fichier', ratio, 'boucle -> longueur adaptee', m.GM[LD+5] / 96000, 'boucle(s)')
