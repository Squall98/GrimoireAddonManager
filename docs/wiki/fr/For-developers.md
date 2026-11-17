> 🌐 [🇬🇧 Read in English](../en/For-developers.md) · [🏠 Accueil](../Home.md)

# 🛠️ Pour les développeurs

Tout ce que GAM affiche ou règle au départ vit dans des **fichiers JSON**, jamais dans le code. Tu changes le JSON, un outil refait le Lua, un autre l'installe.

## 🗂️ Structure du dépôt
| Chemin | Contenu |
|---|---|
| `addon/GrimoireAddonManager/` | L'add-on (Lua + `.toc` + `Bindings.xml`). Sous-dossiers : `Core`, `Fenetre`, `Liste`, `Fiche`, `Profils`, `Actions`, `Erreurs`, `Aide`, `Options`, `Diag`. |
| `addon/GrimoireAddonManager/Donnees/*.lua` | **Générés** depuis `donnees/`. Ne jamais modifier à la main. |
| `donnees/reglages.json` | Valeurs de départ (`defauts`), liste des sous-commandes, noms techniques. |
| `donnees/options.json` | Le panneau d'options : onglets, groupes, éléments (`avance: true` = avancé). |
| `donnees/textes/enUS.json`, `frFR.json` | Tous les textes affichés. Mêmes clés dans les deux fichiers. |
| `donnees/fiches/` | `fiches.json`, `categories.json`, `doublons.json`, `profils.json`. |
| `outils/` | Les outils Python. |
| `outils/banc/` | Banc d'essai hors jeu (Lua 5.1 portable + imitation de l'API de WoW). |
| `docs/wiki/` | Ce wiki. `outils/fabriquer_wiki.py` fabrique `Commands.md` et `Options.md`. |
| `media/` | Logo et captures d'écran. |

## 🔁 La boucle
Depuis la racine du projet :
```
python -X utf8 outils/generer_donnees.py     # JSON -> addon/.../Donnees/*.lua
python -X utf8 outils/verifier.py            # syntaxe Lua, textes fr = en, réglages, tous les tests
python -X utf8 outils/installer.py --simuler # montre ce qui serait copié
python -X utf8 outils/installer.py           # installe, range l'ancienne version dans _archives\installations
```
Puis `/reload` en jeu (quitte et relance le jeu si tu as ajouté un fichier Lua, pas seulement des données).
`outils/verifier.py` est la preuve : code de sortie 0 = tout est bon. `--sans-tests` va plus vite.
`outils/versionner.py "message"` fait une version git **locale** (rien n'est envoyé).

## ➕ Ajouter une fiche
Dans `donnees/fiches/fiches.json`, copie un bloc. La clé est le **nom exact du dossier** de l'add-on. Remplis `fr` et `en` (`resume`, `commandes`, `remarques`), `categories` (noms pris dans `categories.json`) et `utilite` (indispensable, confort ou gadget). Un module a `"type": "module"` et `"parent"`. `/gam sansfiche` ou `donnees/fiches/sans-fiche.py` listent ce qui manque.

## ➕ Ajouter une catégorie
Dans `categories.json` : un nom technique (minuscules, tirets), le nom affiché en `fr` et `en`, une `source`. Puis ajoute ce nom dans la liste `categories` des fiches concernées.

## ➕ Ajouter un profil prêt
Dans `profils.json` : `nom` (fr/en), `addons` (dossiers principaux ; les modules suivent si `avec_modules`), `note`, `couleur`. Puis dans `reglages.json` ajoute son id à `profils.ordre_prets` et une icône à `profils.icones_depart`. Les add-ons absents sont ignorés.

## ➕ Ajouter une commande
- Un **nom d'ouverture** de plus : ajoute-le à `defauts.commandes.liste` (lettres et chiffres seulement).
- Une nouvelle **action** (un nouveau mot après /gam) demande du code Lua : la fonction dans le bon `Commande.lua`, son id dans `sous_commandes`, et `sous.<id>.nom` / `sous.<id>.desc` dans les deux fichiers de textes.

## ➕ Ajouter une langue
Copie `textes/enUS.json` en, par exemple, `textes/deDE.json` et traduis les valeurs (garde les `%s` / `%d` dans le même ordre). Déclare la langue dans `reglages.json` (`langue`) et ajoute son code à la liste des langues de `outils/generer_donnees.py`. `outils/verifier.py` contrôle que toutes les langues ont exactement les mêmes clés.

## ⚙️ Ajouter un réglage
1. Sa valeur de départ dans `reglages.json` › `defauts`.
2. Sa place dans `options.json` (groupe, type `bool` / `choix` / `nombre` / `texte`, bornes, `avance`). Chaque réglage doit être dans `options.json` ou dans sa liste `exclus` avec une raison : la vérification l'exige.
3. Son libellé `opt.<chemin>` dans les deux fichiers de textes.
4. Une ligne dans `DESC` de `outils/fabriquer_wiki.py`, puis lance-le pour rafraîchir les [Options](Options.md).

## 📸 Captures
Dans `media/captures/` (`gam-en-*.png`, `gam-fr-*.png`). Les pages les relient par des chemins relatifs comme `../../../media/captures/gam-fr-1-fiche.png`.
