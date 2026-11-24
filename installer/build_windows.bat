@echo off
rem Construit Dripsody_Installer.exe sur un PC Windows (Python 3 installe, cocher "Add to PATH").
cd /d "%~dp0"
pip install pyinstaller || goto :eof
pyinstaller --noconfirm --onefile --windowed --name Dripsody_Installer --add-data "..\NowUndo;NowUndo" install_dripsody.py
echo Executable : dist\Dripsody_Installer.exe
pause
