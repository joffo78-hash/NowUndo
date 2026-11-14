import re, sys
import os; exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'luabal.py')).read().split("def bal")[0])
def count(src):
    s = strip(src)
    toks = re.findall(r'[A-Za-z_]\w*|==|~=|<=|>=|\.\.\.|\.\.|[^\sA-Za-z_]', s)
    d = 0; n = 0; i = 0
    while i < len(toks):
        w = toks[i]
        if w == 'local':
            if toks[i+1] == 'function':
                if d == 0: n += 1
                i += 1; continue
            j = i + 1; names = 0
            while j < len(toks):
                if re.match(r'[A-Za-z_]\w*$', toks[j]):
                    names += 1; j += 1
                    if j < len(toks) and toks[j] == '<':  # attribs
                        j += 3
                    if j < len(toks) and toks[j] == ',': j += 1; continue
                break
            if d == 0: n += names
        elif w in ('function', 'if', 'do', 'repeat'): d += 1
        elif w in ('end', 'until'): d -= 1
        i += 1
    return n, d
for f in sys.argv[1:]:
    print(f.split('/')[-1], 'locales niveau principal = %d (profondeur finale %d)' % count(open(f, encoding='utf-8').read()))
