"""Minimal EEL2/JSFX -> Python translator (test harness only, not a full implementation).
Handles the subset used by NowUndo: expressions, ?:, && ||, assignments, mem[] / gmem[], loop, while,
user functions with local(), builtins. Strings / gfx are stubbed to 0."""
import re, math, random, sys

TOK = re.compile(r"""
 (?P<ws>\s+|//[^\n]*|/\*.*?\*/)
|(?P<num>(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?)
|(?P<str>"(?:[^"\\]|\\.)*")
|(?P<chr>'(?:[^'\\]|\\.)*')
|(?P<id>[A-Za-z_#$][A-Za-z_0-9.]*)
|(?P<op>\+=|-=|\*=|/=|%=|\^=|\|=|&=|===|!==|==|!=|<=|>=|&&|\|\||<<|>>|[-+*/%^!<>=?:;,()\[\]&|~])
""", re.X | re.S)

def lex(src):
    out = []
    i = 0
    while i < len(src):
        m = TOK.match(src, i)
        if not m:
            raise SyntaxError("lex error at %r" % src[i:i+40])
        i = m.end()
        k = m.lastgroup
        if k == 'ws':
            continue
        out.append((k, m.group(k)))
    out.append(('eof', None))
    return out

# ---------------- parser -> AST tuples ----------------
class P:
    def __init__(s, toks, name=''):
        s.t = toks; s.i = 0; s.name = name
    def peek(s, o=0): return s.t[s.i + o]
    def nx(s):
        t = s.t[s.i]; s.i += 1; return t
    def exp(s, v):
        t = s.nx()
        if t[1] != v:
            ctx = ' '.join(str(x[1]) for x in s.t[max(0, s.i-12):s.i+4])
            raise SyntaxError("[%s] expected %r got %r near: %s" % (s.name, v, t[1], ctx))
    def is_op(s, v, o=0):
        t = s.peek(o); return t[0] == 'op' and t[1] == v

    def seq(s, stops):
        items = []
        while True:
            t = s.peek()
            if t[0] == 'eof' or (t[0] == 'op' and t[1] in stops):
                break
            if s.is_op(';'):
                s.nx(); continue
            items.append(s.assign())
            if s.is_op(';'):
                s.nx()
            else:
                t = s.peek()
                if not (t[0] == 'eof' or (t[0] == 'op' and t[1] in stops)):
                    ctx = ' '.join(str(x[1]) for x in s.t[max(0, s.i-12):s.i+4])
                    raise SyntaxError("[%s] unexpected %r near: %s" % (s.name, t[1], ctx))
        return ('seq', items)

    ASSIGN = ('=', '+=', '-=', '*=', '/=', '%=', '^=', '|=', '&=')
    def assign(s):
        lhs = s.ternary()
        t = s.peek()
        if t[0] == 'op' and t[1] in P.ASSIGN:
            s.nx()
            rhs = s.assign()
            if lhs[0] not in ('var', 'idx'):
                raise SyntaxError("[%s] bad lvalue %r" % (s.name, lhs))
            return ('asg', t[1], lhs, rhs)
        return lhs
    def ternary(s):
        c = s.logic()
        if s.is_op('?'):
            s.nx()
            a = s.assign()
            b = None
            if s.is_op(':'):
                s.nx(); b = s.assign()
            return ('tern', c, a, b)
        return c
    def logic(s):
        l = s.cmp()
        while s.is_op('&&') or s.is_op('||'):
            op = s.nx()[1]; r = s.cmp(); l = ('and' if op == '&&' else 'or', l, r)
        return l
    def cmp(s):
        l = s.bit()
        while s.peek()[0] == 'op' and s.peek()[1] in ('==', '!=', '<', '>', '<=', '>=', '===', '!=='):
            op = s.nx()[1]; r = s.bit(); l = ('bin', op, l, r)
        return l
    def bit(s):
        l = s.add()
        while s.peek()[0] == 'op' and s.peek()[1] in ('|', '&', '~'):
            op = s.nx()[1]; r = s.add(); l = ('bin', op, l, r)
        return l
    def add(s):
        l = s.mul()
        while s.peek()[0] == 'op' and s.peek()[1] in ('+', '-'):
            op = s.nx()[1]; r = s.mul(); l = ('bin', op, l, r)
        return l
    def mul(s):
        l = s.shift()
        while s.peek()[0] == 'op' and s.peek()[1] in ('*', '/'):
            op = s.nx()[1]; r = s.shift(); l = ('bin', op, l, r)
        return l
    def shift(s):
        l = s.mod()
        while s.peek()[0] == 'op' and s.peek()[1] in ('<<', '>>'):
            op = s.nx()[1]; r = s.mod(); l = ('bin', op, l, r)
        return l
    def mod(s):
        l = s.pw()
        while s.is_op('%'):
            s.nx(); r = s.pw(); l = ('bin', '%', l, r)
        return l
    def pw(s):
        l = s.unary()
        while s.is_op('^'):
            s.nx(); r = s.unary(); l = ('bin', '^', l, r)
        return l
    def unary(s):
        if s.is_op('-'):
            s.nx(); return ('neg', s.unary())
        if s.is_op('+'):
            s.nx(); return s.unary()
        if s.is_op('!'):
            s.nx(); return ('not', s.unary())
        return s.postfix()
    def postfix(s):
        e = s.primary()
        while s.is_op('['):
            s.nx()
            i = s.seq((']',)) if not s.is_op(']') else ('num', 0.0)
            s.exp(']')
            e = ('idx', e, i)
        return e
    def primary(s):
        t = s.nx()
        if t[0] == 'num': return ('num', float(t[1]))
        if t[0] in ('str', 'chr'): return ('num', 0.0)
        if t[0] == 'op' and t[1] == '(':
            if s.is_op(')'):
                s.nx(); return ('num', 0.0)
            e = s.seq((')',)); s.exp(')'); return e
        if t[0] == 'id':
            name = t[1]
            if name == '$pi': return ('num', math.pi)
            if name.startswith('#'): return ('num', 0.0)
            if s.is_op('('):
                s.nx()
                args = []
                if not s.is_op(')'):
                    while True:
                        args.append(s.seq((',', ')')))
                        if s.is_op(','):
                            s.nx(); continue
                        break
                s.exp(')')
                if name == 'while' and s.is_op('('):
                    s.nx(); body = s.seq((')',)) if not s.is_op(')') else ('seq', []); s.exp(')')
                    return ('while2', args[0], body)
                return ('call', name, args)
            return ('var', name)
        ctx = ' '.join(str(x[1]) for x in s.t[max(0, s.i-12):s.i+4])
        raise SyntaxError("[%s] unexpected token %r near: %s" % (s.name, t, ctx))

def parse_section(src, name):
    """returns (funcs, ast) ; function definitions are extracted"""
    toks = lex(src)
    funcs = []
    out = []
    i = 0
    # split out function definitions at top level
    depth = 0
    cur = []
    k = 0
    while k < len(toks):
        t = toks[k]
        if t[0] == 'id' and t[1] == 'function' and depth == 0:
            # function name ( params ) [spec(...)]* ( body )
            k += 1
            fname = toks[k][1]; k += 1
            assert toks[k][1] == '(', (name, fname)
            k += 1; params = []
            while toks[k][1] != ')':
                if toks[k][0] == 'id': params.append(toks[k][1])
                k += 1
            k += 1
            locs = []
            while toks[k][0] == 'id':
                spec = toks[k][1]; k += 1
                assert toks[k][1] == '('; k += 1
                while toks[k][1] != ')':
                    if toks[k][0] == 'id': locs.append(toks[k][1])
                    k += 1
                k += 1
                assert spec in ('local', 'instance', 'globals', 'global'), spec
            assert toks[k][1] == '(', (name, fname, toks[k])
            # find matching paren
            d = 0; j = k
            while True:
                if toks[j][1] == '(' and toks[j][0] == 'op': d += 1
                elif toks[j][1] == ')' and toks[j][0] == 'op':
                    d -= 1
                    if d == 0: break
                j += 1
            body_toks = toks[k+1:j] + [('eof', None)]
            body = P(body_toks, name + ':' + fname).seq(())
            funcs.append((fname, params, locs, body))
            k = j + 1
            continue
        if t[0] == 'op' and t[1] in '([': depth += 1
        if t[0] == 'op' and t[1] in ')]': depth -= 1
        cur.append(t); k += 1
    p = P(cur, name)
    ast = p.seq(())
    return funcs, ast

# ---------------- code generation ----------------
BUILTIN = {
    'min': 'min', 'max': 'max', 'abs': 'abs', 'floor': '_floor', 'ceil': '_ceil', 'sin': 'math.sin', 'cos': 'math.cos',
    'exp': '_exp', 'log': '_log', 'sqrt': '_sqrt', 'rand': '_rand', 'time_precise': '_time', 'memset': '_memset',
    'memcpy': '_memcpy', 'midirecv': '_zero', 'midisend': '_zero', 'round': '_round', 'pow': '_pow', 'tan': 'math.tan',
    'atan': 'math.atan', 'atan2': 'math.atan2', 'sign': '_sign', 'log10': '_log10',
}
class Gen:
    def __init__(s, aliases):
        s.n = 0; s.aliases = aliases; s.globals_used = set(); s.funcs = set()
    def tmp(s):
        s.n += 1; return '_t%d' % s.n
    def vname(s, name):
        name = s.aliases.get(name, name)
        if name in s.locals: return 'L_' + name.replace('.', '_')
        s.globals_used.add(name)
        return 'v_' + name.replace('.', '_')
    def is_simple(s, e):
        return re.fullmatch(r"[-\w.]+", e) is not None
    def ex(s, node, blk, ind):
        k = node[0]
        if k == 'num': return repr(node[1])
        if k == 'var': return s.vname(node[1])
        if k == 'seq':
            r = '0.0'
            for it in node[1]:
                r = s.ex(it, blk, ind)
            return r
        if k == 'neg':
            return '(-%s)' % s.ex(node[1], blk, ind)
        if k == 'not':
            return '(0.0 if _tr(%s) else 1.0)' % s.ex(node[1], blk, ind)
        if k == 'bin':
            op = node[1]
            a = s.ex(node[2], blk, ind)
            mark = len(blk)
            b = s.ex(node[3], blk, ind)
            if len(blk) > mark and not re.fullmatch(r"[-\d.e]+", a):
                t = s.tmp(); blk.insert(mark, ind + '%s = %s' % (t, a)); a = t
            if op in ('+', '-', '*'): return '(%s %s %s)' % (a, op, b)
            if op == '/': return '_div(%s, %s)' % (a, b)
            if op == '%': return '_mod(%s, %s)' % (a, b)
            if op == '^': return '_pow(%s, %s)' % (a, b)
            if op in ('==', '==='): return '(1.0 if abs(%s - %s) < 0.00001 else 0.0)' % (a, b)
            if op in ('!=', '!=='): return '(0.0 if abs(%s - %s) < 0.00001 else 1.0)' % (a, b)
            if op in ('<', '>', '<=', '>='): return '(1.0 if %s %s %s else 0.0)' % (a, op, b)
            if op == '&': return 'float(int(%s) & int(%s))' % (a, b)
            if op == '|': return 'float(int(%s) | int(%s))' % (a, b)
            if op == '~': return 'float(int(%s) ^ int(%s))' % (a, b)
            if op == '<<': return 'float(int(%s) << int(%s))' % (a, b)
            if op == '>>': return 'float(int(%s) >> int(%s))' % (a, b)
            raise ValueError(op)
        if k in ('and', 'or'):
            t = s.tmp()
            a = s.ex(node[1], blk, ind)
            blk.append(ind + '%s = 1.0 if _tr(%s) else 0.0' % (t, a))
            blk.append(ind + ('if %s:' if k == 'and' else 'if not %s:') % t)
            sub = []
            b = s.ex(node[2], sub, ind + '  ')
            sub.append(ind + '  %s = 1.0 if _tr(%s) else 0.0' % (t, b))
            blk.extend(sub)
            return t
        if k == 'tern':
            c = s.ex(node[1], blk, ind)
            t = s.tmp()
            blk.append(ind + 'if _tr(%s):' % c)
            sub = []; a = s.ex(node[2], sub, ind + '  '); sub.append(ind + '  %s = %s' % (t, a)); blk.extend(sub)
            blk.append(ind + 'else:')
            sub = []
            if node[3] is not None:
                b = s.ex(node[3], sub, ind + '  '); sub.append(ind + '  %s = %s' % (t, b))
            else:
                sub.append(ind + '  %s = 0.0' % t)
            blk.extend(sub)
            return t
        if k == 'idx':
            base = s.ex(node[1], blk, ind)
            if node[1] == ('var', 'gmem'):
                i = s.ex(node[2], blk, ind)
                return '_gget(%s)' % i
            i = s.ex(node[2], blk, ind)
            return '_mget(%s + %s)' % (base, i)
        if k == 'asg':
            op, lhs, rhs = node[1], node[2], node[3]
            if lhs[0] == 'var':
                v = s.vname(lhs[1])
                r = s.ex(rhs, blk, ind)
                if op == '=': blk.append(ind + '%s = %s' % (v, r))
                else: blk.append(ind + '%s = %s' % (v, s.binop(op[0], v, r)))
                return v
            else:
                isg = lhs[1] == ('var', 'gmem')
                if isg:
                    ix = s.tmp(); i = s.ex(lhs[2], blk, ind); blk.append(ind + '%s = _ix(%s)' % (ix, i))
                else:
                    base = s.ex(lhs[1], blk, ind); i = s.ex(lhs[2], blk, ind)
                    ix = s.tmp(); blk.append(ind + '%s = _ix(%s + %s)' % (ix, base, i))
                r = s.ex(rhs, blk, ind)
                t = s.tmp()
                getter = '_gget' if isg else '_mget'
                setter = '_gset' if isg else '_mset'
                if op == '=': blk.append(ind + '%s = %s' % (t, r))
                else: blk.append(ind + '%s = %s' % (t, s.binop(op[0], '%s(%s)' % (getter, ix), r)))
                blk.append(ind + '%s(%s, %s)' % (setter, ix, t))
                return t
        if k == 'while2':
            t = s.tmp()
            blk.append(ind + '%s = 0' % t)
            blk.append(ind + 'while True:')
            sub = []
            c = s.ex(node[1], sub, ind + '  ')
            sub.append(ind + '  if not _tr(%s): break' % c)
            s.ex(node[2], sub, ind + '  ')
            sub.append(ind + '  %s += 1' % t)
            sub.append(ind + '  if %s > 1000000: break' % t)
            blk.extend(sub)
            return '0.0'
        if k == 'call':
            name, args = node[1], node[2]
            if name == 'loop':
                n = s.ex(args[0], blk, ind)
                t = s.tmp()
                blk.append(ind + 'for %s in range(max(0, int(%s))):' % (t, n))
                sub = []
                s.ex(args[1], sub, ind + '  ')
                if not sub: sub.append(ind + '  pass')
                blk.extend(sub)
                return '0.0'
            if name == 'while':
                t = s.tmp()
                blk.append(ind + '%s = 0' % t)
                blk.append(ind + 'while True:')
                sub = []
                c = s.ex(args[0], sub, ind + '  ')
                sub.append(ind + '  %s += 1' % t)
                sub.append(ind + '  if not _tr(%s) or %s > 1000000: break' % (c, t))
                blk.extend(sub)
                return '0.0'
            vals = []
            for a in args:
                v = s.ex(a, blk, ind)
                if not re.fullmatch(r"[-\d.e]+", v):
                    tt = s.tmp(); blk.append(ind + '%s = %s' % (tt, v)); v = tt
                vals.append(v)
            if name in s.userfuncs:
                t = s.tmp(); blk.append(ind + '%s = f_%s(%s)' % (t, name, ', '.join(vals))); return t
            if name in BUILTIN:
                t = s.tmp(); blk.append(ind + '%s = %s(%s)' % (t, BUILTIN[name], ', '.join(vals))); return t
            # gfx / strings / misc -> 0
            return '0.0'
        raise ValueError(node)
    def binop(s, o, a, b):
        if o in '+-*': return '(%s %s %s)' % (a, o, b)
        if o == '/': return '_div(%s, %s)' % (a, b)
        if o == '%': return '_mod(%s, %s)' % (a, b)
        if o == '^': return '_pow(%s, %s)' % (a, b)
        if o == '|': return 'float(int(%s) | int(%s))' % (a, b)
        if o == '&': return 'float(int(%s) & int(%s))' % (a, b)
        raise ValueError(o)

RUNTIME = r'''
import math, random
_RNG = random.Random(12345)
MEMN = %(memn)d
GMEMN = %(gmemn)d
M = [0.0] * MEMN
GM = [0.0] * GMEMN
_clock = [0.0]
def _tr(x): return x > 0.00001 or x < -0.00001
def _ix(x):
    return int(math.floor(x + 0.00001))
def _mget(x):
    i = int(math.floor(x + 0.00001))
    return M[i] if 0 <= i < MEMN else 0.0
def _mset(i, v):
    if 0 <= i < MEMN: M[i] = v
def _gget(x):
    i = int(math.floor(x + 0.00001))
    return GM[i] if 0 <= i < GMEMN else 0.0
def _gset(i, v):
    if 0 <= i < GMEMN: GM[i] = v
def _div(a, b):
    try: return a / b
    except ZeroDivisionError: return 0.0 if a == 0 else (math.copysign(1e300, a))
def _mod(a, b):
    bi = int(abs(b))
    return float(int(abs(a)) %% bi) if bi else 0.0
def _pow(a, b):
    try:
        r = a ** b
        return r.real if isinstance(r, complex) else float(r)
    except (OverflowError, ZeroDivisionError): return 0.0
def _floor(x): return float(math.floor(x))
def _ceil(x): return float(math.ceil(x))
def _round(x): return float(math.floor(x + 0.5))
def _exp(x):
    try: return math.exp(x)
    except OverflowError: return 1e300
def _log(x): return math.log(x) if x > 0 else -1e300
def _log10(x): return math.log10(x) if x > 0 else -1e300
def _sqrt(x): return math.sqrt(abs(x))
def _sign(x): return 1.0 if x > 0 else (-1.0 if x < 0 else 0.0)
def _rand(x=1.0): return _RNG.random() * x
def _time(): return _clock[0]
def _zero(*a): return 0.0
def _memset(d, v, n):
    d = int(d); n = int(n)
    if n <= 0: return d
    a = max(0, d); b = min(MEMN, d + n)
    if b > a: M[a:b] = [v] * (b - a)
    return d
def _memcpy(d, s_, n):
    d = int(d); s_ = int(s_); n = int(n)
    if n <= 0: return d
    M[d:d+n] = M[s_:s_+n]
    return d
'''

def translate(path, sections_wanted=('init', 'slider', 'block', 'sample'), patches=(), memn=14000000, gmemn=8200000):
    src = open(path, encoding='utf-8').read()
    for a, b in patches:
        assert src.count(a) == 1, a
        src = src.replace(a, b)
    lines = src.split('\n')
    aliases = {}
    secs = {}
    cur = None
    for ln in lines:
        m = re.match(r'^slider(\d+):([A-Za-z_][A-Za-z_0-9]*)=', ln)
        if m and cur is None:
            aliases['slider' + m.group(1)] = m.group(2)
            continue
        m = re.match(r'^@(\w+)', ln)
        if m:
            cur = m.group(1); secs[cur] = []
            continue
        if cur: secs[cur].append(ln)
    g = Gen(aliases)
    allfuncs = []
    asts = {}
    for name in ('init', 'slider', 'block', 'sample', 'gfx'):
        if name not in secs: continue
        f, a = parse_section('\n'.join(secs[name]), name)
        allfuncs += f
        asts[name] = a
    g.userfuncs = set(f[0] for f in allfuncs)
    out = [RUNTIME % {'memn': memn, 'gmemn': gmemn}]
    bodies = []
    for fname, params, locs, body in allfuncs:
        g.locals = set(params) | set(locs)
        g.globals_used = set()
        blk = []
        r = g.ex(body, blk, '  ')
        hdr = 'def f_%s(%s):' % (fname, ', '.join('L_' + p for p in params))
        gl = sorted(g.globals_used)
        code = [hdr]
        if gl: code.append('  global ' + ', '.join('v_' + x for x in gl))
        for l in locs:
            if l not in params: code.append('  L_%s = 0.0' % l)
        code += blk + ['  return %s' % r]
        bodies.append(('f', code, gl))
    for name in sections_wanted:
        if name not in asts: continue
        g.locals = set(); g.globals_used = set()
        blk = []
        g.ex(asts[name], blk, '  ')
        gl = sorted(g.globals_used)
        code = ['def sec_%s():' % name]
        if gl: code.append('  global ' + ', '.join('v_' + x for x in gl))
        code += blk + ['  return 0']
        bodies.append(('s', code, gl))
    allg = set()
    for _, _, gl in bodies: allg |= set(gl)
    out.append('\n'.join('v_%s = 0.0' % x for x in sorted(allg)))
    for _, code, _ in bodies:
        out.append('\n'.join(code))
    return '\n\n'.join(out) + '\n', aliases

if __name__ == '__main__':
    code, al = translate(sys.argv[1])
    open(sys.argv[2], 'w').write(code)
    print('ok', len(code.split('\n')), 'lines')
