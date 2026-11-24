#!/bin/sh
# Construit Dripsody_Installer.app sur un Mac (Python 3 + pip install pyinstaller).
# Le dossier NowUndo (scripts, effets, page web) est embarque dans l'application.
cd "$(dirname "$0")"
pip3 install pyinstaller >/dev/null
pyinstaller --noconfirm --windowed --name Dripsody_Installer \
  --add-data "../NowUndo:NowUndo" install_dripsody.py
echo "Application : dist/Dripsody_Installer.app"
