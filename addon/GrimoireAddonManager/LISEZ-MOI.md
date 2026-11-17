# Grimoire Addon Manager (GAM)

Gestionnaire d'add-ons pour **World of Warcraft Forever** (client 1.60.1). Il range tous tes add-ons dans une seule
fenêtre : tu les allumes ou les éteins d'un clic, une fiche te dit à quoi chacun sert, et les profils (Leveling, Donjon,
Pêche, Minimal…) allument d'un coup tout un jeu d'add-ons.

## Installer

1. Ferme le jeu.
2. Copie le dossier `GrimoireAddonManager` dans `World of Warcraft\_forever_\Interface\AddOns\`
   (on doit trouver `…\AddOns\GrimoireAddonManager\GrimoireAddonManager.toc`, sans dossier en trop au milieu).
3. Lance le jeu. Sur l'écran des personnages, bouton **AddOns** : vérifie que « Grimoire Addon Manager » est coché.

Tes réglages, profils, notes et favoris ne sont pas dans ce dossier (le jeu les garde dans
`WTF\Account\…\SavedVariables\`) : réinstaller ou mettre à jour l'add-on ne les efface pas.

## Les commandes principales

On les tape dans le chat. `/gam`, `/maa` et `/mesaddons` marchent pareil ; les mots anglais aussi (`/maa help`).

| Commande | Ce qu'elle fait |
|---|---|
| `/maa` | ouvre la fenêtre |
| `/maa aide` | la liste des commandes dans le chat |
| `/maa antiseche` | toutes les commandes, cliquables (aussi le bouton « ? » de la fenêtre) |
| `/maa visite` | relance la visite guidée |
| `/maa profil Donjon` | applique un profil (puis recharge) |
| `/maa recharger` | applique les changements en attente |
| `/maa annuler` | défait le dernier changement |
| `/maa erreurs` | la fenêtre des erreurs Lua |
| `/maa depannage` puis `/maa retour` | tout éteindre sauf l'essentiel, puis tout remettre comme avant |
| `/maa resume` | l'état en une ligne |

On ouvre aussi la fenêtre par le bouton rond de la minicarte, par le menu Échap › AddOns, ou par une touche
(menu Raccourcis du jeu).

**À retenir :** cocher ou décocher ne change rien tant que tu n'as pas cliqué **Recharger** en bas de la fenêtre.

## Où sont les réglages

- Bouton **Options** de la fenêtre, `/maa options`, ou Échap › Options › AddOns (`/maa options jeu`).
- Onglets à gauche (Fenêtre, Liste, Fiches, Profils, Erreurs) ; coche « Montrer les réglages avancés » pour les
  réglages fins.

## En cas de souci

1. **La fenêtre ne s'ouvre pas** : vérifie que l'add-on est coché sur l'écran des personnages ; essaie `/mesaddons`
   (si un autre add-on a pris `/maa`) ou le bouton de la minicarte.
2. **Un add-on ne se charge pas** : lis la raison écrite à droite de sa ligne (dépendance manquante, périmé…).
   Pour un add-on « périmé » : `/maa perimes on`, puis recharge.
3. **Des erreurs Lua** : `/maa erreurs`, choisis l'erreur, bouton **Copier**, et donne-la à qui t'aide.
4. **Trouver l'add-on qui casse tout** : `/maa depannage`, recharge, teste ; `/maa retour` remet tout comme avant.
5. **La fenêtre s'affiche mal** : `/maa diag` puis `/reload`, et transmets le résultat (il est dans la sauvegarde).

Le mode d'emploi complet (maquette cliquable, toutes les commandes et options, FAQ) est dans `mode-d-emploi.html`.
