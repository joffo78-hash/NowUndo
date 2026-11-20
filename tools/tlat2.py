import sys, math
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
LAT = 400
ST = {'F': None, 'Len': None, 'mode': 'rec', 'P0': []}
CL = [int(SR*0.3), int(SR*0.8), int(SR*1.3)]   # instants des clics pendant le 1er REC (rec demarre a 1024)
def burst(d, f=900): return 0.6 * math.exp(-d/60.0) * math.sin(2*math.pi*f*d/SR) if 0 <= d < 400 else 0.0
def sig(n):
    if ST['mode'] == 'rec':
        return sum(burst(n - c) for c in CL)
    if ST['mode'] == 'dub':
        ph = (n - ST['F']) % ST['Len']
        return sum(burst(ph - (c + LAT), 600) for c in ST['P0'])   # joue sur les coups qu'il ENTEND (ceux de la boucle) : arrive LAT apres la tete
    return 0.0
def peaks(buf):
    out = []; i = 0
    while i < len(buf):
        if abs(buf[i]) > 0.25:
            j = max(range(i, min(i+120, len(buf))), key=lambda q: abs(buf[q])); out.append(j); i += 2000
        else: i += 1
    return out
for tag, path in (('322','v322.jsfx'), ('323','v323.jsfx')):
    ST['mode'] = 'rec'
    m = load(path, 'lt'+tag); bench.jsfx_path_of[m] = path
    m.GM[955] = LAT; m.GM[957] = 1
    r = Run(m, sig)
    r.run(1024); r.set(rec_cmd=1); r.run(SR*2 - 1024); r.set(rec_cmd=1); r.run(1)
    ST['F'] = r.n; ST['Len'] = int(m.v_length)
    L = ST['Len']; lb = int(m.v_left_buf)
    b0 = list(m.M[lb:lb+L]); p0 = peaks(b0); ST['P0'] = [p - 60 for p in p0]
    ST['mode'] = 'dub'
    r.set(state_target=3); r.run(L + 2000); r.set(state_target=2); r.run(10)
    ST['mode'] = 'off'
    lb = int(m.v_left_buf)
    d = [x - y for x, y in zip(m.M[lb:lb+L], b0)]
    p1 = peaks(d)
    print(tag, 'clics de la boucle', p0, '| clics de l overdub', p1, '| decalage overdub - boucle :', [b - a for a, b in zip(p0, p1)])
