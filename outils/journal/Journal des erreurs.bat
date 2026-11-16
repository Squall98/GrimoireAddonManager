@echo off
rem Double-clic : fabrique et ouvre la page du journal des erreurs de Mes Add-ons (le fichier du jeu n'est pas modifié).
"C:\Program Files\Python314\python.exe" "%~dp0journal.py" %*
if errorlevel 1 pause
