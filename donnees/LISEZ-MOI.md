Les données de départ de « Mes Add-ons » (réglages, textes français et anglais, fiches) : la source de tout ce que l'add-on affiche ou règle.

# donnees

| Fichier ou dossier | Contenu |
|---|---|
| `reglages.json` | valeurs de départ des réglages (`defauts`), liste des sous-commandes, langues disponibles, noms techniques (variables sauvegardées, clé de commande) |
| `textes/frFR.json`, `textes/enUS.json` | tous les textes affichés, mêmes clés dans les deux langues (contrôlé par `outils/verifier.py`) |
| `options.json` | le schéma de la page d'options : groupes, réglages (type, choix, bornes, suite à appliquer) ; le panneau est généré d'après lui, et `outils/verifier.py` exige que chaque réglage y soit (ou soit exclu avec sa raison) |
| `fiches/` | les 102 fiches, catégories, doublons et profils de départ (voir son `LISEZ-MOI.md`) ; `fiches/origine/` = copie des 33 fiches de départ de `Claude\Fiches-addons` (Fiches.lua, Textes.lua), gardée telle quelle |

Après toute modification : `python -X utf8 outils\generer_donnees.py` (régénère `addon/GrimoireAddonManager/Donnees/*.lua`), puis `outils\verifier.py`.
Rien de propre à Nykaro ici (partage possible, S2.9) : ses notes, profils et réglages restent dans ses sauvegardes du jeu.
