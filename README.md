<p align="center"><img src="media/logo.png" width="128" alt="Grimoire Addon Manager"></p>

<h1 align="center">Grimoire Addon Manager (GAM)</h1>

<p align="center">An add-on manager for <b>WoW Forever</b> · Un gestionnaire d'add-ons pour <b>WoW Forever</b></p>

<p align="center"><a href="#-english">English</a> · <a href="#-français">Français</a> · <a href="https://www.curseforge.com/wow/addons/grimoire-addon-manager">CurseForge</a> · MIT</p>

<!-- CAPTURES -->

# 🌐 English
**Grimoire Addon Manager (GAM)** puts all your add-ons in one grimoire-style window, in your faction's colours. Turn them on and off in a click, switch whole sets with profiles, and never forget again what an add-on is for: every add-on has its own little sheet.

Type **/gam** or click the minimap button to open it.

## 🌟 At a glance

- 📖 **One window for everything**: categories on the left, your add-ons in the middle, the sheet on the right.
- ✅ **On / off in one click**, by category, or everything at once. **Reload** applies, **Undo** goes back.
- 📜 **A sheet for every add-on** (102 included): what it does, its commands, what to know, and your own note.
- 🎒 **Profiles**: Leveling, Dungeon, Fishing, Minimal… or your own, from the window, a macro or the minimap.
- 🐞 **Lua errors** caught with all their details, plus memory and CPU per add-on.
- 🌍 **English and French**, Horde or Alliance theme picked automatically.

## ✨ Features

### 📖 The grimoire window
- "All add-ons" grouped by category (folding sections), or as a single list.
- Fold the left column (categories) or the right one (sheet) with the arrows.
- Mini version (list only), resizable window, text size, Horde / Alliance / neutral theme.

### 🔎 Find and sort
- Search that forgives typos, in names, sheets, notes, commands and tags.
- Filters: enabled, disabled, out of date, duplicates, no sheet, favourites, new…
- Sort by name, category, state, memory or usefulness. Favourite star and personal tags.
- Badges: new, updated, error, duplicate, out of date, trial, locked.

### 📜 Sheets and tooltips
- Hover an add-on: a short summary in the tooltip.
- Click it: the full sheet on parchment, its commands, its dependencies, and **your own note**.
- Edit any sheet, links to its settings and to CurseForge.

### 🎒 Profiles
- Ready-made profiles plus your own; "All" and "Nothing" always there.
- See what changes before applying (+x / −y), dependencies turned on with them.
- Lock an add-on so no profile ever turns it off.
- Copy a profile as text to share it, compare two profiles.
- Suggests the right profile when you enter a dungeon, a raid or a battleground.

### ⚡ Quick actions
- Shift + click: turn an add-on on with its modules and dependencies.
- Trial mode (on for one session only) and safe mode (everything off except what you name, then back).
- Right-click menu, keybindings, the game's Esc menu "Add-ons" button opens GAM.

### 🐞 Errors and performance
- Every Lua error kept with its full stack, grouped and counted; copy it in one click.
- Memory per add-on, CPU measuring mode, a warning if memory gets too high.

### 🧭 Help built in
- A cheat sheet of **every command** (GAM's and your add-ons'), searchable, a click types it in the chat.
- A 5-bubble guided tour of the window.

### ⚙️ Options
- Almost everything can be changed, in 5 tabs. Everyday settings first; tick **"Show advanced settings"** for the fine-tuning.

## 📥 Install

- **CurseForge** (easiest): search for *Grimoire Addon Manager*.
- **By hand**: download the latest zip from the Releases or CurseForge, and copy the `GrimoireAddonManager` folder into `World of Warcraft\_forever_\Interface\AddOns\`.

## 🛠️ For developers

- `addon/GrimoireAddonManager/`: the add-on (Lua). `Donnees/*.lua` are **generated** from `donnees/` (JSON).
- `python -X utf8 outils/generer_donnees.py` then `python outils/verifier.py` (checks + an out-of-game test bench in Lua 5.1).

## 🎮 Supported game versions

| Game | Supported |
|---|---|
| WoW Forever (1.60.1) | ✅ |

## ⌨️ Slash commands

`/gam`, `/maa` and `/mesaddons` all work (you can change them in the options).

| Command | What it does |
|---|---|
| `/gam` | Open or close the window |
| `/gam help` | Show every command |
| `/gam cheatsheet` | Every command, searchable and clickable |
| `/gam profile <name>` | Apply a profile |
| `/gam reload` | Apply the pending changes |
| `/gam undo` | Undo the last change |
| `/gam errors` | Open the Lua error window |
| `/gam safe` then `/gam back` | Safe mode, then put everything back |
| `/gam tour` | Start the guided tour |
| `/gam options` | Open the options |

## 💡 Good to know

- Ticking or unticking does nothing until you click **Reload** (the game only loads add-ons at that moment). The button lights up when something is waiting.
- GAM never turns itself off, and only touches the add-ons you ask it to.
- Your settings, profiles and notes are kept by the game: updating GAM doesn't erase them.

## 🌍 Languages

English and French, picked from your game language (or chosen in the options). Every text lives in a data file, so more languages can be added easily.

## ❓ FAQ

- **I ticked an add-on and nothing happened.** Click **Reload** at the bottom of the window: the game only loads add-ons when the interface reloads.
- **An add-on says "out of date".** It was made for another game version. You can still load it with `/gam outdated on`, at your own risk.
- **My add-on has no sheet.** It shows its own description instead; you can write the sheet yourself with **Edit sheet**.

## 💬 Support

Found a bug or have an idea? Open an issue on GitHub or leave a comment on CurseForge. Please say which game version you play and, for an error, use the **Copy** button of the error window.

Source code and bug reports: https://github.com/Squall98/GrimoireAddonManager

## 📄 Licence

MIT. Made by Nykaro, written with the help of Claude (Anthropic). Inspired by the way other managers work (SAM, ACP), without reusing their code.

---

# 🌐 Français
**Grimoire Addon Manager (GAM)** range tous tes add-ons dans une seule fenêtre façon grimoire, aux couleurs de ta faction. Tu les allumes ou les éteins d'un clic, tu changes tout un jeu d'add-ons avec les profils, et tu n'oublies plus à quoi sert un add-on : chacun a sa petite fiche.

Tape **/gam** ou clique le bouton de la minicarte pour l'ouvrir.

## 🌟 En un coup d'œil

- 📖 **Une seule fenêtre** : les catégories à gauche, tes add-ons au milieu, la fiche à droite.
- ✅ **Allumer / éteindre d'un clic**, par catégorie, ou tout d'un coup. **Recharger** applique, **Annuler** revient en arrière.
- 📜 **Une fiche par add-on** (102 fournies) : à quoi il sert, ses commandes, ce qu'il faut savoir, et ta note perso.
- 🎒 **Profils** : Leveling, Donjon, Pêche, Minimal… ou les tiens, depuis la fenêtre, une macro ou la minicarte.
- 🐞 **Erreurs Lua** gardées avec tout leur détail, et mémoire / processeur par add-on.
- 🌍 **Français et anglais**, thème Horde ou Alliance choisi tout seul.

## ✨ Ce qu'il sait faire

### 📖 La fenêtre grimoire
- « Tous les add-ons » rangé par catégories (sections repliables), ou en une seule liste.
- Replie la colonne de gauche (catégories) ou de droite (fiche) avec les flèches.
- Version mini (la liste seule), fenêtre redimensionnable, taille du texte, thème Horde / Alliance / neutre.

### 🔎 Trouver et trier
- Recherche qui pardonne les fautes, dans les noms, fiches, notes, commandes et étiquettes.
- Filtres : activés, désactivés, périmés, doublons, sans fiche, favoris, nouveaux…
- Tri par nom, catégorie, état, mémoire ou utilité. Étoile des favoris et étiquettes perso.
- Badges : nouveau, mis à jour, erreur, doublon, périmé, en essai, verrouillé.

### 📜 Fiches et infobulles
- Survole un add-on : un résumé dans l'infobulle.
- Clique-le : la fiche complète sur parchemin, ses commandes, ses dépendances, et **ta note perso**.
- Chaque fiche se modifie ; liens vers ses réglages et vers CurseForge.

### 🎒 Profils
- Des profils prêts et les tiens ; « Tout » et « Rien » toujours là.
- Tu vois ce qui change avant d'appliquer (+x / −y) ; les dépendances suivent.
- Verrouille un add-on : aucun profil ne l'éteindra.
- Copie un profil en texte pour le partager, compare deux profils.
- Propose le bon profil quand tu entres en donjon, en raid ou en champ de bataille.

### ⚡ Actions rapides
- Maj + clic : allume un add-on avec ses modules et ses dépendances.
- Mode essai (allumé pour une session) et mode dépannage (tout éteint sauf ce que tu cites, puis retour).
- Menu clic droit, raccourcis clavier, et le bouton « Add-ons » du menu Échap ouvre GAM.

### 🐞 Erreurs et performances
- Chaque erreur Lua gardée avec sa pile complète, regroupée et comptée ; copiable d'un clic.
- Mémoire par add-on, mode mesure du processeur, alerte si la mémoire grimpe trop.

### 🧭 L'aide intégrée
- Une antisèche de **toutes les commandes** (celles de GAM et de tes add-ons), avec recherche ; un clic l'écrit dans le chat.
- Une visite guidée de la fenêtre en 5 bulles.

### ⚙️ Options
- Presque tout se règle, en 5 onglets. L'essentiel d'abord ; coche **« Montrer les réglages avancés »** pour les réglages fins.

## 📥 Installer

- **CurseForge** (le plus simple) : cherche *Grimoire Addon Manager*.
- **À la main** : télécharge le dernier zip (Releases ou CurseForge) et copie le dossier `GrimoireAddonManager` dans `World of Warcraft\_forever_\Interface\AddOns\`.

## 🛠️ Pour les développeurs

- `addon/GrimoireAddonManager/` : l'add-on (Lua). Les `Donnees/*.lua` sont **générés** depuis `donnees/` (JSON).
- `python -X utf8 outils/generer_donnees.py` puis `python outils/verifier.py` (vérifications + banc d'essai hors jeu en Lua 5.1).

## 🎮 Versions du jeu

| Jeu | Pris en charge |
|---|---|
| WoW Forever (1.60.1) | ✅ |

## ⌨️ Commandes

`/gam`, `/maa` et `/mesaddons` marchent pareil (modifiables dans les options).

| Commande | Ce qu'elle fait |
|---|---|
| `/gam` | Ouvre ou ferme la fenêtre |
| `/gam aide` | Toutes les commandes |
| `/gam antiseche` | Toutes les commandes, avec recherche, cliquables |
| `/gam profil <nom>` | Applique un profil |
| `/gam recharger` | Applique les changements en attente |
| `/gam annuler` | Annule le dernier changement |
| `/gam erreurs` | La fenêtre des erreurs Lua |
| `/gam depannage` puis `/gam retour` | Mode dépannage, puis tout remettre |
| `/gam visite` | La visite guidée |
| `/gam options` | Les options |

## 💡 Bon à savoir

- Cocher ou décocher ne change rien tant que tu n'as pas cliqué **Recharger** (le jeu ne charge les add-ons qu'à ce moment-là). Le bouton s'allume quand quelque chose attend.
- GAM ne s'éteint jamais lui-même et ne touche qu'aux add-ons que tu lui demandes.
- Tes réglages, profils et notes sont gardés par le jeu : mettre GAM à jour ne les efface pas.

## 🌍 Langues

Français et anglais, selon la langue du jeu (ou au choix dans les options). Tous les textes sont dans un fichier de données : d'autres langues s'ajoutent facilement.

## ❓ Questions fréquentes

- **J'ai coché un add-on et rien ne change.** Clique **Recharger** en bas de la fenêtre : le jeu ne charge les add-ons qu'au rechargement de l'interface.
- **Un add-on est marqué « périmé ».** Il a été fait pour une autre version du jeu. Tu peux quand même le charger avec `/gam perimes on`, à tes risques.
- **Mon add-on n'a pas de fiche.** Sa propre description s'affiche à la place ; tu peux écrire la fiche toi-même avec **Modifier la fiche**.

## 💬 Aide

Un bug ou une idée ? Ouvre une issue sur GitHub ou laisse un commentaire sur CurseForge, en disant ta version du jeu ; pour une erreur, utilise le bouton **Copier** de la fenêtre des erreurs.

Code source et signalement des bugs : https://github.com/Squall98/GrimoireAddonManager

## 📄 Licence

MIT. Fait par Nykaro, écrit avec l'aide de Claude (Anthropic). Inspiré de la façon de faire d'autres gestionnaires (SAM, ACP), sans reprendre leur code.
