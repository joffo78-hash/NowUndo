# MSV3 + Auto-Tempo : choix des temps / tempo publie en gmem 917-919 (banc eel2py)
import sys; sys.path.insert(0, '.')
from eel2py import translate
code, al = translate('../NowUndo/master_synchro', sections_wanted=('init', 'block', 'gfx'), patches=[('#at_menu = slider10 < 1 ? "!Auto" : "Auto";', '0;'), ('#mb_m = ""; mb_k = 1;', 'mb_k = 1;'), ('#mb_m = ""; mb_k = 0;', 'mb_k = 0;')])
ns = {}; exec(code, ns)
def setv(k, v): ns['v_' + k] = float(v)
def gm(i): return ns['_gget'](i) if '_gget' in ns else ns['gmem'][i]
setv('srate', 48000); setv('ts_num', 4); setv('tempo', 100)
ns['sec_init']()
G = ns['GMEM'] if 'GMEM' in ns else None
def gset(i, v): ns['_gset'](i, v)
def run(t):
    ns['sec_block']()
    print("%-44s -> %2d temps = %7.2f BPM  (917=%.2f 918=%d 919=%d)" % (t, gm(918), gm(917), gm(917), gm(918), gm(919)))
run("pas de maitre")
gset(0, 1); gset(1, 11); gset(2, 48000 * 4); gset(910, 0)            # looper maitre, boucle 4 s
run("boucle 4 s, Auto, tempo 100")
gset(2, 48000 * 3); run("boucle 3 s, Auto")
gset(2, int(48000 * 2.044)); run("boucle 2.044 s, Auto")
ns['f_at_set'](16); run("temps forces 16 (boucle 2.044 s)")
ns['f_at_set'](0); gset(1000, 11); gset(1000 + 31, 12); run("Loop Beats du looper = 12")
for k in range(3): ns['sec_gfx']()
print("interface (gfx) executee sans erreur ; tolerance re-phase gmem[92] =", gm(92), "| mesures Host =", ns.get('v_host_sync_meas'))
