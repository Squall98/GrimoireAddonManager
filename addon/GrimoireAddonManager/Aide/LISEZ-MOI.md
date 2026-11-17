Aide intégrée de Mes Add-ons : antisèche de toutes les commandes (clic = écrite dans le chat) et visite guidée en 5 bulles.

# Aide

| Fichier | Rôle |
|---|---|
| `Modele.lua` | rassemble les commandes : celles de ce gestionnaire (groupes de `reglages.aide.groupes`), celles citées dans la fiche de chaque add-on (texte découpé aux virgules hors parenthèses), celles que le jeu connaît en plus (`SlashCmdList` rapproché du nom de l'add-on) ; recherche sans accents ; écrit une commande dans le chat ou la lance |
| `Fenetre.lua` | fenêtre de l'antisèche : colonne d'onglets à gauche (un par thème de ce gestionnaire, puis les add-ons par catégorie ou un par add-on, réglage `aide.regrouper`), page choisie à droite en cartes qui défilent (commande en doré, description dessous), recherche sur toutes les pages (onglet « Résultats »), choix du contenu (tout / ce gestionnaire / add-ons installés) ; déplaçable, redimensionnable (poignée, bornes `interface.aide.taille_min` / `taille_max`), taille, place et onglet gardés (`MesAddonsDB.antiseche`), Échap la ferme ; clic = écrit dans le chat, Maj + clic = lance |
| `Visite.lua` | visite guidée : bulles et cadre doré autour de la partie montrée (étapes dans `reglages.aide.visite`), lancée seule au premier lancement (3 s après la connexion, jamais en combat), relançable (`/maa visite`, menu de la minicarte, options) |
| `Commande.lua` | sous-commandes `antiseche` et `visite`, petit bouton « ? » de l'en-tête de la fenêtre |

Réglages : `aide.*` (options › « Aide : antisèche et visite »). Textes : `aide.*`, `visite.*`, `aideportee.*`. Rien en dur : les groupes, les étapes de la visite et leurs cibles sont dans `donnees/reglages.json`. Mode mini / complet : déjà dans `Fenetre\Cadre.lua` (B2-01), complété ici par un raccourci clavier, une entrée du menu de la minicarte et la mention dans la visite.
