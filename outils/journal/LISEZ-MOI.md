Outil Windows qui transforme le journal des erreurs de Mes Add-ons en page HTML lisible (étape B4-02).

- **Double-clic** sur `Journal des erreurs.bat` : cherche `WTF\Account\*\SavedVariables\GrimoireAddonManager.lua`, fabrique
  `pages\journal-erreurs-<compte>.html` et l'ouvre.
- Le fichier du jeu est lu **sans être modifié** : son empreinte SHA256 est comparée avant et après (rien n'est
  fabriqué s'il a changé pendant la lecture). Le journal n'est écrit par le jeu qu'au `/reload` ou à la déconnexion.
- Options : `--source <fichier>`, `--sortie <dossier>`, `--exemple` (page de démo sans le jeu), `--ne-pas-ouvrir`.
- Rien en dur : chemins et noms dans `reglages.json`, textes de la page dans `textes.json`, mise en page dans `modele.html`.
- Format lu : `MesAddonsDB.erreurs_journal.liste` (voir le bilan de B4-01).
- Test : `python test_journal.py` (lecteur Lua, empreinte inchangée, page fabriquée).
