> 🌐 [🇫🇷 Lire en français](../fr/For-developers.md) · [🏠 Home](../Home.md)

# 🛠️ For developers

Everything GAM shows or sets by default lives in **JSON data files**, never in the code. You change the JSON, a tool rebuilds the Lua, another installs it.

## 🗂️ Repository layout
| Path | What is in it |
|---|---|
| `addon/GrimoireAddonManager/` | The add-on (Lua + `.toc` + `Bindings.xml`). Subfolders: `Core`, `Fenetre`, `Liste`, `Fiche`, `Profils`, `Actions`, `Erreurs`, `Aide`, `Options`, `Diag`. |
| `addon/GrimoireAddonManager/Donnees/*.lua` | **Generated** from `donnees/`. Never edit by hand. |
| `donnees/reglages.json` | Default values (`defauts`), the sub-command list, technical names. |
| `donnees/options.json` | The options panel: tabs, groups, items (`avance: true` = advanced). |
| `donnees/textes/enUS.json`, `frFR.json` | Every displayed text. Same keys in both files. |
| `donnees/fiches/` | `fiches.json`, `categories.json`, `doublons.json`, `profils.json`. |
| `outils/` | Python tools. |
| `outils/banc/` | Out-of-game test bench (portable Lua 5.1 + a mock of the WoW API). |
| `docs/wiki/` | This wiki. `outils/fabriquer_wiki.py` builds `Commands.md` and `Options.md`. |
| `media/` | Logo and screenshots. |

## 🔁 The loop
Run from the project root:
```
python -X utf8 outils/generer_donnees.py     # JSON -> addon/.../Donnees/*.lua
python -X utf8 outils/verifier.py            # Lua syntax, texts fr = en, settings, all tests
python -X utf8 outils/installer.py --simuler # shows what would be copied
python -X utf8 outils/installer.py           # installs, keeps the old version in _archives\installations
```
Then `/reload` in game (quit and restart if you added a Lua file, not only data).
`outils/verifier.py` is the proof: exit code 0 means everything is fine. `--sans-tests` goes faster.
`outils/versionner.py "message"` makes a **local** git version (nothing is sent anywhere).

## ➕ Add a sheet
In `donnees/fiches/fiches.json`, copy a block. The key is the **exact folder name** of the add-on. Fill `fr` and `en` (`resume`, `commandes`, `remarques`), `categories` (names from `categories.json`) and `utilite` (indispensable, confort or gadget). A module has `"type": "module"` and `"parent"`. `/gam nosheet` or `donnees/fiches/sans-fiche.py` list what is missing.

## ➕ Add a category
In `categories.json`: a technical name (lowercase, dashes), the display name in `fr` and `en`, a `source`. Then add that name to the `categories` list of the sheets concerned.

## ➕ Add a ready-made profile
In `profils.json`: `nom` (fr/en), `addons` (main folders; modules follow if `avec_modules`), `note`, `couleur`. Then in `reglages.json` add its id to `profils.ordre_prets` and an icon to `profils.icones_depart`. Missing add-ons are ignored.

## ➕ Add a command
- An extra **opening name**: add it to `defauts.commandes.liste` (letters and digits only).
- A new **action** (a new word after /gam) needs Lua code: add the function in the right `Commande.lua`, its id in `sous_commandes`, and its `sous.<id>.nom` / `sous.<id>.desc` in both text files.

## ➕ Add a language
Copy `textes/enUS.json` to e.g. `textes/deDE.json` and translate the values (keep `%s` / `%d` in the same order). Declare the language in `reglages.json` (`langue`), and add its code to the language list in `outils/generer_donnees.py`. `outils/verifier.py` checks that every language has exactly the same keys.

## ⚙️ Add a setting
1. Its default in `reglages.json` › `defauts`.
2. Its place in `options.json` (group, type `bool` / `choix` / `nombre` / `texte`, bounds, `avance`). Every setting must be in `options.json` or in its `exclus` list with a reason: the check enforces it.
3. Its label `opt.<path>` in both text files.
4. A line in `DESC` in `outils/fabriquer_wiki.py`, then run it to refresh [Options](Options.md).

## 📸 Screenshots
In `media/captures/` (`gam-en-*.png`, `gam-fr-*.png`). Pages link them with relative paths like `../../../media/captures/gam-en-1-window.png`.
