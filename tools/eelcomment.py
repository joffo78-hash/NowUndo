"""EEL2 : signale les commentaires // qui cachent probablement du code (code apres le // sur la meme ligne).
python3 tools/eelcomment.py f.jsfx"""
import sys, re
n = 0
for i, line in enumerate(open(sys.argv[1], encoding='utf-8'), 1):
    k = line.find('//')
    if k < 0 or '"' in line[:k] or not line[:k].strip(): continue
    c = line[k + 2:]
    # du code : affectation terminee par ; ou appel suivi de ;
    if re.search(r'\b[a-z_][a-z_0-9\[\]]*\s*(=|\+=|-=|\*=)\s*[^=;]+;', c, re.I) :
        n += 1; print('%d: %s' % (i, line.rstrip()[:200]))
print('OK : aucun code cache par un //' if n == 0 else '%d ligne(s) a verifier' % n)
