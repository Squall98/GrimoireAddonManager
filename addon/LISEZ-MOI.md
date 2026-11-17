Le code de l'add-on « Mes Add-ons » (dossier GrimoireAddonManager, à copier dans Interface\AddOns du jeu par `outils/installer.py`).

# addon/GrimoireAddonManager

Squelette (B1-02), fenêtre Grimoire (B2-01) et fiche + infobulle (B2-02) puis recherche, tris, badges et options (B2-03, v0.4.0) : l'add-on charge ses données, ses réglages, son journal, ses textes (français et anglais), enregistre ses commandes et ouvre la fenêtre (catégories, liste, fiche courte, activer/désactiver, Recharger, Annuler) ; au survol une infobulle, au clic la fiche complète sur le parchemin (note perso, fiche modifiable, réglages et lien CurseForge) ; une barre de recherche (tolérante aux fautes, par nom, fiche, note, commandes `/way`, étiquettes `#pvp`), des tris, des puces de filtres, des favoris, des badges, la raison en clair, un menu au clic droit et un panneau d'options complet (dans la fenêtre et dans Échap › Options › AddOns).

| Fichier | Rôle |
|---|---|
| `GrimoireAddonManager.toc` | carte d'identité : Interface 16001, version, SavedVariables (compte `MesAddonsDB`, personnage `MesAddonsPersoDB`), ordre de chargement |
| `Donnees\*.lua` | **générés** par `outils/generer_donnees.py` depuis `donnees/` : ne jamais les modifier à la main |
| `Core\Espace.lua` | espace commun `ns` partagé par tous les fichiers |
| `Core\Reglages.lua` | valeurs de départ + choix sauvegardés (lire / écrire typé / réinitialiser), complétés à chaque mise à jour sans perdre les choix |
| `Core\Langue.lua` | langue automatique (client) ou choisie, repli en anglais, `ns.T(clé, …)` |
| `Core\Sortie.lua` | `ns.dire(texte)` : message dans le chat avec préfixe coloré |
| `Core\Journal.lua` | journal de débogage interne (clé de texte + arguments, taille max, regroupement des lignes identiques, capture des erreurs de l'add-on sans remplacer le gestionnaire du jeu) |
| `Core\Fiches.lua` | accès aux 102 fiches (texte dans la langue, « pas encore de fiche » sinon) |
| `Core\Personnages.lua` | mémorise chaque personnage connecté (GUID, nom, faction, classe) |
| `Core\Commandes.lua` | commandes `/mesaddons` et `/maa` (valeurs de départ, modifiables), détection d'une commande déjà prise, sous-commandes aide / ouvrir / version / journal / langue / commandes |
| `Fenetre\Style.lua` | thèmes Horde / Alliance / Neutre (auto selon la faction), couleurs, fonds, emblème, polices (jeu, gothique, Cinzel au choix), boutons et cases ; tout vient de `interface` dans `donnees/reglages.json` |
| `Fenetre\Cadre.lua` | la fenêtre : en-tête, pied (Annuler, Recharger), déplacement, taille, poignée, version mini, Échap, ouverture/fermeture |
| `Fenetre\Acces.lua` | bouton de la minicarte (compteur, clic droit = menu des profils), bouton « AddOns » du menu Échap, sous-commandes theme / taille / police / mini |
| `Liste\Modele.lua` | les add-ons du jeu : catégories, sous-modules, état coché, changements en attente, Annuler (5 états), Recharger |
| `Liste\Vue.lua` | colonne des catégories, liste à cases (sous-modules repliés), bandeau de catégorie ; la fiche est déléguée à `Fiche\Parchemin.lua` |
| `Liste\Recherche.lua` | modèle de la liste : recherche (score, tolérance aux fautes), tris, filtres rapides, favoris, étiquettes, utilité, nouveau / mis à jour, erreurs des autres add-ons, badges, raison en clair |
| `Liste\Barre.lua` | champ de recherche, bouton de tri, bouton Options, puces de filtres (à la ligne si besoin) |
| `Liste\Menu.lua` | menu du clic droit sur une ligne : favori, essai, à désinstaller, utilité, vu, étiquettes, verrou, activer avec ses modules, activer seul, copier le lien |
| `Liste\Commande.lua` | sous-commandes chercher / tri / etiquette / favori / desinstaller / sansfiche / vus |
| `Options\Appliquer.lua` | changer un réglage et en appliquer l'effet ; actions des boutons ; proposition d'une commande libre |
| `Options\Panneau.lua` | panneau d'options généré d'après le schéma `donnees/options.json` ; volet dans la fenêtre |
| `Options\Page.lua` | page Échap › Options › AddOns (`Settings.RegisterCanvasLayoutCategory`) et sous-commande `options` |
| `Erreurs\Capture.lua` | capture des erreurs Lua (chaînée devant le gestionnaire du jeu), attribution à l'add-on, compteur, journal détaillé dans la sauvegarde |
| `Erreurs\Sante.lua` | mémoire de chaque add-on et du total (alerte au-delà d'un seuil), mode mesure du processeur |
| `Erreurs\Fenetre.lua` | fenêtre des erreurs : liste, détail complet, copier, effacer |
| `Erreurs\Commande.lua` | sous-commandes erreurs / memoire / cpu et boutons d'options |
| `Fiche\Modele.lua` | contenu d'une fiche : texte du fichier ou version modifiée en jeu (prioritaire), note perso, technique, dépendances, doublons actifs, badges, lien CurseForge, ouverture des réglages |
| `Fiche\Infobulle.lua` | infobulle au survol d'une ligne de la liste (chaque partie réglable) |
| `Fiche\Parchemin.lua` | fiche complète sur le parchemin : zone qui défile, note perso (enregistrée à la frappe), éditeur de fiche, volet du lien, boutons |
| `Fiche\Commande.lua` | sous-commande `fiche` : couper ou activer l'infobulle et chaque partie |
| `Profils\Modele.lua` | profils : prêts au départ, Tout / Rien, verrous, dépendances, aperçu +x / -y, application (ce personnage ou tous), fusion, comparaison, copie en texte et sauvegarde complète |
| `Profils\Interface.lua` | fenêtre des profils (liste, détail, confirmation, comparer, copier/coller) et bouton « Profils » de l'en-tête |
| `Profils\Situation.lua` | proposition du profil associé en donjon, raid ou champ de bataille (jamais automatique, avec rechargement) |
| `Profils\Commande.lua` | sous-commandes profils / profil / verrou |
| `Actions\Modele.lua` | actions rapides : activer seul, activer avec ses modules (Maj + clic), essai d'une session, dépannage et retour, périmés, compteur, résumé |
| `Actions\Commande.lua` | sous-commandes activer / desactiver / seul / essai / depannage / retour / recharger / perimes / annuler / resume |
| `Actions\Connexion.lua` | fin des essais et résumé d'une ligne à la connexion, noms des raccourcis clavier |
| `Actions\Rapide.lua` | menu du clic droit sur le bouton de minicarte : recharger, profils, dépannage, périmés |
| `Aide\Modele.lua`, `Fenetre.lua`, `Visite.lua`, `Commande.lua` | antisèche de toutes les commandes (celles de ce gestionnaire, des fiches, du jeu ; clic = écrite dans le chat, Maj + clic = lancée), visite guidée en 5 bulles au premier lancement (relançable), bouton « ? » de l'en-tête (voir `Aide\LISEZ-MOI.md`) |
| `Bindings.xml` | raccourcis clavier : fenêtre, profils, enregistrer et recharger, antisèche, version mini / complète |
| `Core\Demarrage.lua` | événements du jeu (ADDON_LOADED, PLAYER_LOGIN) |

Règles : aucun texte, nombre de réglage ni identifiant dans le code (tout vient de `Donnees\`) ; `outils/verifier.py` le contrôle. `/ma` est prise par le jeu : jamais utilisée par défaut.
Aide (étape B5-01, v0.7.0) : antisèche des commandes, visite guidée, mode mini / complet par raccourci et menu, anglais complet vérifié.
