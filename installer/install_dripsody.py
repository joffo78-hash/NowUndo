#!/usr/bin/env python3
"""Installeur Dripsody (Windows / macOS).

Copie les scripts, la page web et les effets au bon endroit dans le dossier de
ressources de REAPER, puis ecrit le demarrage automatique dans Scripts/__startup.lua.
Ne touche a rien d'autre (une copie de __startup.lua est faite avant).

Usage :
  Interface graphique : double-clic sur l'application (Dripsody_Installer).
  Ligne de commande   : python3 install_dripsody.py --cli [--resource CHEMIN] [--auto]
                        --auto = lance tous les scripts par defaut au demarrage.
"""
import argparse, glob, os, platform, re, shutil, sys, webbrowser

APP_SUB = os.path.join("Dripsody", "NowUndo")                  # sous-dossier de REAPER (comme ReaPack)
MARK_A = "-- >>> NOWUNDO (genere par NowUndo_Setup, ne pas modifier a la main) >>>"
MARK_B = "-- <<< NOWUNDO <<<"
SETUP_SCRIPT = os.path.join("Scripts", "V3.21", "NowUndo_Setup.lua")
# scripts lances au demarrage par defaut (meme choix que le Setup de REAPER)
AUTO_DEFAULT = {"virtuallaunchpad_main.lua", "twisterinoutreset.lua", "NowUndo_Twister_Web.lua"}


def base_dir():
    """Dossier qui contient le dossier NowUndo (dev : depot ; app figee : donnees embarquees)."""
    if getattr(sys, "frozen", False):
        return sys._MEIPASS
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def manifest(base=None):
    """Liste (type, source, rel) lue dans le @provides du Setup : une seule source de verite."""
    base = base or base_dir()
    root = os.path.join(base, "NowUndo")
    setup = os.path.join(root, SETUP_SCRIPT)
    items, seen = [], set()
    rx = re.compile(r"^--\s*\[(main|webinterface|effect)\]\s+(\S+)")
    with open(setup, encoding="utf-8") as f:
        for line in f:
            m = rx.match(line.strip())
            if not m:
                continue
            kind, rel_src = m.group(1), m.group(2)
            src = os.path.normpath(os.path.join(root, "Scripts", "V3.21", rel_src))
            if src in seen or not os.path.isfile(src):
                if not os.path.isfile(src):
                    raise FileNotFoundError("fichier introuvable dans le paquet : " + src)
                continue
            seen.add(src)
            items.append((kind, src, os.path.relpath(src, root)))
    return items


def detect_resource():
    """Dossier de ressources de REAPER par defaut selon le systeme."""
    home = os.path.expanduser("~")
    if sys.platform.startswith("win"):
        cands = [os.path.join(os.environ.get("APPDATA", os.path.join(home, "AppData", "Roaming")), "REAPER")]
    elif sys.platform == "darwin":
        cands = [os.path.join(home, "Library", "Application Support", "REAPER")]
    else:
        cands = [os.path.join(home, ".config", "REAPER")]
    for c in cands:
        if os.path.isfile(os.path.join(c, "reaper.ini")):
            return c
    return cands[0]


def is_resource(path):
    return bool(path) and os.path.isfile(os.path.join(path, "reaper.ini"))


REATEAM_URL = "https://raw.githubusercontent.com/ReaTeam/Extensions/master/index.xml"
REAPACK_URL = "https://reapack.com/"
EXT_WANTED = {"js_ReaScriptAPI.ext": ("js_ReaScriptAPI", "reaper_js_ReaScriptAPI"),
              "reaper_imgui.ext": ("ReaImGui", "reaper_imgui"),
              "reaper-oss_SWS.ext": ("SWS", "reaper_sws")}


def extensions_missing(res):
    """Extensions a installer : (nom affiche, prefixe du fichier dans UserPlugins, id ReaPack)."""
    plug = os.path.join(res, "UserPlugins")
    out = []
    for rid, (name, pre) in EXT_WANTED.items():
        if not glob.glob(os.path.join(plug, pre + "*")):
            out.append((name, pre, rid))
    return out


def missing_deps(res):
    return [n for n, _, _ in extensions_missing(res)]


def platform_key():
    """Cle de plateforme de l'index ReaPack : win64, darwin64 (Intel), darwin-arm64 (Apple Silicon)."""
    if sys.platform.startswith("win"):
        return "win64" if platform.machine().lower() in ("amd64", "x86_64") else "win32"
    if sys.platform == "darwin":
        return "darwin-arm64" if platform.machine().lower() == "arm64" else "darwin64"
    return None


def fetch(url, timeout=60):
    import urllib.request
    req = urllib.request.Request(url, headers={"User-Agent": "Dripsody-Installer"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def plan_downloads(res, log=print):
    """Pour chaque extension manquante : (nom, url, chemin de destination), d'apres l'index officiel ReaTeam."""
    import xml.etree.ElementTree as ET
    miss = extensions_missing(res)
    if not miss:
        return []
    key = platform_key()
    if key is None:
        raise RuntimeError("systeme non pris en charge pour le telechargement automatique")
    root = ET.fromstring(fetch(REATEAM_URL))
    plan = []
    for name, pre, rid in miss:
        rp = next((x for x in root.iter("reapack") if x.get("name") == rid), None)
        if rp is None:
            raise RuntimeError("extension absente de l'index : " + rid)
        version = list(rp.iter("version"))[-1]
        srcs = [x for x in version.iter("source") if x.get("platform") == key and not x.get("type")]
        if not srcs:
            raise RuntimeError("pas de version pour ce systeme : " + name)
        src = srcs[0]
        url = (src.text or "").strip()
        plan.append((name, url, os.path.join(res, "UserPlugins", src.get("file"))))
        # l'API Lua de ReaImGui (utilisee par les interfaces) : a cote des scripts REAPER
        if rid == "reaper_imgui.ext":
            api = next((x for x in version.iter("source") if x.get("file") == "imgui.lua" and not x.get("platform")), None)
            if api is not None:
                plan.append((name + " (API Lua)", (api.text or "").strip(),
                             os.path.join(res, "Scripts", "ReaTeam Extensions", "API", "imgui.lua")))
    return plan


def check_file(data, dest):
    """Refuse un fichier qui n'est pas une bibliotheque (page d'erreur, coupure...)."""
    head = data[:4]
    if dest.endswith(".dll"):
        ok = head[:2] == b"MZ"
    elif dest.endswith(".dylib"):
        ok = head in (b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xfe\xed\xfa\xcf", b"\xfe\xed\xfa\xce", b"\xce\xfa\xed\xfe")
    else:
        ok = len(data) > 1000
    if not ok:
        raise RuntimeError("fichier telecharge invalide : " + os.path.basename(dest))


def download_extensions(res, log=print):
    """Telecharge et copie les extensions manquantes. Renvoie la liste des noms installes."""
    plan = plan_downloads(res, log)
    done = []
    for name, url, dest in plan:
        log("Telechargement : " + name + " ...")
        data = fetch(url)
        check_file(data, dest)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        tmp = dest + ".part"
        with open(tmp, "wb") as f:
            f.write(data)
        os.replace(tmp, dest)
        log("  -> " + os.path.relpath(dest, res))
        done.append(name)
    return done


def dep_steps(miss):
    """Ce qu'il reste a faire si le telechargement n'a pas abouti."""
    if not miss:
        return []
    return ["Il reste a installer dans REAPER (Extensions > ReaPack > Browse packages) : " + ", ".join(miss) + ".",
            "Si ReaPack n'est pas installe : " + REAPACK_URL,
            "Puis redemarre REAPER."]


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_startup(res, scripts_dir, files, log):
    """Ecrit le bloc Dripsody dans __startup.lua (le reste du fichier est conserve)."""
    path = os.path.join(res, "Scripts", "__startup.lua")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    old = ""
    if os.path.isfile(path):
        with open(path, encoding="utf-8", errors="replace") as f:
            old = f.read()
        shutil.copyfile(path, path + ".dripsody.bak")       # sauvegarde avant modification
        log("Sauvegarde de __startup.lua : __startup.lua.dripsody.bak")
    a = old.find(MARK_A)
    if a >= 0:
        b = old.find(MARK_B, a)
        old = old[:a] + old[(b + len(MARK_B) if b >= 0 else len(old)):]
    old = old.rstrip()
    if files:
        q = ", ".join(lua_str(x) for x in files)
        block = "\n".join([
            MARK_A, "do",
            "  local dir = " + lua_str(scripts_dir.replace("\\", "/") + "/"),
            "  local files = { " + q + " }",
            "  local t0, done = reaper.time_precise(), false",
            "  local function boot()",
            "    if done then return end",
            "    if reaper.time_precise() - t0 < 1.5 then reaper.defer(boot); return end",
            "    done = true",
            "    for _, fn in ipairs(files) do",
            "      local id = reaper.AddRemoveReaScript(true, 0, dir .. fn, true)",
            "      if id and id ~= 0 then reaper.Main_OnCommand(id, 0) end",
            "    end",
            "  end",
            "  boot()",
            "end",
            MARK_B])
        new = (old + "\n\n" if old else "") + block + "\n"
    else:
        new = old + ("\n" if old else "")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new)
    log("Demarrage automatique ecrit : %d script(s)." % len(files))


def install(res, auto_files, log=print, extensions=True):
    """Installe tout. auto_files = noms de scripts lances au demarrage. Renvoie le nombre de fichiers copies."""
    if not is_resource(res):
        raise SystemExit("Dossier REAPER introuvable (pas de reaper.ini) : " + res)
    if extensions and extensions_missing(res):
        try:
            download_extensions(res, log)
        except Exception as e:                                 # pas de reseau : on guide au lieu de bloquer
            log("Telechargement des extensions impossible : " + str(e))
    base = base_dir()
    root = os.path.join(base, "NowUndo")
    scripts_dir = os.path.join(res, "Scripts", APP_SUB, "Scripts", "V3.21")
    n = 0
    for kind, src, rel in manifest(base):
        if kind == "main":
            dst = os.path.join(res, "Scripts", APP_SUB, rel)
        elif kind == "effect":
            dst = os.path.join(res, "Effects", APP_SUB, rel)
        else:                                                  # page web : reaper_www_root
            dst = os.path.join(res, "reaper_www_root", os.path.basename(src))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(src, dst)
        n += 1
    log("%d fichier(s) copies (scripts, page web, effets)." % n)
    write_startup(res, scripts_dir, sorted(auto_files), log)
    miss = missing_deps(res)
    if miss:
        for line in dep_steps(miss):
            log(line)
    else:
        log("Extensions SWS, js_ReaScriptAPI et ReaImGui : presentes.")
    log("Termine. Redemarre REAPER pour charger Dripsody.")
    return n


def run_cli(args):
    res = args.resource or detect_resource()
    print("Dossier REAPER :", res)
    if not is_resource(res):
        print("Introuvable. Relance avec --resource CHEMIN (le dossier qui contient reaper.ini).")
        return 1
    install(res, sorted(AUTO_DEFAULT))   # --auto : meme choix par defaut (demarrage automatique)
    return 0


def run_gui():
    import tkinter as tk
    from tkinter import filedialog, messagebox
    root = tk.Tk()
    root.title("Installer Dripsody")
    root.geometry("640x520")
    res_var = tk.StringVar(value=detect_resource())
    frm = tk.Frame(root, padx=14, pady=12); frm.pack(fill="both", expand=True)
    tk.Label(frm, text="Dossier de ressources REAPER", font=("Arial", 12, "bold")).pack(anchor="w")
    row = tk.Frame(frm); row.pack(fill="x", pady=4)
    tk.Entry(row, textvariable=res_var).pack(side="left", fill="x", expand=True)
    def browse():
        d = filedialog.askdirectory(initialdir=res_var.get())
        if d: res_var.set(d)
    tk.Button(row, text="Parcourir...", command=browse).pack(side="left", padx=6)
    tk.Label(frm, text="Scripts lances au demarrage de REAPER :", font=("Arial", 11, "bold")).pack(anchor="w", pady=(10, 2))
    checks = {}
    for name, label in [("virtuallaunchpad_main.lua", "Launchpad (virtuel + Mini MK3)"),
                        ("twisterinoutreset.lua", "Twister (Midi Fighter Twister)"),
                        ("NowUndo_Twister_Web.lua", "Pont de la page web"),
                        ("nowundo_midi_learn.lua", "MIDI Learn + raccourcis"),
                        ("NowUndo_8Waves.lua", "8 Waves (formes d'onde)"),
                        ("NowUndo_Scenario.lua", "Rushes / Scenario"),
                        ("FX_Router_v2.lua", "FX Router"),
                        ("NowUndo_VirtualPedalBoard.lua", "Pedalier virtuel"),
                        ("NowUndo_Performance.lua", "Performance (enregistrement du concert)")]:
        v = tk.BooleanVar(value=name in AUTO_DEFAULT)
        tk.Checkbutton(frm, text=label, variable=v).pack(anchor="w")
        checks[name] = v
    log_box = tk.Text(frm, height=12, wrap="word"); log_box.pack(fill="both", expand=True, pady=(10, 6))
    def log(msg):
        log_box.insert("end", msg + "\n"); log_box.see("end"); root.update()
    def go():
        log_box.delete("1.0", "end")
        r = res_var.get().strip()
        if not is_resource(r):
            messagebox.showerror("Dripsody", "Ce dossier ne contient pas reaper.ini.\nChoisis le dossier REAPER (Parcourir).")
            return
        try:
            install(r, [k for k, v in checks.items() if v.get()], log)
        except Exception as e:
            log("ERREUR : " + str(e))
            messagebox.showerror("Dripsody", "Installation interrompue :\n" + str(e))
    tk.Button(frm, text="INSTALLER", font=("Arial", 12, "bold"), height=2, command=go).pack(fill="x")
    def copy_url():
        root.clipboard_clear(); root.clipboard_append(REATEAM_URL)
        log_box.insert("end", "Adresse copiee : colle-la dans ReaPack (Import repositories).\n")
    def check():
        miss = missing_deps(res_var.get().strip())
        log_box.insert("end", ("Extensions : toutes presentes, rien a faire de plus.\n" if not miss else
                               "Encore manquant : " + ", ".join(miss) + "\n"))
        log_box.see("end")
    bar = tk.Frame(frm); bar.pack(fill="x")
    tk.Button(bar, text="Ouvrir ReaPack (site)", command=lambda: webbrowser.open(REAPACK_URL)).pack(side="left")
    tk.Button(bar, text="Copier l'adresse du depot", command=copy_url).pack(side="left", padx=6)
    tk.Button(bar, text="Verifier les extensions", command=check).pack(side="left")
    def get_ext():
        r = res_var.get().strip()
        if not is_resource(r):
            messagebox.showerror("Dripsody", "Choisis d'abord le dossier REAPER.")
            return
        log_box.delete("1.0", "end")
        try:
            done = download_extensions(r, log)
            log("Extensions installees : " + (", ".join(done) if done else "aucune a installer") + ". Redemarre REAPER.")
        except Exception as e:
            log("Telechargement impossible : " + str(e))
            for line in dep_steps(missing_deps(r)):
                log(line)
    tk.Button(bar, text="Installer les extensions", command=get_ext).pack(side="left", padx=6)
    root.mainloop()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--cli", action="store_true", help="sans fenetre")
    p.add_argument("--resource", help="dossier de ressources REAPER")
    p.add_argument("--auto", action="store_true", help="scripts de demarrage par defaut")
    args = p.parse_args()
    if args.cli or args.resource:
        sys.exit(run_cli(args))
    try:
        run_gui()
    except Exception:                                          # pas d'ecran : repli en ligne de commande
        sys.exit(run_cli(args))


if __name__ == "__main__":
    main()
