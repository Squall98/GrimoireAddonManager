Capture des erreurs Lua, journal des erreurs, fenêtre d'erreurs, mémoire des add-ons et mode mesure du processeur (étape B4-01).

| Fichier | Rôle |
|---|---|
| `Capture.lua` | se place devant le gestionnaire d'erreurs du jeu (l'ancien reçoit toujours l'erreur ensuite : BugSack et cie continuent de marcher), trouve l'add-on (chemin `Interface\AddOns\<dossier>\…` du message, sinon de la pile d'appels), compte les répétitions, garde date et heure de la première et de la dernière fois, fichier, ligne, pile d'appels, version de l'add-on, combat ; tout est rangé dans `MesAddonsDB.erreurs_journal` (fichier de sauvegarde du compte, écrit au /reload et à la déconnexion), limité à `erreurs.max` erreurs différentes ; annonce (fenêtre, chat ou rien), petit son en option, cache la fenêtre d'erreur du jeu (réglage `scriptErrors`) si l'option est active |
| `Sante.lua` | mémoire de chaque add-on et du total (`UpdateAddOnMemoryUsage`), mesure régulière et alerte au-delà de seuils réglables ; mode mesure du processeur (réglage du jeu `scriptProfile`, à recharger), mesures triées |
| `Fenetre.lua` | fenêtre des erreurs : liste paginée, filtre par add-on, détail complet qui défile, boutons Copier / Copier tout / Effacer, mémoire totale en bas |
| `Commande.lua` | sous-commandes `erreurs [add-on | effacer]`, `memoire`, `cpu [activer | couper | zero]` ; boutons « Ouvrir la fenêtre des erreurs » et « Effacer toutes les erreurs » du panneau d'options |

Réglages : `erreurs.*` (valeurs de départ dans `donnees/reglages.json`, panneau dans le groupe « Erreurs, mémoire et processeur » de `donnees/options.json`) ; tailles, motifs de chemin, noms des réglages du jeu : `interface.erreurs`. Tests : `outils/banc/tests/test_erreurs.lua`.
