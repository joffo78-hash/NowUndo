import re, sys
def strip(src):
    src = re.sub(r'--\[(=*)\[.*?\]\1\]', '', src, flags=re.S)
    src = re.sub(r'\[(=*)\[.*?\]\1\]', '""', src, flags=re.S)
    out=[]; i=0; n=len(src)
    while i<n:
        c=src[i]
        if src.startswith('--',i):
            j=src.find('\n',i); i = n if j<0 else j; continue
        if c in '"\'':
            q=c; i+=1
            while i<n and src[i]!=q:
                if src[i]=='\\': i+=1
                i+=1
            i+=1; out.append('""'); continue
        out.append(c); i+=1
    return ''.join(out)
def bal(src):
    t = re.findall(r'\b(function|if|do|end|repeat|until|elseif|then|for|while)\b', strip(src))
    d=0; mn=0
    for w in t:
        if w in ('function','if','do','repeat'): d+=1
        elif w in ('end','until'): d-=1
        mn=min(mn,d)
    return d, mn, src.count('(')-src.count(')'), src.count('{')-src.count('}')
for f in sys.argv[1:]:
    print(f.split('/')[-1], 'profondeur finale / min / () / {} :', bal(open(f,encoding='utf-8').read()))
