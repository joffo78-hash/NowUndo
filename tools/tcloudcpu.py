"""Cloud : sortie + temps de calcul (densite forte). python3 tcloudcpu.py . f.jsfx"""
import sys, math, re, time
sys.path.insert(0, sys.argv[1])
import bench
from bench import *
path = sys.argv[2]
A = load(path, 'cc' + str(abs(hash(path)) % 1000)); GM = A.GM; m = A
m.v_srate = float(SR); m.v_samplesblock = 128.0; m.v_tempo = 120.0; m.v_ts_num = 4.0; m.v_play_state = 0.0
for mm in re.finditer(r'^slider\d+:([A-Za-z_][A-Za-z_0-9]*)=([-\d.]+)', open(path, encoding='utf-8').read(), re.M):
    setattr(m, 'v_' + mm.group(1).lower(), float(mm.group(2)))
A._clock[0] = 100.0; m.v_manual_id = 1.0; m.sec_init(); m.sec_slider()
N = [0]; OUT = []; T = []
def step(k, rec=False):
    for _ in range(k):
        n0 = N[0]; t = time.perf_counter(); m.sec_block()
        for i in range(128):
            n = n0 + i; x = 0.3 * math.sin(2 * math.pi * 220 * n / SR) * (1 if (n // 9000) % 2 else 0.3)
            m.v_spl0 = x; m.v_spl1 = x; m.sec_sample()
            if rec: OUT.append(m.v_spl0)
        if rec: T.append(time.perf_counter() - t)
        N[0] = n0 + 128
def cmd(c): GM[1000 + int(m.v_inst_idx) * 600 + (int(m.v_active_part) - 1) * 200 + 48] = c
cmd(1); step(int(2 * SR / 128)); cmd(1); step(20)
m.v_cloud_on = 1.0; m.v_cloud_density = 1.0; m.v_cloud_chaos = 0.3; m.sec_slider(); step(50)
step(int(2 * SR / 128), True)
d2 = [abs(OUT[i] - 2 * OUT[i - 1] + OUT[i - 2]) for i in range(2, len(OUT))]
print('%s : temps moyen/bloc %.2f ms, max %.2f ms | rms %.4f, 2e diff max %.4f' % (path, 1000 * sum(T) / len(T), 1000 * max(T),
      math.sqrt(sum(v * v for v in OUT) / len(OUT)), max(d2)))
open('_cc_' + path + '.txt', 'w').write('\n'.join('%.6f' % v for v in OUT))
