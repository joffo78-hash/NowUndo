"""EEL2 : une fonction doit etre definie AVANT son premier appel dans @init (sinon REAPER : "'f' undefined").
Le traducteur Python ne le voit pas. Usage : python3 tools/eelorder.py NowUndo/NowUndo_V3.27.jsfx"""
import re, sys
s = open(sys.argv[1], encoding='utf-8').read()
s = re.sub(r'//[^\n]*', '', s)
init = s[s.index('@init'):]
nxt = re.search(r'^@(slider|block|sample|gfx|serialize)', init, re.M)
init = init[:nxt.start()] if nxt else init
defs = {}
for m in re.finditer(r'^\s*function\s+(\w+)\s*\(', init, re.M): defs.setdefault(m.group(1).lower(), m.start())
bad = set()
for name, pos in defs.items():
    for m in re.finditer(r'(?<![\w.])' + re.escape(name) + r'\s*\(', init, re.I):
        if m.start() < pos and not re.search(r'function\s+$', init[max(0, m.start() - 12):m.start()]):
            bad.add((name, init[:m.start()].count('\n') + 1))
print('OK : aucun appel avant definition' if not bad else 'ERREUR : ' + ', '.join('%s (ligne %d de @init)' % b for b in sorted(bad)))
sys.exit(1 if bad else 0)
