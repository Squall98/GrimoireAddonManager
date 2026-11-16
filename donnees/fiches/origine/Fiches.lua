-- Fiches Add-ons : LES FICHES (données seulement, pas de code).
--
-- Une fiche par DOSSIER d'add-on (le nom du dossier dans Interface\AddOns,
-- affiché en gris sous le titre dans l'infobulle).
--   resume    = à quoi il sert (1-2 lignes)
--   commandes = ses commandes (facultatif)
--   remarques = doublons, pièges, conseils (facultatif)
-- Pour ajouter une fiche : copier un bloc, changer le nom entre [" "], /reload.
-- Rédigées le 14/11/2026 pour WoW Forever 1.60.1.
local _, ns = ...

ns.Fiches = {
	["Auctionator"] = {
		resume    = "Hôtel des ventes plus rapide : recherche par liste, prix du marché, vente en un clic, annulation facile.",
		commandes = "/atr (ou /auctionator)",
		remarques = "Recoupe en partie Naowh Forever : The Market (vente à l'HV). L'un ou l'autre suffit.",
	},
	["Baganator"] = {
		resume    = "Sacs réunis en un seul, rangés par catégories, avec recherche ; voit aussi les sacs et la banque de tes autres persos.",
		commandes = "/bgr (ou /baganator), /bgrs <mot> pour chercher",
		remarques = "Va avec Syndicator (garder les deux activés).",
	},
	["Syndicator"] = {
		resume    = "Mémorise les objets de tous tes persos (sacs, banque, courrier) ; sert à Baganator et à d'autres add-ons.",
		commandes = "/syn, /syns <mot> pour chercher un objet sur tous tes persos",
		remarques = "Ne rien faire de spécial : laisser activé avec Baganator.",
	},
	["BetterFishing"] = {
		resume    = "Pêche avec une seule touche ou un double-clic, et son du bouchon plus fort.",
		commandes = "/bf (ou /betterfishing)",
		remarques = "Doublon de FishyWashy : en garder un seul activé.",
	},
	["FishyWashy"] = {
		resume    = "Aide à la pêche : bouchon plus bruyant, boutons d'appâts, lancer facile, statistiques de pêche.",
		commandes = "/fishy",
		remarques = "Doublon de BetterFishing : en garder un seul activé.",
	},
	["Curator"] = {
		resume    = "Mini-jeu de cartes à collectionner sur les créatures d'Azeroth : ouvre des boosters, remplis ton album zone par zone, montre-le.",
		commandes = "/curator",
		remarques = "Purement pour le plaisir, rien d'indispensable.",
	},
	["DBM-Core"] = {
		resume    = "Deadly Boss Mods : alertes et minuteurs pendant les combats de boss (donjons, raids).",
		commandes = "/dbm (options), /pull <secondes>, /break <minutes>, /range",
		remarques = "Les ~20 dossiers DBM-* sont ses modules. Seuls ceux marqués Forever ou Vanilla servent ici ; les autres (Midnight, BC, WotLK, MoP…) restent « périmés » et peuvent rester désactivés.",
	},
	["Details"] = {
		resume    = "Compteur de dégâts et de soins (DPS/HPS), avec le détail de chaque sort et de chaque combat.",
		commandes = "/details",
		remarques = "Les dossiers Details_* sont ses extensions. Details_TinyThreat fait doublon avec le compteur de menace de Naowh Forever : Combat.",
	},
	["DialogueUI"] = {
		resume    = "Remplace la fenêtre des quêtes et des discussions par une interface façon jeu moderne, plus lisible, jouable au clavier.",
		commandes = "Réglages : Échap > Options > AddOns",
		remarques = "Compatible avec Spoken (les voix FR continuent).",
	},
	["ForeverClassGuide"] = {
		resume    = "ForeverGuide : guide de ta classe (talents, sorts du maître, nourriture à buff, campement, métiers, Héritage).",
		commandes = "/fg (ou /foreverguide)",
		remarques = "Recoupe en partie Naowh Forever : Training Planner (quoi apprendre, talents).",
	},
	["ForeverDungeonJournal"] = {
		resume    = "DungeonJournal : boss, butin et quêtes des donjons.",
		commandes = "/dj",
		remarques = "DÉSACTIVÉ exprès : doublon de Naowh Forever : Dungeon Journal.",
	},
	["ForeverLootSparkles"] = {
		resume    = "Fait toujours briller les objets de quête à ramasser (le jeu coupe parfois cet effet).",
		commandes = "Réglages : Échap > Options > AddOns",
	},
	["ForeverSecrets"] = {
		resume    = "Quêtes cachées, livres de bibliothèque et secrets de WoW Forever, avec coordonnées, captures et suivi par perso.",
		commandes = "/fsecret (secrets), /fbooks (livres)",
		remarques = "Les livres recoupent Naowh Forever : Discovery.",
	},
	["GearQuestForever"] = {
		resume    = "Améliorations d'équipement pendant le leveling : clique un emplacement, choisis l'objet à aller chercher, suis-le dans le journal.",
		commandes = "/gq (ou /gearquest)",
		remarques = "Les dossiers GearQuestForever_<CLASSE> sont ses données ; GearQuestForever_Languages le met en français.",
	},
	["GTFO"] = {
		resume    = "Son d'alerte quand tu restes dans quelque chose qui fait mal (feu, poison…) : « sors de là ! ».",
		commandes = "/gtfo",
	},
	["MinimapButtonButton"] = {
		resume    = "Range tous les boutons de la minicarte dans un seul bouton.",
		commandes = "Clique son bouton près de la minicarte",
	},
	["NaowhForever"] = {
		resume    = "Le « tout-en-un » de Forever : une fenêtre commune pour ses 15 modules (BiS, donjons, quoi apprendre, métiers, HV, combat, confort…).",
		commandes = "/nf (ou /nao, /naowh), /nfquests (quêtes et rares par zone)",
		remarques = "Remplace DungeonJournal et What's Training (désactivés). Chaque module s'allume dans /nf > Réglages > Modules.",
	},
	["OPie"] = {
		resume    = "Roues d'actions : tu maintiens une touche, une roue de sorts/objets/montures apparaît, tu choisis à la souris.",
		commandes = "/opie",
	},
	["OpenMap"] = {
		resume    = "Carte du monde d'un seul tenant : toutes les zones collées, on zoome de l'une à l'autre.",
		commandes = "/openmap",
		remarques = "La carte de Blizzard, le journal de quêtes et Questie continuent de marcher.",
	},
	["Pawn"] = {
		resume    = "Compare les objets et marque les améliorations (flèche verte) selon les stats de ta spé.",
		commandes = "/pawn",
		remarques = "Recoupe un peu GearQuest et Naowh : BiS List ; ensemble, ça ne gêne pas.",
	},
	["Plater"] = {
		resume    = "Barres de vie au-dessus des ennemis (nameplates) très réglables : menace, sorts lancés, debuffs.",
		commandes = "/plater",
	},
	["Questie"] = {
		resume    = "Affiche sur la carte et la minicarte les quêtes disponibles, leurs objectifs et où les rendre.",
		commandes = "/questie",
		remarques = "QuestieDB (sa base) et QuestieTrace (collecte de données) vont avec.",
	},
	["RXPGuides"] = {
		resume    = "RestedXP : guide de leveling pas à pas, avec flèche et étapes.",
		commandes = "/rxp",
		remarques = "Fait doublon avec Zygor : n'activer qu'un seul guide de leveling à la fois.",
	},
	["RareScanner"] = {
		resume    = "Prévient (son + bouton avec image) quand un monstre rare, un trésor ou un évènement apparaît sur ta minicarte.",
		commandes = "/rs (ou /rarescanner)",
	},
	["Spoken"] = {
		resume    = "Lit le jeu à voix haute (en français) : quêtes, discussions, lieux, livres, histoires des boss. Une file, un narrateur, un bouton.",
		commandes = "/sp (ou /spoken), /spp (lieux), /spr (livres et lettres)",
		remarques = "Les dossiers Spoken_* et Spoken*Audio_frFR sont ses modules et ses voix FR. Normal que les packs de voix paraissent « désactivés » ou « périmés ».",
	},
	["SpokenBooks"] = {
		resume    = "Ancien add-on, maintenant intégré à Spoken.",
		remarques = "Ce dossier ne se charge jamais : il peut partir à la corbeille (_a-supprimer).",
	},
	["TomTom"] = {
		resume    = "Flèche de navigation vers des coordonnées (points de passage).",
		commandes = "/way <x> <y> (ex. /way 45 60), /cway (point le plus proche), /wayb (retour)",
	},
	["Warmth"] = {
		resume    = "Feux de camp des joueurs sur ta carte : ce que propose chaque campement, qui est autour, et monter le tien.",
		commandes = "/warmth",
	},
	["WhatsTraining"] = {
		resume    = "What's Training : liste des sorts disponibles chez ton maître de classe.",
		commandes = "/wt",
		remarques = "DÉSACTIVÉ exprès : doublon de Naowh Forever : Training Planner.",
	},
	["ZephrasCollector"] = {
		resume    = "Envoie ce que tu découvres (PNJ, quêtes, butin) au site zephras.com ; Ctrl+C sur un objet donne son lien.",
		commandes = "/zephras",
		remarques = "Facultatif : utile seulement si tu te sers du site Zephras.",
	},
	["ZygorGuidesViewerForever"] = {
		resume    = "Zygor : guide de leveling (version gratuite Forever), avec flèche et étapes.",
		commandes = "Bouton de la minicarte",
		remarques = "Fait doublon avec RestedXP : n'activer qu'un seul guide de leveling à la fois.",
	},
	["FichesAddons"] = {
		resume    = "Cet add-on : la fiche en français que tu lis en ce moment, plus ta note perso.",
		commandes = "/fiche (aide), /fiche <dossier> <texte> (ta note)",
		remarques = "Les fiches se modifient dans Interface\\AddOns\\FichesAddons\\Fiches.lua, puis /reload.",
	},
}

-- Sous-modules : rattachés à la fiche de l'add-on principal.
-- La fiche du dossier exact passe toujours en premier ; sinon le premier préfixe qui colle.
--   note = une ligne commune à tous les modules de ce préfixe (facultatif)
ns.Regroupements = {
	{ prefixe = "DBM-",              principal = "DBM-Core" },
	{ prefixe = "NaowhForever_",     principal = "NaowhForever" },
	{ prefixe = "Details_",          principal = "Details" },
	{ prefixe = "GearQuestForever_", principal = "GearQuestForever",
	  note = "Données d'une classe : seule celle de ton perso sert." },
	{ prefixe = "Spoken",            principal = "Spoken" },
	{ prefixe = "Questie",           principal = "Questie" },
	{ prefixe = "OPie_",             principal = "OPie" },
}

-- Une ligne propre à un sous-module (affichée au-dessus de la fiche du principal).
ns.Modules = {
	-- Naowh Forever
	["NaowhForever_AuctionData"]   = "Prix de tous les hôtels des ventes (données, chargées toutes seules).",
	["NaowhForever_BiS"]           = "Listes BiS, poids de stats, Gear Score, fenêtre du perso et d'inspection.",
	["NaowhForever_Combat"]        = "Barre de consommables, swing timer, menace, PvP, debuffs de raid, bénédictions… (un interrupteur chacun).",
	["NaowhForever_Discovery"]     = "Livres de bibliothèque, Sac de couchage douillet, quêtes et rares par zone (/nfquests).",
	["NaowhForever_DiscoveryData"] = "Données des quêtes et rares (chargées toutes seules).",
	["NaowhForever_DungeonJournal"] = "Boss, butin et quêtes de chaque donjon (remplace DungeonJournal).",
	["NaowhForever_JourneysData"]  = "Données des trajets à pied de Journeys (chargées toutes seules).",
	["NaowhForever_Locales"]       = "Traduction française de Naowh : à garder activé.",
	["NaowhForever_Market"]        = "Panneau à côté de l'HV pour vendre tes sacs, plus une fenêtre farm / composants / prix.",
	["NaowhForever_Professions"]   = "Recettes, composants et artisanat dans une fenêtre, avec les recettes pas encore apprises.",
	["NaowhForever_QoL"]           = "Petits conforts de jeu (/copy pour copier un texte, /nfaim…).",
	["NaowhForever_SearchIndex"]   = "Permet à la recherche des réglages de trouver les options des modules éteints.",
	["NaowhForever_Training"]      = "Quoi apprendre maintenant et jusqu'au 60, builds de talents (remplace What's Training).",
	["NaowhForever_Utilities"]     = "Suivi d'instances, Journeys, macros, inspection et recherche de groupe, barres d'action… (un interrupteur chacun).",
	-- Spoken
	["Spoken_Quests"]              = "Lit les quêtes et les discussions.",
	["Spoken_Places"]              = "Lit l'histoire des zones sur la carte (/spp).",
	["Spoken_Readables"]           = "Lit les livres, lettres, notes et plaques (/spr).",
	["Spoken_Bosses"]              = "Histoires des boss des donjons et raids (Compendium d'Azeroth).",
	["SpokenQuestsAudioHorde_frFR"]    = "Voix françaises des quêtes Horde.",
	["SpokenQuestsAudioAlliance_frFR"] = "Voix françaises des quêtes Alliance (inutile pour un perso Horde, mais sans gêne).",
	["SpokenQuestsAudioShared_frFR"]   = "Voix françaises des quêtes communes aux deux factions.",
	["SpokenQuestsAudioGossip_frFR"]   = "Voix françaises des discussions avec les PNJ.",
	["SpokenZonesAudio_frFR"]      = "Voix françaises de l'histoire des zones (bêta).",
	["SpokenBooksAudio_frFR"]      = "Voix françaises des livres et lettres.",
	["SpokenBossesAudio_frFR"]     = "Voix françaises des histoires des boss : à garder activé.",
	["SpokenContributions"]        = "Garde les répliques récoltées pour les envoyer à spoken.quest/contribute (facultatif).",
	-- Details
	["Details_Compare2"]           = "Nouvel onglet Comparer dans le détail d'un joueur.",
	["Details_DataStorage"]        = "Stockage des données de Details (à garder).",
	["Details_EncounterDetails"]   = "Analyse détaillée d'un combat de boss (phases, graphiques).",
	["Details_RaidCheck"]          = "Talents, niveau d'objets, nourriture et flacons du groupe.",
	["Details_Streamer"]           = "Affiche les sorts que tu lances (pour le streaming).",
	["Details_TinyThreat"]         = "Compteur de menace (doublon de Naowh : Combat).",
	["Details_Vanguard"]           = "Vie et debuffs des tanks du groupe.",
	-- DBM
	["DBM-StatusBarTimers"]        = "Les barres de minuteurs de DBM : obligatoire.",
	["DBM-GUI"]                    = "La fenêtre des options de DBM (/dbm).",
	["DBM-Party-Forever"]          = "Les donjons propres à WoW Forever.",
	["DBM-Party-Vanilla"]          = "Les donjons classiques.",
	["DBM-Raids-Vanilla"]          = "Les raids classiques (Cœur du Magma, Onyxia…).",
	["DBM-Azeroth"]                = "Les boss du monde.",
	["DBM-VPVEM"]                  = "Pack de voix pour les alertes DBM (en anglais).",
	-- GearQuest
	["GearQuestForever_Languages"] = "Met GearQuest en français : à garder activé.",
	-- Questie
	["QuestieDB"]                  = "La base de données de Questie : obligatoire.",
	["QuestieTrace"]               = "Collecte de données pour Questie (facultatif).",
}
