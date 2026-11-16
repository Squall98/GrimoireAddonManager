Données des fiches d'add-ons (catégories, liens CurseForge, utilité, textes FR/EN, doublons, profils prêts) pour « Mes Add-ons » ; fichiers JSON, aucun code du jeu.

# donnees/fiches

| Fichier | Contenu |
|---|---|
| `fiches.json` | Une entrée par dossier installé (102, modules compris). Clés : `type` (principal/module), `parent`, `categories` (ids de `categories.json`), `curseforge` (adresse, ou `null` + `note_lien` qui explique), `confiance` (haute = vérifié Perplexity + .toc le 15/11/2026, moyenne, aucune), `utilite` (indispensable/confort/gadget), `fr` et `en` (`resume`, `commandes`, `remarques`), `doublons`, `icone` et `dependances` (lus dans le .toc), `verifie`. |
| `categories.json` | Les 26 catégories CurseForge + 6 lues dans les .toc, avec nom FR et EN. |
| `doublons.json` | Paires d'add-ons qui se recoupent, avec explication FR/EN. |
| `profils.json` | Leveling, Donjon, Pêche, Minimal : add-ons principaux (leurs modules suivent), nom/note FR/EN, icône, couleur. Seuls les add-ons installés sont gardés. |
| `sans-fiche.py` | `python -X utf8 sans-fiche.py [dossier AddOns]` : liste les add-ons installés sans fiche et les fiches incomplètes ; code 0 = rien à signaler. |
| `essais/construire.py` | Régénère les JSON à partir des textes + des .toc (utile pour ajouter une « nouvelle fiche »). |

Règles : un module (sous-dossier d'un add-on) hérite catégories, lien et utilité de son principal. Rien de propre à Nykaro : un add-on sans entrée = « pas encore de fiche ». Adresses `curseforge.com/projects/<id>` : l'id vient du .toc (`X-Curse-Project-ID`), donc sûr.
Les 33 fiches de départ viennent de `Claude\Fiches-addons\FichesAddons\Fiches.lua` (copiées, pas modifiées).
