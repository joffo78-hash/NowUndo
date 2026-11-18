"""Bench: runs the translated JSFX on scenarios and measures clicks (second-difference spikes)."""
import sys, math, importlib.util, time, json
sys.setrecursionlimit(10000)
HERE = sys.argv[1]
sys.path.insert(0, HERE)
import eel2py

SR = 48000
BLK = 256

def load(jsfx, tag):
    # cloud / freeze sont a des adresses fixes (120 M) : on les ramene dans la memoire simulee (14 M)
    code, aliases = eel2py.translate(jsfx, patches=[("mem_budget = 120000000;", "mem_budget = 12000000;"),
                                                    ("cl_mem = 120000500;", "cl_mem = 11700000;"),
                                                    ("frz_l = 120100000; frz_max = 3600000;", "frz_l = 11800000; frz_max = 1000000;")])
    fn = '%s/_gen_%s.py' % (HERE, tag)
    open(fn, 'w').write(code)
    spec = importlib.util.spec_from_file_location('gen_' + tag, fn)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    return m

def sig_tonal(n):
    # continuous tonal content (clicks are easy to see on a sine)
    t = n / SR
    return 0.35 * math.sin(2 * math.pi * 110 * t) + 0.2 * math.sin(2 * math.pi * 330.5 * t)

def sig_drums(n):
    # one "hit" per eighth note at 120 bpm : decaying 180 Hz burst, + noise-free tonal bed
    t = n / SR
    per = SR * 0.25
    ph = n % per
    k = int(n // per)
    f = 180 if k % 2 == 0 else 420
    hit = 0.7 * (1 - math.exp(-ph / (SR * 0.0007))) * math.exp(-ph / (SR * 0.035)) * math.sin(2 * math.pi * f * ph / SR)
    return hit + 0.12 * math.sin(2 * math.pi * 97 * t)

class Run:
    def __init__(s, m, sig):
        s.m = m; s.sig = sig; s.n = 0; s.out = []; s.events = []
        m.v_srate = float(SR); m.v_samplesblock = float(BLK); m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 1.0
        m.v_beat_position = 0.0
        # slider defaults
        src = open(jsfx_path_of[m], encoding='utf-8').read()
        import re
        for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', src, re.M):
            setattr(m, 'v_' + mm.group(1), float(mm.group(2)))
        m.v_manual_id = 1.0
        m.sec_init(); m.sec_slider()
    def set(s, **kw):
        for k, v in kw.items(): setattr(s.m, 'v_' + k, float(v))
        s.m.sec_slider()
    def call(s, fname, *a):
        getattr(s.m, 'f_' + fname)(*[float(x) for x in a])
    def mark(s, label):
        s.events.append((s.n, label))
    def run(s, nsamp):
        m = s.m
        for _ in range(int(nsamp)):
            if s.n % BLK == 0:
                m._clock[0] = s.n / SR
                m.v_beat_position = s.n / SR * 2.0
                m.sec_block()
            x = s.sig(s.n)
            m.v_spl0 = x; m.v_spl1 = x * 0.9
            m.sec_sample()
            s.out.append((m.v_spl0, m.v_spl1))
            s.n += 1
            m._clock[0] = s.n / SR

jsfx_path_of = {}

def clicks(out, a, b, dry=None):
    """max |2nd difference| of wet output in [a, b) (dry removed = mix 1 => out is wet + dry*cos(pi/2)=0)"""
    mx = 0.0; at = a; cnt = 0
    for i in range(max(a, 2), min(b, len(out))):
        for c in (0, 1):
            d = abs(out[i][c] - 2 * out[i-1][c] + out[i-2][c])
            if d > mx: mx = d; at = i
            if d > 0.02: cnt += 1
    return mx, at, cnt

def sig_other(n):
    t = n / SR
    return 0.4 * math.sin(2 * math.pi * 251.3 * t + 1.0)
