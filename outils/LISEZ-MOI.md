Les outils du projet « Mes Add-ons » : vérifier, générer les données, installer dans le jeu, versionner, et le banc d'essai hors jeu.

# outils

Python : `"C:\Program Files\Python314\python.exe" -X utf8 outils\<outil>.py` (depuis la racine du projet). Les chemins viennent de `config.json`.

| Outil | Rôle |
|---|---|
| `verifier.py` | **la preuve** : syntaxe Lua (luac 5.1), .toc, données JSON et Lua générés à jour, textes FR/EN identiques, clés de texte du code, chasse au « en dur », puis tous les tests du banc. Code 0 = tout est bon. `--sans-tests` pour aller vite |
| `generer_donnees.py` | JSON de `donnees/` → `addon/GrimoireAddonManager/Donnees/*.lua` (`--verifier` : dit si c'est périmé). À relancer après toute modification d'un JSON |
| `installer.py` | copie `addon/GrimoireAddonManager` dans `_forever_\Interface\AddOns` (vérifie d'abord, SHA256 fichier par fichier, ancienne version déplacée dans `_archives\installations`, aucun autre add-on touché). `--simuler`, `--vers DOSSIER` |
| `versionner.py` | git **local** (aucun envoi) : `versionner.py "message"` vérifie puis enregistre une version et l'étiquette `vX.Y.Z` ; `--etat`, `--historique` |
| `banc/` | le banc d'essai : Lua 5.1 portable + imitation de l'API de WoW (voir `banc\LISEZ-MOI.md`) |
| `commun.py` | chemins, SHA256 et écriture Lua partagés |

Version : le numéro est dans `addon/GrimoireAddonManager/GrimoireAddonManager.toc` (`## Version`). Changer ce numéro avant `versionner.py` pour une nouvelle version.
