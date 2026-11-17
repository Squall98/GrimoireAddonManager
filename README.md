# Grimoire Addon Manager (GAM)

Gestionnaire d'add-ons pour **World of Warcraft Forever** (client 1.60.1, interface 16001), en français et en anglais.
*An add-on manager for WoW Forever, in French and English.*

Tous tes add-ons dans une seule fenêtre façon grimoire, aux couleurs de ta faction (Horde ou Alliance) :

- **Activer / désactiver** d'un clic, par catégorie, ou tout d'un coup ; « Recharger » applique, « Annuler » revient.
- **Une fiche par add-on** (102 fiches fournies) : à quoi il sert, ses commandes, ce qu'il faut savoir, ta note perso ;
  résumé dans l'infobulle au survol.
- **Rangé par catégories** (style CurseForge), tri, filtres, recherche tolérante aux fautes, favoris, étiquettes.
- **Profils** (Leveling, Donjon, Pêche, Minimal…, et les tiens) : un jeu d'add-ons d'un coup, par macro ou minicarte.
- **Erreurs Lua** capturées avec leur détail, mémoire et processeur par add-on, mode dépannage.
- **Antisèche** de toutes les commandes (les tiennes et celles de tes add-ons), visite guidée, version mini.
- Presque tout se règle dans les options ; rien n'est propre à une personne.

## Installer

Copie le dossier `addon/MesAddons` dans `World of Warcraft\_forever_\Interface\AddOns\`, puis lance le jeu.
Commandes : `/gam`, `/maa` ou `/mesaddons` (`/maa aide` pour la liste). Mode d'emploi complet : `addon/MesAddons/mode-d-emploi.html`.

## Le dépôt

- `addon/MesAddons/` : l'add-on (Lua). Les fichiers `Donnees/*.lua` sont **générés** depuis `donnees/`.
- `donnees/` : fiches, catégories, profils, réglages et textes (JSON) : on modifie ici, puis
  `python -X utf8 outils/generer_donnees.py`.
- `outils/` : `verifier.py` (vérification complète + banc d'essai hors jeu en Lua 5.1, dans `outils/banc/`),
  `installer.py` (copie vérifiée au SHA256), `journal/` (page lisible du journal des erreurs).

## Licence

MIT © 2026 Nykaro. Écrit avec l'aide de Claude (Anthropic). Inspiré par la méthode d'autres gestionnaires
(SAM, ACP), sans en reprendre le code.
