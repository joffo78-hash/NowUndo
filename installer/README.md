# Installeur Dripsody

Copie tout au bon endroit dans le dossier de REAPER et écrit le démarrage automatique.

- **Windows** : `build_windows.bat` produit `dist\Dripsody_Installer.exe`.
- **Mac** : `build_mac.sh` produit `dist/Dripsody_Installer.app`.

Chaque exécutable se construit sur son propre système (PyInstaller ne sait pas faire de compilation croisée).
Sans compilation : `python3 install_dripsody.py` (ou `--cli --auto --resource CHEMIN`).

Ce que fait l'installeur :
1. Trouve le dossier REAPER (`%APPDATA%\REAPER` ou `~/Library/Application Support/REAPER`), ou le demande.
2. Copie les scripts dans `Scripts/Dripsody/NowUndo/`, les effets dans `Effects/Dripsody/NowUndo/`, la page web dans `reaper_www_root/`.
3. Sauvegarde puis met à jour le bloc `NOWUNDO` de `Scripts/__startup.lua` (le reste du fichier est conservé).
4. Dit quelles extensions manquent (SWS, js_ReaScriptAPI, ReaImGui) : elles ne sont pas installées automatiquement.

La liste des fichiers vient du `@provides` de `Scripts/V3.21/NowUndo_Setup.lua` (une seule source).
