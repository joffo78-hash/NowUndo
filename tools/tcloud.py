"""Clics du Cloud (V3.26) : cd tools && python3 tcloud.py . fichier.jsfx (source tonale, 2 s de Cloud par reglage)."""
import sys
sys.path.insert(0, '.')
import bench
from bench import *
JS = sys.argv[2]
def case(label, sig=sig_tonal, **kw):
    m = load(JS, 'c' + JS[1:4]); bench.jsfx_path_of[m] = JS
    r = Run(m, sig)
    b = 1000 + int(m.v_inst_idx) * 600
    m.GM[b+48] = 1; r.run(SR*2); m.GM[b+48] = 1; r.run(SR//2)
    r.set(cloud_on=1, **kw); a = len(r.out); r.run(SR*2)
    mx, at, cnt = clicks(r.out, a + SR//10, len(r.out))
    print('  %-40s max 2e diff %.4f  depassements %d' % (label, mx, cnt))
print(JS)
case('defaut (Free)')
case('Linked', cloud_pos_mode=0)
case('size 20 ms', cloud_size=20)
case('densite 100%', cloud_density=1.0)
case('agitation 100%', cloud_chaos=1.0)
case('pitch spread 100%', cloud_pitch_spread=100)
case('LFO 100% 4 Hz', cloud_lfo_depth=100, cloud_lfo_rate=4)
case('LFO saw 100% 4 Hz', cloud_lfo_depth=100, cloud_lfo_rate=4, cloud_lfo_shape=1)
case('speed 2 / pitch +12', speed=2.0)
case('diffuse 100%', cloud_diffuse=1.0)
