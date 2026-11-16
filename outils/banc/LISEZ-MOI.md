Le banc d'essai hors jeu : Lua 5.1 portable + une imitation de l'API de WoW Forever pour charger l'add-on et lancer des tests sans le jeu.

# outils/banc

## Lancer
- Tous les tests + toute la vérification : `python -X utf8 outils\verifier.py`.
- Un seul fichier de tests : `set MAA_RACINE=<racine du projet>` puis `outils\banc\lua51\lua5.1.exe outils\banc\tests\test_commandes.lua`.

## Contenu
| Fichier | Rôle |
|---|---|
| `lua51/` | Lua 5.1 portable (`lua5.1.exe`, `luac5.1.exe`), accord de Nykaro (CA.2). Hors git (voir `essais/sonde/lua51/lua51.zip` pour le repartir de zéro) |
| `wow.lua` | l'imitation du jeu : `C_AddOns` (liste tirée des vrais .toc), cadres et événements, `SlashCmdList` (avec des commandes du jeu comme `/ma`), `seterrorhandler`, `C_Timer`, chat, SavedVariables écrites/relues au `/reload`, `GetLocale`, `UnitGUID`… |
| `test.lua` | mini cadre de tests (`T.test`, `T.eq`, `T.vrai`, `T.sans_erreur`, `T.fin`) |
| `tests/test_*.lua` | les tests (chargement, commandes, langue et réglages, journal et personnages, fenêtre Grimoire) |
| `addons_installes.lua` | **généré** par `instantane_addons.py` : photo des add-ons installés (nom, titre, dépendances, métadonnées) |
| `instantane_addons.py` | refait cette photo depuis `_forever_\Interface\AddOns` (lecture seule) |

## Écrire un test
```lua
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")
T.test("ce que ça prouve", function(B)
  local ns = B.demarrer({ locale = "frFR" })   -- jeu simulé : charge l'add-on, ADDON_LOADED, PLAYER_LOGIN
  B.slash("/maa version")                      -- tape une commande
  T.vrai(B.chat_contient("102 fiches"))        -- lit le chat (codes de couleur retirés)
  T.sans_erreur()                              -- aucune erreur Lua dans le jeu simulé
end)
T.fin()
```
Autres outils : `B.recharger()` (= /reload, sauvegardes relues), `B.deconnecter()`, `B.avancer(secondes)` (minuteries), `B.wtf` (le « disque »).

B2-03 : `tests/test_liste.lua` (recherche, tris, filtres, favoris), `test_badges.lua` (badges, raison, menu, commandes) et `test_options.lua` (panneau d'options, page du jeu) ; le banc imite aussi `Settings.RegisterCanvasLayoutCategory` (`B.parametres`).

B4-01 : `tests/test_erreurs.lua` (capture, journal, fenêtre d'erreurs, mémoire, processeur) ; le banc imite `GetCVar`/`SetCVar` (`B.cvars`, gardés d'une session à l'autre), `GetAddOnCPUUsage` (`B.cpu`, nul tant que `scriptProfile` ≠ 1), `InCombatLockdown` (`B.en_combat`) et `PlaySound` (`B.sons`) ; une erreur se provoque avec `B.erreur_jeu("Interface/AddOns/Nom/Fichier.lua:12: message")`, la mémoire se pose dans `B.memoire`.

B5-01 : `tests/test_aide.lua` (antisèche, visite guidée, mode mini / complet, anglais complet à l'écran) ; le banc imite `ChatFrame_OpenChat` (`B.chat_saisie` = dernier texte écrit dans la zone de saisie sans être envoyé) ; `B.demarrer` marque la visite guidée comme déjà vue, sauf si le test passe `visite = true`.

## Limites (à savoir)
Le banc imite l'API **telle qu'elle est documentée** dans `docs/API-FOREVER.md` ; il ne rend ni graphismes, ni cadres réels, ni taint. Tout ce qui est visuel ou incertain (❓ du document) reste vérifié en jeu à la recette finale (B5-02). Les méthodes de cadre inconnues sont sans effet (elles ne plantent pas) : un test réussi n'est donc pas une preuve de rendu.
Les modules **Blizzard_*** ne sont pas dans la liste du banc.
