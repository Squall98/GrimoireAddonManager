# Fabrique donnees/fiches/*.json à partir des textes ci-dessous + des .toc installés (icône, dépendances).
# Usage : python construire.py   (relance = régénère ; la vérité reste les .json produits)
import json, os, re, sys
ADDONS = r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns"
OUT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CF = "https://www.curseforge.com/wow/addons/"
PRJ = "https://www.curseforge.com/projects/"
DATE = "2026-11-15"

CATEGORIES = {  # id: (fr, en, source)
 "achievements": ("Hauts faits", "Achievements", "curseforge"),
 "action-bars": ("Barres d'action", "Action Bars", "curseforge"),
 "artwork": ("Illustrations", "Artwork", "curseforge"),
 "auction-economy": ("Hôtel des ventes & économie", "Auction & Economy", "curseforge"),
 "audio-video": ("Audio & vidéo", "Audio & Video", "curseforge"),
 "bags-inventory": ("Sacs & inventaire", "Bags & Inventory", "curseforge"),
 "boss-encounters": ("Combats de boss", "Boss Encounters", "curseforge"),
 "buffs-debuffs": ("Buffs & debuffs", "Buffs & Debuffs", "curseforge"),
 "chat-communication": ("Chat & communication", "Chat & Communication", "curseforge"),
 "class": ("Classe", "Class", "curseforge"),
 "combat": ("Combat", "Combat", "curseforge"),
 "companions": ("Compagnons", "Companions", "curseforge"),
 "data-export": ("Export de données", "Data Export", "curseforge"),
 "guild": ("Guilde", "Guild", "curseforge"),
 "huds": ("Affichage tête haute", "HUDs", "curseforge"),
 "libraries": ("Bibliothèques", "Libraries", "curseforge"),
 "map-minimap": ("Carte & minicarte", "Map & Minimap", "curseforge"),
 "mail": ("Courrier", "Mail", "curseforge"),
 "miscellaneous": ("Divers", "Miscellaneous", "curseforge"),
 "plugins": ("Extensions", "Plugins", "curseforge"),
 "professions": ("Métiers", "Professions", "curseforge"),
 "quests-leveling": ("Quêtes & leveling", "Quests & Leveling", "curseforge"),
 "roleplay": ("Jeu de rôle", "Roleplay", "curseforge"),
 "tooltip": ("Infobulles", "Tooltip", "curseforge"),
 "transmogrification": ("Transmogrification", "Transmogrification", "curseforge"),
 "unit-frames": ("Cadres d'unités", "Unit Frames", "curseforge"),
 # catégories lues dans les .toc ou ajoutées pour Forever (hors liste CurseForge)
 "guides": ("Guides", "Guides", "toc"),
 "collections": ("Collections", "Collections", "toc"),
 "equipment": ("Équipement", "Equipment", "toc"),
 "user-interface": ("Interface", "User Interface", "toc"),
 "inventory": ("Inventaire", "Inventory", "toc"),
 "dbm": ("Modules DBM", "DBM modules", "toc"),
}

U = {"i": "indispensable", "c": "confort", "g": "gadget"}
# dossier: (cats, url|None, confiance, utilité, fr_resume, fr_cmd, fr_rem, en_resume, en_cmd, en_rem, doublons, note_lien)
# confiance : haute = vérifié (Perplexity + .toc le 15/11/2026) ; moyenne = adresse probable ; aucune = pas de page connue
A = {}
def add(d, cats, url, conf, ut, fr, en, dbl=(), lien_note=""):
    A[d] = dict(categories=cats, curseforge=url, confiance=conf, utilite=U[ut], fr=fr, en=en,
                doublons=list(dbl), note_lien=lien_note)
def T(r, c="", n=""): return dict(resume=r, commandes=c, remarques=n)

add("Auctionator", ["auction-economy"], CF+"auctionator", "haute", "c",
 T("Hôtel des ventes plus rapide : recherche par liste, prix du marché, vente en un clic, annulation facile.", "/atr (ou /auctionator)", "Recoupe en partie Naowh Forever : The Market (vente à l'HV). L'un ou l'autre suffit."),
 T("Faster auction house: shopping lists, market prices, one-click selling, easy cancelling.", "/atr (or /auctionator)", "Partly overlaps Naowh Forever: The Market (selling). One of the two is enough."),
 ["NaowhForever_Market"])
add("Baganator", ["bags-inventory"], CF+"baganator", "haute", "c",
 T("Sacs réunis en un seul, rangés par catégories, avec recherche ; voit aussi les sacs et la banque de tes autres persos.", "/bgr (ou /baganator), /bgrs <mot> pour chercher", "Va avec Syndicator (garder les deux activés)."),
 T("All bags merged into one, sorted by category, with search; also shows the bags and bank of your other characters.", "/bgr (or /baganator), /bgrs <word> to search", "Works with Syndicator (keep both enabled)."))
add("Syndicator", ["bags-inventory"], CF+"syndicator", "haute", "c",
 T("Mémorise les objets de tous tes persos (sacs, banque, courrier) ; sert à Baganator et à d'autres add-ons.", "/syn, /syns <mot> pour chercher un objet sur tous tes persos", "Rien de spécial à faire : laisser activé avec Baganator."),
 T("Remembers the items of all your characters (bags, bank, mail); used by Baganator and other add-ons.", "/syn, /syns <word> to find an item across all characters", "Nothing to do: leave it enabled with Baganator."))
add("BetterFishing", ["professions"], CF+"better-fishing", "haute", "c",
 T("Pêche avec une seule touche ou un double-clic, et son du bouchon plus fort.", "/bf (ou /betterfishing)", "Doublon de FishyWashy : en garder un seul activé."),
 T("Fish with a single key or a double-click, with a louder bobber sound.", "/bf (or /betterfishing)", "Duplicate of FishyWashy: keep only one enabled."), ["FishyWashy"])
add("FishyWashy", ["professions"], CF+"fishywashy-forever-fishing", "haute", "c",
 T("Aide à la pêche : bouchon plus bruyant, boutons d'appâts, lancer facile, statistiques de pêche.", "/fishy", "Doublon de BetterFishing : en garder un seul activé."),
 T("Fishing helper: louder bobber, lure buttons, easy casting, fishing statistics.", "/fishy", "Duplicate of BetterFishing: keep only one enabled."), ["BetterFishing"])
add("Curator", ["collections"], None, "moyenne", "g",
 T("Mini-jeu de cartes à collectionner sur les créatures d'Azeroth : ouvre des boosters, remplis ton album zone par zone, montre-le.", "/curator", "Purement pour le plaisir, rien d'indispensable."),
 T("Collectible card mini-game about Azeroth's creatures: open boosters, fill your album zone by zone, show it off.", "/curator", "Purely for fun, nothing essential."),
 lien_note="Page CurseForge non confirmée par la recherche du 15/11/2026 : adresse laissée vide.")
add("DBM-Core", ["boss-encounters"], PRJ+"3358", "haute", "i",
 T("Deadly Boss Mods : alertes et minuteurs pendant les combats de boss (donjons, raids).", "/dbm (options), /pull <secondes>, /break <minutes>, /range", "Les ~30 dossiers DBM-* sont ses modules. Seuls ceux marqués Forever ou Vanilla servent ici ; les autres (Midnight, BC, WotLK, MoP…) restent « périmés » et peuvent rester désactivés."),
 T("Deadly Boss Mods: alerts and timers during boss fights (dungeons, raids).", "/dbm (options), /pull <seconds>, /break <minutes>, /range", "The ~30 DBM-* folders are its modules. Only those marked Forever or Vanilla are useful here; the others (Midnight, BC, WotLK, MoP…) stay 'out of date' and can remain disabled."))
add("Details", ["combat"], PRJ+"61284", "haute", "c",
 T("Compteur de dégâts et de soins (DPS/HPS), avec le détail de chaque sort et de chaque combat.", "/details", "Les dossiers Details_* sont ses extensions. Details_TinyThreat fait doublon avec le compteur de menace de Naowh Forever : Combat."),
 T("Damage and healing meter (DPS/HPS), with the breakdown of each spell and each fight.", "/details", "The Details_* folders are its plugins. Details_TinyThreat duplicates the threat meter of Naowh Forever: Combat."), ["Details_TinyThreat"])
add("DialogueUI", ["quests-leveling"], CF+"dialogueui", "haute", "c",
 T("Remplace la fenêtre des quêtes et des discussions par une interface façon jeu moderne, plus lisible, jouable au clavier.", "Réglages : Échap > Options > AddOns", "Compatible avec Spoken (les voix FR continuent)."),
 T("Replaces the quest and gossip windows with a modern-game style interface, more readable, playable with the keyboard.", "Settings: Esc > Options > AddOns", "Compatible with Spoken (the French voices keep working)."))
add("ForeverClassGuide", ["guides", "class"], PRJ+"1739093", "haute", "c",
 T("ForeverGuide : guide de ta classe (talents, sorts du maître, nourriture à buff, campement, métiers, Héritage).", "/fg (ou /foreverguide)", "Recoupe en partie Naowh Forever : Training Planner (quoi apprendre, talents)."),
 T("ForeverGuide: guide for your class (talents, trainer spells, buff food, camp, professions, Legacy).", "/fg (or /foreverguide)", "Partly overlaps Naowh Forever: Training Planner (what to learn, talents)."), ["NaowhForever_Training"])
add("ForeverDungeonJournal", ["boss-encounters"], CF+"forever-dungeon-journal", "haute", "g",
 T("DungeonJournal : boss, butin et quêtes des donjons.", "/dj", "DÉSACTIVÉ exprès : doublon de Naowh Forever : Dungeon Journal."),
 T("DungeonJournal: bosses, loot and quests of the dungeons.", "/dj", "DISABLED on purpose: duplicate of Naowh Forever: Dungeon Journal."), ["NaowhForever_DungeonJournal"])
add("ForeverLootSparkles", ["miscellaneous"], PRJ+"1729017", "haute", "g",
 T("Fait toujours briller les objets de quête à ramasser (le jeu coupe parfois cet effet).", "Réglages : Échap > Options > AddOns"),
 T("Always makes quest items to loot sparkle (the game sometimes turns this effect off).", "Settings: Esc > Options > AddOns"))
add("ForeverSecrets", ["miscellaneous", "quests-leveling"], CF+"foreversecrets", "haute", "g",
 T("Quêtes cachées, livres de bibliothèque et secrets de WoW Forever, avec coordonnées, captures et suivi par perso.", "/fsecret (secrets), /fbooks (livres)", "Les livres recoupent Naowh Forever : Discovery."),
 T("Hidden quests, library books and secrets of WoW Forever, with coordinates, screenshots and per-character tracking.", "/fsecret (secrets), /fbooks (books)", "Books overlap Naowh Forever: Discovery."), ["NaowhForever_Discovery"])
add("GearQuestForever", ["quests-leveling", "equipment"], PRJ+"1698950", "haute", "c",
 T("Améliorations d'équipement pendant le leveling : clique un emplacement, choisis l'objet à aller chercher, suis-le dans le journal.", "/gq (ou /gearquest)", "Les dossiers GearQuestForever_<CLASSE> sont ses données ; GearQuestForever_Languages le met en français."),
 T("Gear upgrades while leveling: click a slot, pick the item to go get, track it in the quest log.", "/gq (or /gearquest)", "The GearQuestForever_<CLASS> folders are its data; GearQuestForever_Languages translates it."))
add("GTFO", ["combat"], CF+"gtfo", "haute", "c",
 T("Son d'alerte quand tu restes dans quelque chose qui fait mal (feu, poison…) : « sors de là ! ».", "/gtfo"),
 T("Warning sound when you stand in something harmful (fire, poison…): 'get out!'.", "/gtfo"))
add("MinimapButtonButton", ["map-minimap", "user-interface"], PRJ+"446096", "haute", "c",
 T("Range tous les boutons de la minicarte dans un seul bouton.", "Clique son bouton près de la minicarte"),
 T("Gathers all minimap buttons into a single button.", "Click its button near the minimap"))
add("NaowhForever", ["miscellaneous", "combat", "professions", "auction-economy", "quests-leveling"], CF+"naowhforever", "haute", "i",
 T("Le « tout-en-un » de Forever : une fenêtre commune pour ses 15 modules (BiS, donjons, quoi apprendre, métiers, HV, combat, confort…).", "/nf (ou /nao, /naowh), /nfquests (quêtes et rares par zone)", "Remplace DungeonJournal et What's Training (désactivés). Chaque module s'allume dans /nf > Réglages > Modules."),
 T("The Forever 'all-in-one': a shared window for its 15 modules (BiS, dungeons, what to learn, professions, AH, combat, comfort…).", "/nf (or /nao, /naowh), /nfquests (quests and rares by zone)", "Replaces DungeonJournal and What's Training (disabled). Each module is switched on in /nf > Settings > Modules."),
 lien_note="Site officiel aussi : https://naowh.gg/forever/")
add("OPie", ["action-bars"], CF+"opie", "haute", "c",
 T("Roues d'actions : tu maintiens une touche, une roue de sorts/objets/montures apparaît, tu choisis à la souris.", "/opie"),
 T("Action rings: hold a key, a ring of spells/items/mounts appears, pick with the mouse.", "/opie"))
add("OpenMap", ["map-minimap"], PRJ+"1735937", "haute", "c",
 T("Carte du monde d'un seul tenant : toutes les zones collées, on zoome de l'une à l'autre.", "/openmap", "La carte de Blizzard, le journal de quêtes et Questie continuent de marcher."),
 T("Seamless world map: all zones joined together, zoom from one to the next.", "/openmap", "Blizzard's map, the quest log and Questie keep working."),
 lien_note="Site officiel aussi : https://openmap.world")
add("Pawn", ["equipment"], CF+"pawn", "moyenne", "c",
 T("Compare les objets et marque les améliorations (flèche verte) selon les stats de ta spé.", "/pawn", "Recoupe un peu GearQuest et Naowh : BiS List ; ensemble, ça ne gêne pas."),
 T("Compares items and flags upgrades (green arrow) according to your spec's stats.", "/pawn", "Slightly overlaps GearQuest and Naowh: BiS List; together they do not conflict."))
add("Plater", ["unit-frames"], PRJ+"100547", "haute", "c",
 T("Barres de vie au-dessus des ennemis (nameplates) très réglables : menace, sorts lancés, debuffs.", "/plater"),
 T("Highly customisable nameplates above enemies: threat, cast bars, debuffs.", "/plater"))
add("Questie", ["quests-leveling", "map-minimap"], CF+"questie", "haute", "i",
 T("Affiche sur la carte et la minicarte les quêtes disponibles, leurs objectifs et où les rendre.", "/questie", "QuestieDB (sa base) et QuestieTrace (collecte de données) vont avec."),
 T("Shows available quests, their objectives and turn-in points on the map and minimap.", "/questie", "QuestieDB (its database) and QuestieTrace (data collection) go with it."))
add("RXPGuides", ["quests-leveling", "guides"], PRJ+"486246", "haute", "i",
 T("RestedXP : guide de leveling pas à pas, avec flèche et étapes.", "/rxp", "Fait doublon avec Zygor : n'activer qu'un seul guide de leveling à la fois."),
 T("RestedXP: step-by-step leveling guide, with arrow and steps.", "/rxp", "Duplicate of Zygor: enable only one leveling guide at a time."), ["ZygorGuidesViewerForever"])
add("RareScanner", ["map-minimap", "collections"], CF+"rarescanner", "haute", "c",
 T("Prévient (son + bouton avec image) quand un monstre rare, un trésor ou un évènement apparaît sur ta minicarte.", "/rs (ou /rarescanner)"),
 T("Alerts you (sound + button with a picture) when a rare mob, treasure or event shows up on your minimap.", "/rs (or /rarescanner)"))
add("Spoken", ["quests-leveling", "audio-video"], None, "moyenne", "c",
 T("Lit le jeu à voix haute (en français) : quêtes, discussions, lieux, livres, histoires des boss. Une file, un narrateur, un bouton.", "/sp (ou /spoken), /spp (lieux), /spr (livres et lettres)", "Les dossiers Spoken_* et Spoken*Audio_frFR sont ses modules et ses voix FR. Normal que les packs de voix paraissent « désactivés » ou « périmés »."),
 T("Reads the game aloud (in French): quests, gossip, places, books, boss stories. One queue, one narrator, one button.", "/sp (or /spoken), /spp (places), /spr (books and letters)", "The Spoken_* and Spoken*Audio_frFR folders are its modules and French voices. It is normal for voice packs to look 'disabled' or 'out of date'."),
 lien_note="La recherche du 15/11/2026 donne deux pages différentes (spoken, spoken-players-chat-tts) sans certitude : adresse laissée vide, à confirmer.")
add("SpokenBooks", ["audio-video"], None, "aucune", "g",
 T("Ancien add-on, maintenant intégré à Spoken.", "", "Ce dossier ne se charge jamais : il peut partir à la corbeille (_a-supprimer)."),
 T("Old add-on, now built into Spoken.", "", "This folder never loads: it can be moved to the trash (_a-supprimer)."))
add("Syndicator", A["Syndicator"]["categories"], A["Syndicator"]["curseforge"], "haute", "c", A["Syndicator"]["fr"], A["Syndicator"]["en"])
add("TomTom", ["map-minimap"], PRJ+"18808", "haute", "c",
 T("Flèche de navigation vers des coordonnées (points de passage).", "/way <x> <y> (ex. /way 45 60), /cway (point le plus proche), /wayb (retour)"),
 T("Navigation arrow to coordinates (waypoints).", "/way <x> <y> (e.g. /way 45 60), /cway (closest point), /wayb (back)"))
add("Warmth", ["miscellaneous", "map-minimap"], PRJ+"1799681", "haute", "g",
 T("Feux de camp des joueurs sur ta carte : ce que propose chaque campement, qui est autour, et monter le tien.", "/warmth"),
 T("Players' campfires on your map: what each camp offers, who is around, and how to set up your own.", "/warmth"))
add("WhatsTraining", ["class"], PRJ+"324944", "haute", "g",
 T("What's Training : liste des sorts disponibles chez ton maître de classe.", "/wt", "DÉSACTIVÉ exprès : doublon de Naowh Forever : Training Planner."),
 T("What's Training: list of spells available from your class trainer.", "/wt", "DISABLED on purpose: duplicate of Naowh Forever: Training Planner."), ["NaowhForever_Training"])
add("ZephrasCollector", ["data-export"], None, "aucune", "g",
 T("Envoie ce que tu découvres (PNJ, quêtes, butin) au site zephras.com ; Ctrl+C sur un objet donne son lien.", "/zephras", "Facultatif : utile seulement si tu te sers du site Zephras."),
 T("Sends what you discover (NPCs, quests, loot) to zephras.com; Ctrl+C on an item gives its link.", "/zephras", "Optional: only useful if you use the Zephras site."),
 lien_note="Add-on d'un site tiers : pas de page CurseForge connue.")
add("ZygorGuidesViewerForever", ["quests-leveling", "guides"], None, "aucune", "c",
 T("Zygor : guide de leveling (version gratuite Forever), avec flèche et étapes.", "Bouton de la minicarte", "Fait doublon avec RestedXP : n'activer qu'un seul guide de leveling à la fois."),
 T("Zygor: leveling guide (free Forever version), with arrow and steps.", "Minimap button", "Duplicate of RestedXP: enable only one leveling guide at a time."), ["RXPGuides"],
 lien_note="Pas de page CurseForge du guide lui-même ; site officiel : https://zygorguides.com/")
add("FichesAddons", ["user-interface", "tooltip"], None, "aucune", "c",
 T("Cet add-on : la fiche en français que tu lis en ce moment, plus ta note perso.", "/fiche (aide), /fiche <dossier> <texte> (ta note)", "Sera remplacé par Mes Add-ons."),
 T("This add-on: the French add-on notes you are reading right now, plus your personal note.", "/fiche (help), /fiche <folder> <text> (your note)", "Will be replaced by My Add-ons."),
 lien_note="Add-on maison, pas de page publique.")

A["SpokenBooks"]["note_lien"] = "Ancien add-on intégré à Spoken : pas de page."
# Modules (dossier -> (parent, fr, en))
M = {
 "NaowhForever_AuctionData": ("NaowhForever", "Prix de tous les hôtels des ventes (données, chargées toutes seules).", "Prices of all auction houses (data, loaded automatically)."),
 "NaowhForever_BiS": ("NaowhForever", "Listes BiS, poids de stats, Gear Score, fenêtre du perso et d'inspection.", "BiS lists, stat weights, Gear Score, character and inspect windows."),
 "NaowhForever_Combat": ("NaowhForever", "Barre de consommables, swing timer, menace, PvP, debuffs de raid, bénédictions… (un interrupteur chacun).", "Consumables bar, swing timer, threat, PvP, raid debuffs, blessings… (one switch each)."),
 "NaowhForever_Discovery": ("NaowhForever", "Livres de bibliothèque, Sac de couchage douillet, quêtes et rares par zone (/nfquests).", "Library books, Cosy Sleeping Bag, quests and rares by zone (/nfquests)."),
 "NaowhForever_DiscoveryData": ("NaowhForever", "Données des quêtes et rares (chargées toutes seules).", "Quest and rare data (loaded automatically)."),
 "NaowhForever_DungeonJournal": ("NaowhForever", "Boss, butin et quêtes de chaque donjon (remplace DungeonJournal).", "Bosses, loot and quests of each dungeon (replaces DungeonJournal)."),
 "NaowhForever_JourneysData": ("NaowhForever", "Données des trajets à pied de Journeys (chargées toutes seules).", "Walking-route data for Journeys (loaded automatically)."),
 "NaowhForever_Locales": ("NaowhForever", "Traduction française de Naowh : à garder activé.", "French translation of Naowh: keep enabled."),
 "NaowhForever_Market": ("NaowhForever", "Panneau à côté de l'HV pour vendre tes sacs, plus une fenêtre farm / composants / prix.", "Panel beside the AH to sell your bags, plus a farm / reagents / prices window."),
 "NaowhForever_Professions": ("NaowhForever", "Recettes, composants et artisanat dans une fenêtre, avec les recettes pas encore apprises.", "Recipes, reagents and crafting in one window, including recipes not yet learned."),
 "NaowhForever_QoL": ("NaowhForever", "Petits conforts de jeu (/copy pour copier un texte, /nfaim…).", "Small quality-of-life features (/copy to copy a text, /nfaim…)."),
 "NaowhForever_SearchIndex": ("NaowhForever", "Permet à la recherche des réglages de trouver les options des modules éteints.", "Lets the settings search find options of switched-off modules."),
 "NaowhForever_Training": ("NaowhForever", "Quoi apprendre maintenant et jusqu'au 60, builds de talents (remplace What's Training).", "What to learn now and up to 60, talent builds (replaces What's Training)."),
 "NaowhForever_Utilities": ("NaowhForever", "Suivi d'instances, Journeys, macros, inspection et recherche de groupe, barres d'action… (un interrupteur chacun).", "Instance tracking, Journeys, macros, inspect and group finder, action bars… (one switch each)."),
 "Spoken_Quests": ("Spoken", "Lit les quêtes et les discussions.", "Reads quests and gossip."),
 "Spoken_Places": ("Spoken", "Lit l'histoire des zones sur la carte (/spp).", "Reads the story of zones on the map (/spp)."),
 "Spoken_Readables": ("Spoken", "Lit les livres, lettres, notes et plaques (/spr).", "Reads books, letters, notes and plaques (/spr)."),
 "Spoken_Bosses": ("Spoken", "Histoires des boss des donjons et raids (Compendium d'Azeroth).", "Boss stories for dungeons and raids (Azeroth Compendium)."),
 "SpokenQuestsAudioHorde_frFR": ("Spoken", "Voix françaises des quêtes Horde.", "French voices for Horde quests."),
 "SpokenQuestsAudioAlliance_frFR": ("Spoken", "Voix françaises des quêtes Alliance (inutile pour un perso Horde, mais sans gêne).", "French voices for Alliance quests (useless on a Horde character, harmless)."),
 "SpokenQuestsAudioShared_frFR": ("Spoken", "Voix françaises des quêtes communes aux deux factions.", "French voices for quests shared by both factions."),
 "SpokenQuestsAudioGossip_frFR": ("Spoken", "Voix françaises des discussions avec les PNJ.", "French voices for NPC gossip."),
 "SpokenZonesAudio_frFR": ("Spoken", "Voix françaises de l'histoire des zones (bêta).", "French voices for zone stories (beta)."),
 "SpokenBooksAudio_frFR": ("Spoken", "Voix françaises des livres et lettres.", "French voices for books and letters."),
 "SpokenBossesAudio_frFR": ("Spoken", "Voix françaises des histoires des boss : à garder activé.", "French voices for boss stories: keep enabled."),
 "SpokenContributions": ("Spoken", "Garde les répliques récoltées pour les envoyer à spoken.quest/contribute (facultatif).", "Keeps collected lines to send to spoken.quest/contribute (optional)."),
 "Details_Compare2": ("Details", "Nouvel onglet Comparer dans le détail d'un joueur.", "New Compare tab in a player's breakdown."),
 "Details_DataStorage": ("Details", "Stockage des données de Details (à garder).", "Storage for Details data (keep)."),
 "Details_EncounterDetails": ("Details", "Analyse détaillée d'un combat de boss (phases, graphiques).", "Detailed analysis of a boss fight (phases, graphs)."),
 "Details_RaidCheck": ("Details", "Talents, niveau d'objets, nourriture et flacons du groupe.", "Group talents, item level, food and flasks."),
 "Details_Streamer": ("Details", "Affiche les sorts que tu lances (pour le streaming).", "Shows the spells you cast (for streaming)."),
 "Details_TinyThreat": ("Details", "Compteur de menace (doublon de Naowh : Combat).", "Threat meter (duplicate of Naowh: Combat)."),
 "Details_Vanguard": ("Details", "Vie et debuffs des tanks du groupe.", "Health and debuffs of the group's tanks."),
 "DBM-StatusBarTimers": ("DBM-Core", "Les barres de minuteurs de DBM : obligatoire.", "DBM's timer bars: required."),
 "DBM-GUI": ("DBM-Core", "La fenêtre des options de DBM (/dbm).", "DBM's options window (/dbm)."),
 "DBM-Party-Forever": ("DBM-Core", "Les donjons propres à WoW Forever.", "Dungeons specific to WoW Forever."),
 "DBM-Party-Vanilla": ("DBM-Core", "Les donjons classiques.", "Classic dungeons."),
 "DBM-Raids-Vanilla": ("DBM-Core", "Les raids classiques (Cœur du Magma, Onyxia…).", "Classic raids (Molten Core, Onyxia…)."),
 "DBM-Azeroth": ("DBM-Core", "Les boss du monde.", "World bosses."),
 "DBM-VPVEM": ("DBM-Core", "Pack de voix pour les alertes DBM (en anglais).", "Voice pack for DBM alerts (English)."),
 "GearQuestForever_Languages": ("GearQuestForever", "Met GearQuest en français : à garder activé.", "Translates GearQuest to French: keep enabled."),
 "QuestieDB": ("Questie", "La base de données de Questie : obligatoire.", "Questie's database: required."),
 "QuestieTrace": ("Questie", "Collecte de données pour Questie (facultatif).", "Data collection for Questie (optional)."),
}
# Règles par préfixe pour les dossiers non listés ci-dessus
R = [
 ("DBM-Party-", "DBM-Core", "Modules DBM des donjons d'autres extensions : périmés sur Forever, peuvent rester désactivés.", "DBM modules for dungeons of other expansions: out of date on Forever, can stay disabled."),
 ("DBM-Raids-", "DBM-Core", "Modules DBM des raids d'autres extensions : périmés sur Forever, peuvent rester désactivés.", "DBM modules for raids of other expansions: out of date on Forever, can stay disabled."),
 ("DBM-Delves-", "DBM-Core", "Modules DBM des gouffres (Delves) : n'existent pas sur Forever, peuvent rester désactivés.", "DBM modules for Delves: not on Forever, can stay disabled."),
 ("DBM-Lairs-", "DBM-Core", "Modules DBM d'antres d'une autre extension : périmés sur Forever, peuvent rester désactivés.", "DBM modules for lairs of another expansion: out of date on Forever, can stay disabled."),
 ("DBM-", "DBM-Core", "Module DBM d'une autre extension ou d'un mode de jeu : peu utile sur Forever, peut rester désactivé.", "DBM module for another expansion or game mode: little use on Forever, can stay disabled."),
 ("GearQuestForever_", "GearQuestForever", "Données d'une classe : seule celle de ton perso sert.", "Data for one class: only your character's class is used."),
 ("Spoken", "Spoken", "Module ou voix de Spoken.", "Spoken module or voice pack."),
 ("Details_", "Details", "Extension de Details.", "Details plugin."),
 ("NaowhForever_", "NaowhForever", "Module de Naowh Forever.", "Naowh Forever module."),
]
# Doublons connus entre fiches (paires symétriques, avec explication)
DOUBLONS = [
 {"entre": ["BetterFishing", "FishyWashy"], "fr": "Deux aides à la pêche : en garder une seule activée.", "en": "Two fishing helpers: keep only one enabled."},
 {"entre": ["RXPGuides", "ZygorGuidesViewerForever"], "fr": "Deux guides de leveling : un seul à la fois.", "en": "Two leveling guides: only one at a time."},
 {"entre": ["ForeverDungeonJournal", "NaowhForever_DungeonJournal"], "fr": "Même journal de donjons ; DungeonJournal est désactivé exprès.", "en": "Same dungeon journal; DungeonJournal is disabled on purpose."},
 {"entre": ["WhatsTraining", "NaowhForever_Training"], "fr": "Même liste de sorts à apprendre ; What's Training est désactivé exprès.", "en": "Same list of spells to learn; What's Training is disabled on purpose."},
 {"entre": ["Details_TinyThreat", "NaowhForever_Combat"], "fr": "Deux compteurs de menace.", "en": "Two threat meters."},
 {"entre": ["Auctionator", "NaowhForever_Market"], "fr": "Deux aides à la vente à l'HV : l'un ou l'autre suffit.", "en": "Two AH selling helpers: either is enough."},
 {"entre": ["ForeverClassGuide", "NaowhForever_Training"], "fr": "Se recoupent en partie (quoi apprendre, talents).", "en": "Partly overlap (what to learn, talents)."},
 {"entre": ["ForeverSecrets", "NaowhForever_Discovery"], "fr": "Les livres de bibliothèque sont dans les deux.", "en": "Library books are in both."},
]
# Profils prêts (add-ons principaux ; les modules suivent leur principal, les dépendances sont activées par la règle S1.38)
P = {
 "leveling": ("Leveling", "Leveling", "📈", "#4CAF50",
   ["NaowhForever","Questie","RXPGuides","TomTom","OpenMap","GearQuestForever","DialogueUI","Spoken","Baganator","Syndicator","Pawn","RareScanner","MinimapButtonButton","OPie"],
   "Un seul guide de leveling (RestedXP) ; Zygor reste éteint.", "A single leveling guide (RestedXP); Zygor stays off."),
 "donjon": ("Donjon", "Dungeon", "🛡️", "#2196F3",
   ["NaowhForever","DBM-Core","Details","GTFO","Plater","Baganator","Syndicator","Pawn","DialogueUI","MinimapButtonButton","OPie"],
   "DBM et Details avec leurs modules utiles ; pas de guide de leveling.", "DBM and Details with their useful modules; no leveling guide."),
 "peche": ("Pêche", "Fishing", "🎣", "#00BCD4",
   ["NaowhForever","FishyWashy","Baganator","Syndicator","Auctionator","TomTom","OpenMap","MinimapButtonButton"],
   "Une seule aide à la pêche (FishyWashy) ; BetterFishing reste éteint.", "A single fishing helper (FishyWashy); BetterFishing stays off."),
 "minimal": ("Minimal", "Minimal", "🪶", "#9E9E9E",
   ["NaowhForever","Baganator","Syndicator","DBM-Core","Questie","MinimapButtonButton"],
   "Le strict nécessaire pour jouer léger.", "The bare minimum for a light setup."),
}

def toc_info(d):
    p = os.path.join(ADDONS, d, d + ".toc")
    info = {"icone": None, "dependances": [], "titre_toc": None}
    if not os.path.isfile(p): return info
    for line in open(p, encoding="utf-8", errors="replace"):
        m = re.match(r"##\s*([\w-]+):\s*(.*)", line.strip())
        if not m: continue
        k, v = m.group(1).lower(), m.group(2).strip()
        if k == "icontexture" and not info["icone"]: info["icone"] = v
        elif k == "title" and not info["titre_toc"]:
            info["titre_toc"] = re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", v)
        elif k in ("dependencies", "requireddeps", "reqdeps"):
            info["dependances"] += [x.strip() for x in v.split(",") if x.strip()]
    return info

installed = sorted(x for x in os.listdir(ADDONS) if os.path.isdir(os.path.join(ADDONS, x)))
fiches = {}
for d in installed:
    t = toc_info(d)
    if d in A:
        e = dict(A[d]); e["type"] = "principal"
    elif d in M:
        par, fr, en = M[d]; pa = A[par]
        e = dict(type="module", parent=par, categories=pa["categories"], curseforge=pa["curseforge"], confiance=pa["confiance"],
                 utilite=pa["utilite"], fr=dict(resume=fr, commandes="", remarques=""), en=dict(resume=en, commandes="", remarques=""),
                 doublons=[], note_lien=pa["note_lien"])
        if d in ("SpokenContributions", "QuestieTrace", "Details_Streamer", "NaowhForever_SearchIndex"): e["utilite"] = "gadget"
        if d in ("DBM-GUI",) : e["utilite"] = "indispensable"
    else:
        r = next((x for x in R if d.startswith(x[0])), None)
        if not r: continue
        pa = A[r[1]]
        e = dict(type="module", parent=r[1], categories=["dbm"] if r[1] == "DBM-Core" else pa["categories"], curseforge=pa["curseforge"],
                 confiance=pa["confiance"], utilite="gadget", fr=dict(resume=r[2], commandes="", remarques=""),
                 en=dict(resume=r[3], commandes="", remarques=""), doublons=[], note_lien=pa["note_lien"])
    e.update(icone=t["icone"], dependances=t["dependances"], titre_toc=t["titre_toc"], verifie=DATE)
    fiches[d] = e

json.dump(dict(version=1, langues=["fr", "en"], genere=DATE, fiches=fiches), open(os.path.join(OUT, "fiches.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump(dict(version=1, source="Catégories de CurseForge (liste vérifiée par Perplexity le 15/11/2026) + catégories lues dans les .toc",
               categories={k: dict(fr=v[0], en=v[1], source=v[2]) for k, v in CATEGORIES.items()}),
          open(os.path.join(OUT, "categories.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump(dict(version=1, doublons=DOUBLONS), open(os.path.join(OUT, "doublons.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
prof = {}
for k, (fr, en, ic, col, lst, nf, ne) in P.items():
    prof[k] = dict(nom=dict(fr=fr, en=en), icone=ic, couleur=col, addons=lst, avec_modules=True, note=dict(fr=nf, en=ne))
json.dump(dict(version=1, profils=prof, remarque="addons = dossiers principaux ; l'outil de profils ne garde que ceux réellement installés."),
          open(os.path.join(OUT, "profils.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(fiches), "fiches;", sum(1 for x in installed if x not in fiches), "sans fiche")
