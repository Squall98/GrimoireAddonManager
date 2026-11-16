-- Profils : appliquer, verrous, dépendances, profils prêts, incomplet, fusion, comparer, copier/coller, sauvegarde,
-- proposition selon la situation, fenêtre des profils et commandes (B3-01).
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function demarrer(B, opts)
	opts = opts or {}
	opts.addons_actifs = opts.addons_actifs or {}
	return B.demarrer(opts)
end

local function actifs(ns)
	local t = {}
	for _, e in ipairs(ns.Liste.entrees()) do
		if ns.Liste.actif(e.nom) then t[e.nom] = true end
	end
	return t
end

local function compte(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

local function contient(liste, nom)
	for _, n in ipairs(liste) do if n == nom then return true end end
	return false
end

local function profil(ns, texte)
	local p = ns.Profils.trouver(texte)
	T.vrai(p, "profil introuvable : " .. texte)
	return p
end

T.test("profils prêts : Leveling, Donjon, Pêche, Minimal, seulement avec des add-ons installés", function(B)
	local ns = demarrer(B)
	T.eq(ns.Profils.nombre(), 4)
	for _, id in ipairs({ "leveling", "donjon", "peche", "minimal" }) do
		local p = ns.Profils.obtenir(id)
		T.vrai(p, id)
		T.faux(ns.Profils.incomplet(p), id .. " ne cite que des add-ons installés")
		T.vrai(#p.addons > 0, id .. " a du contenu")
		for _, nom in ipairs(p.addons) do T.vrai(ns.Liste.parNom(nom), nom .. " installé") end
	end
	T.eq(ns.Profils.nom(ns.Profils.obtenir("donjon")), "Donjon")
	-- « Tout » et « Rien » sont toujours là, devant
	local tous = ns.Profils.tous()
	T.eq(ns.Profils.nom(tous[1]), "Tout")
	T.eq(ns.Profils.nom(tous[2]), "Rien")
	T.sans_erreur()
end)

T.test("les profils prêts changent de langue avec le jeu", function(B)
	local ns = demarrer(B, { locale = "enUS" })
	T.eq(ns.Profils.nom(ns.Profils.obtenir("donjon")), "Dungeon")
	T.eq(ns.Profils.nom(ns.Profils.tous()[2]), "None")
	T.vrai(ns.Profils.trouver("donjon"), "le nom français se retrouve aussi")
	T.vrai(ns.Profils.trouver("Dungeon"), "et l'anglais")
end)

T.test("appliquer Donjon puis recharger donne exactement les add-ons du profil", function(B)
	local ns = demarrer(B)
	local p = profil(ns, "Donjon")
	local contenu = ns.Profils.contenu(p)
	local a, touches = ns.Profils.appliquer(p, "perso")
	T.eq(touches, 1)
	T.sans_erreur()
	T.vrai(#a.moins > 0, "des add-ons sont coupés")
	-- en attente : le jeu n'a pas encore rechargé
	T.eq((ns.Liste.enAttente()), #a.plus + #a.moins)
	-- recharger : l'état est gardé, c'est exactement le contenu du profil (+ ce gestionnaire)
	ns = B.recharger()
	local on = actifs(ns)
	for nom in pairs(contenu.set) do T.vrai(on[nom], nom .. " doit être actif") end
	T.eq(compte(on), #contenu.ordre + 1, "rien d'autre n'est actif (sauf Mes Add-ons)")
	T.vrai(on["MesAddons"], "ce gestionnaire reste")
	T.vrai(on["DBM-Core"] and on["Details"], "DBM et Details")
	T.faux(on["Questie"], "Questie coupé")
	T.faux(on["RXPGuides"], "le guide de leveling coupé")
	T.eq((ns.Liste.enAttente()), 0, "plus rien en attente après le rechargement")
	T.eq(ns.Profils.actuel().id, "donjon", "le profil appliqué est retenu")
	T.faux(ns.Profils.actuelModifie())
end)

T.test("un profil appliqué est une seule entrée d'historique : Annuler revient en arrière", function(B)
	local ns = demarrer(B)
	local avant = actifs(ns)
	ns.Profils.appliquer(profil(ns, "Minimal"), "perso")
	T.eq(ns.Liste.nombreAnnulations(), 1)
	T.vrai(compte(actifs(ns)) < compte(avant))
	ns.Liste.annuler()
	T.eq(compte(actifs(ns)), compte(avant))
end)

T.test("« Rien » coupe tout sauf ce gestionnaire et les verrous ; « Tout » rallume ce qui est prévu pour Forever", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("Questie", true)
	T.vrai(ns.Profils.verrou("Questie"))
	local a = ns.Profils.apercu(ns.Profils.tous()[2])
	T.vrai(contient(a.gardes, "Questie"), "le verrou est annoncé dans l'aperçu")
	T.faux(contient(a.moins, "Questie"))
	ns.Profils.appliquer(ns.Profils.tous()[2], "perso")
	local on = actifs(ns)
	T.eq(compte(on), 2, "ce gestionnaire et Questie")
	T.vrai(on["MesAddons"] and on["Questie"])
	ns.Profils.appliquer(ns.Profils.tous()[1], "perso")
	on = actifs(ns)
	for _, e in ipairs(ns.Liste.entrees()) do
		if not e.inutile then T.vrai(on[e.nom], e.nom .. " rallumé") end
	end
	T.sans_erreur()
end)

T.test("un verrou n'est jamais coupé par un profil (même le profil Minimal)", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("Pawn", true)
	ns.Profils.appliquer(profil(ns, "Minimal"), "perso")
	T.vrai(ns.Liste.actif("Pawn"), "Pawn reste allumé")
	ns.Profils.basculerVerrou("Pawn", false)
	T.faux(ns.Profils.verrou("Pawn"))
	ns.Profils.appliquer(profil(ns, "Minimal"), "perso")
	T.faux(ns.Liste.actif("Pawn"), "sans verrou, il est coupé")
end)

T.test("dépendances automatiques : Baganator active Syndicator, et un manque est signalé", function(B)
	local ns = demarrer(B)
	local p = ns.Profils.creer("Sacs", { addons = { "Baganator" }, modules = false })
	T.vrai(p)
	local a = ns.Profils.apercu(p)
	T.faux(contient(a.deps, "Syndicator"), "par défaut, une dépendance facultative n'est pas ajoutée")
	ns.Reglages.ecrire("profils.dependances_facultatives", true)
	a = ns.Profils.apercu(p)
	T.vrai(contient(a.deps, "Syndicator"), "Syndicator ajouté pour la dépendance")
	ns.Profils.appliquer(p, "perso")
	T.vrai(ns.Liste.actif("Baganator") and ns.Liste.actif("Syndicator"), "les deux sont actifs")
	-- le réglage coupe l'ajout
	ns.Reglages.ecrire("profils.dependances_facultatives", false)
	a = ns.Profils.apercu(p)
	T.faux(contient(a.deps, "Syndicator"), "plus d'ajout automatique")
	ns.Reglages.ecrire("profils.dependances_auto", false)
	T.eq(#ns.Profils.apercu(p).deps, 0)
end)

T.test("une dépendance requise introuvable est signalée dans l'aperçu", function(B)
	local ns = demarrer(B)
	local e = ns.Liste.parNom("DBM-GUI") or ns.Liste.parNom("DBM-Core")
	local vrai_dep = C_AddOns.GetAddOnDependencies
	C_AddOns.GetAddOnDependencies = function(nom)
		if nom == "Pawn" then return "AddOnFantome" end
		return vrai_dep(nom)
	end
	local p = ns.Profils.creer("Avec Pawn", { addons = { "Pawn" }, modules = false })
	local a = ns.Profils.apercu(p)
	T.eq(#a.deps_absentes, 1)
	T.eq(a.deps_absentes[1].dep, "AddOnFantome")
	T.eq(a.deps_absentes[1].addon, "Pawn")
	B.chat = {}
	B.slash("/maa profil Avec Pawn")
	T.vrai(B.chat_contient("Dépendance manquante : AddOnFantome"), "l'alerte est dite dans le chat")
	C_AddOns.GetAddOnDependencies = vrai_dep
	T.vrai(e)
end)

T.test("profil incomplet : un add-on désinstallé est signalé, puis retiré", function(B)
	local ns = demarrer(B)
	local p = ns.Profils.creer("Vieux", { addons = { "Questie", "AddOnDesinstalle", "Pawn" }, modules = false })
	T.vrai(ns.Profils.incomplet(p))
	T.eq(ns.Profils.absents(p)[1], "AddOnDesinstalle")
	local a = ns.Profils.apercu(p)
	T.eq(a.absents[1], "AddOnDesinstalle")
	T.eq(ns.Profils.retirerAbsents(p), 1)
	T.faux(ns.Profils.incomplet(p))
	T.eq(#p.addons, 2)
end)

T.test("fusion : le profil s'ajoute à l'actuel sans rien couper", function(B)
	local ns = demarrer(B)
	ns.Profils.appliquer(ns.Profils.tous()[2], "perso") -- Rien
	local avant = actifs(ns)
	local p = profil(ns, "Pêche")
	local a = ns.Profils.apercu(p, "fusion")
	T.eq(#a.moins, 0, "fusion = aucun add-on coupé")
	ns.Profils.appliquer(p, "perso", "fusion")
	local apres = actifs(ns)
	for nom in pairs(avant) do T.vrai(apres[nom], nom .. " reste") end
	T.vrai(compte(apres) > compte(avant), "des add-ons de plus")
	-- fusionner un deuxième profil garde le premier
	ns.Profils.appliquer(profil(ns, "Donjon"), "perso", "fusion")
	T.vrai(actifs(ns)["DBM-Core"])
	for nom in pairs(apres) do T.vrai(actifs(ns)[nom]) end
end)

T.test("comparer deux profils : seulement dans l'un, seulement dans l'autre, en commun", function(B)
	local ns = demarrer(B)
	local d = ns.Profils.comparer(profil(ns, "Leveling"), profil(ns, "Donjon"))
	T.vrai(contient(d.seulA, "Questie"), "Questie seulement en Leveling")
	T.vrai(contient(d.seulB, "DBM-Core"), "DBM seulement en Donjon")
	T.vrai(contient(d.commun, "Baganator"), "Baganator dans les deux")
	T.faux(contient(d.seulA, "Baganator") or contient(d.seulB, "Baganator"))
	local m = ns.Profils.comparer(profil(ns, "Minimal"), profil(ns, "Minimal"))
	T.eq(#m.seulA + #m.seulB, 0, "un profil et lui-même : aucune différence")
end)

T.test("icône et couleur par profil, renommer (nom unique), supprimer", function(B)
	local ns = demarrer(B)
	local p = ns.Profils.creer("Mon profil")
	local icone, couleur = p.icone, p.couleur
	ns.Profils.changerIcone(p, 1)
	ns.Profils.changerCouleur(p, 1)
	T.vrai(p.icone ~= icone and p.couleur ~= couleur)
	local q = ns.Profils.creer("Mon profil")
	T.eq(ns.Profils.nom(q), "Mon profil (2)", "un nom déjà pris reçoit un numéro")
	ns.Profils.renommer(q, "Donjon")
	T.eq(ns.Profils.nom(q), "Donjon (2)", "pareil pour un profil prêt")
	ns.Profils.renommer(q, "Tout")
	T.eq(ns.Profils.nom(q), "Tout (2)", "et pour Tout et Rien")
	T.faux(ns.Profils.renommer(ns.Profils.tous()[1], "x"), "Tout ne se renomme pas")
	T.faux(ns.Profils.supprimer(ns.Profils.tous()[2]), "Rien ne se supprime pas")
	T.vrai(ns.Profils.supprimer(q))
	T.faux(ns.Profils.trouver("Tout (2)") == q)
	T.eq(ns.Profils.nombre(), 5)
end)

T.test("les profils et les verrous sont gardés d'une session à l'autre", function(B)
	local ns = demarrer(B)
	local p = ns.Profils.creer("Garde", { addons = { "Pawn", "Questie" }, modules = false, couleur = "#FF0000" })
	ns.Profils.basculerVerrou("OPie", true)
	ns.Profils.appliquer(p, "perso")
	ns = B.recharger()
	local q = ns.Profils.trouver("Garde")
	T.vrai(q, "profil retrouvé")
	T.eq(q.couleur, "#FF0000")
	T.eq(#q.addons, 2)
	T.vrai(ns.Profils.verrou("OPie"))
	T.eq(ns.Profils.nombre(), 5, "les profils prêts ne sont pas recréés en double")
	T.eq(ns.Profils.actuel().id, q.id)
end)

T.test("profil copié en texte puis recollé : identique", function(B)
	local ns = demarrer(B)
	local p = ns.Profils.creer("Spécial ; = , : ~ %", { addons = { "Questie", "Pawn", "OPie" }, modules = true, couleur = "#12AB34",
		note = "Une note, avec ; des = signes" })
	local texte = ns.Profils.exporter(p)
	T.vrai(texte:find("^MAA1:P:"), "commence par l'entête")
	T.faux(texte:find("\n"), "une seule ligne : se colle dans un champ simple")
	local res = ns.Profils.importer(texte)
	T.vrai(res and res.profils == 1)
	local q = res.dernier
	T.vrai(q.id ~= p.id)
	T.eq(table.concat(q.addons, ","), table.concat(p.addons, ","))
	T.eq(q.couleur, p.couleur)
	T.eq(q.modules, p.modules)
	T.eq(ns.Profils.note(q), ns.Profils.note(p))
	T.eq(ns.Profils.nom(q), "Spécial ; = , : ~ % (2)", "le nom existant n'est pas écrasé")
	T.eq(ns.Profils.exporter(q):gsub("nom=[^;]*;", ""), ns.Profils.exporter(p):gsub("nom=[^;]*;", ""), "même contenu")
	-- n'importe quel mélange est refusé proprement
	local r, err = ns.Profils.importer("n'importe quoi")
	T.faux(r)
	T.eq(err, "profil.import_invalide")
	r, err = ns.Profils.importer("   ")
	T.eq(err, "profil.import_vide")
	r, err = ns.Profils.importer("MAA1:P:nom=;addons=A")
	T.eq(err, "profil.import_invalide", "sans nom")
	T.sans_erreur()
end)

T.test("sauvegarde complète : profils, verrous, notes, étiquettes, favoris retrouvés sur une installation neuve", function(B)
	local ns = demarrer(B)
	ns.Profils.creer("Mon donjon", { addons = { "DBM-Core", "Details" }, modules = true, couleur = "#00FF00" })
	ns.Profils.basculerVerrou("Pawn", true)
	ns.Reglages.compte.fiches = { textes = {}, notes = { Questie = "Ma note\nsur deux lignes ; avec = des signes" } }
	ns.Recherche.definirEtiquettes("Questie", { "leveling", "à tester" })
	ns.Recherche.basculerFavori("TomTom", true)
	local texte = ns.Profils.exporterTout()
	T.vrai(texte:find("^MAA1:S"), "entête de sauvegarde")
	-- installation neuve
	B.effacer_sauvegardes()
	ns = demarrer(B)
	T.eq(ns.Profils.nombre(), 4)
	T.faux(ns.Profils.verrou("Pawn"))
	local res = ns.Profils.importer(texte)
	T.vrai(res)
	T.eq(res.verrous, 1)
	T.eq(res.notes, 1)
	T.vrai(ns.Profils.verrou("Pawn"))
	T.vrai(ns.Profils.trouver("Mon donjon"))
	T.eq(ns.Reglages.compte.fiches.notes.Questie, "Ma note\nsur deux lignes ; avec = des signes")
	T.eq(ns.Recherche.texteEtiquettes("Questie"), "leveling, à tester")
	T.vrai(ns.Recherche.favori("TomTom"))
	-- recoller deux fois ne casse rien : les profils reçoivent un numéro
	ns.Profils.importer(texte)
	T.vrai(ns.Profils.trouver("Mon donjon (2)"))
	T.sans_erreur()
end)

T.test("tous les personnages : le profil s'applique aussi aux personnages déjà connus", function(B)
	local ns = demarrer(B)
	ns.Reglages.compte.personnages = ns.Reglages.compte.personnages or {}
	ns.Reglages.compte.personnages["Player-1-AUTRE"] = { nom = "Autre", royaume = "R", faction = "Horde", classe = "MAGE", vu = 1 }
	B.etat_perso["Player-1-AUTRE"] = {}
	T.eq(#ns.Profils.autresPersonnages(), 1)
	local p = profil(ns, "Minimal")
	local a, touches = ns.Profils.appliquer(p, "tous")
	T.eq(touches, 2)
	T.faux(C_AddOns.GetAddOnEnableState("Pawn", "Player-1-AUTRE") ~= 0, "Pawn coupé chez l autre personnage")
	T.vrai(C_AddOns.GetAddOnEnableState("Questie", "Player-1-AUTRE") ~= 0, "le contenu du profil reste actif chez lui")
	T.vrai(C_AddOns.GetAddOnEnableState("MesAddons", "Player-1-AUTRE") ~= 0, "ce gestionnaire aussi")
	-- au perso seul, l'autre personnage n'est pas touché
	B.etat_perso["Player-1-AUTRE"] = {}
	ns.Profils.appliquer(profil(ns, "Leveling"), "perso")
	T.vrai(C_AddOns.GetAddOnEnableState("DBM-Core", "Player-1-AUTRE") ~= 0, "inchangé")
end)

------------------------------------------------------------------ situation
local function entrer(B, ns, type_, id)
	B.instance_type = type_
	B.instance_id = id or 1
	B.evenement("PLAYER_ENTERING_WORLD", false, false)
	B.avancer(ns.Reglages.lire("profils.delai_proposition") + 1)
end

T.test("en entrant en donjon : le profil associé est proposé, jamais appliqué tout seul", function(B)
	local ns = demarrer(B)
	local avant = compte(actifs(ns))
	entrer(B, ns, "party", 33)
	T.vrai(ns.Situation.ouverte(), "proposition visible")
	T.vrai(ns.Situation.texte:GetText():find("Donjon", 1, true), "cite le profil")
	T.vrai(ns.Situation.texte:GetText():find("donjon", 1, true), "cite la situation")
	T.eq(compte(actifs(ns)), avant, "rien n'a changé tout seul")
	T.eq(B.rechargements, 0)
	-- refuser : rien ne change, et on ne repropose pas pour la même instance
	ns.Situation.non:Click()
	T.faux(ns.Situation.ouverte())
	entrer(B, ns, "party", 33)
	T.faux(ns.Situation.ouverte(), "pas deux fois pour la même instance")
	-- une autre instance : on repropose ; accepter applique le profil puis recharge
	entrer(B, ns, "party", 34)
	T.vrai(ns.Situation.ouverte())
	ns.Situation.oui:Click()
	T.faux(ns.Situation.ouverte())
	T.eq(B.rechargements, 1, "avec rechargement")
	T.vrai(ns.Liste.actif("DBM-Core") and not ns.Liste.actif("Questie"), "le profil Donjon est appliqué")
	-- déjà dans le bon état : plus de proposition
	entrer(B, ns, "party", 35)
	T.faux(ns.Situation.ouverte(), "déjà en Donjon")
	T.sans_erreur()
end)

T.test("raid : même profil par défaut ; champ de bataille : aucun profil associé au départ ; réglable", function(B)
	local ns = demarrer(B)
	entrer(B, ns, "raid", 1)
	T.vrai(ns.Situation.ouverte(), "raid")
	ns.Situation.non:Click()
	entrer(B, ns, "pvp", 2)
	T.faux(ns.Situation.ouverte(), "pas de profil pour le champ de bataille")
	ns.Reglages.ecrire("profils.situation.champ", "Pêche")
	entrer(B, ns, "pvp", 3)
	T.vrai(ns.Situation.ouverte(), "maintenant associé")
	T.vrai(ns.Situation.texte:GetText():find("Pêche", 1, true))
	T.vrai(ns.Situation.texte:GetText():find("champ de bataille", 1, true))
	ns.Situation.non:Click()
	entrer(B, ns, "arena", 4)
	T.vrai(ns.Situation.ouverte(), "l'arène compte comme un champ de bataille")
	ns.Situation.non:Click()
	-- coupée par le réglage
	ns.Reglages.ecrire("profils.proposer", false)
	entrer(B, ns, "raid", 5)
	T.faux(ns.Situation.ouverte(), "proposition coupée")
	-- hors instance : rien
	ns.Reglages.ecrire("profils.proposer", true)
	B.instance_type = nil
	B.evenement("PLAYER_ENTERING_WORLD", false, false)
	B.avancer(10)
	T.faux(ns.Situation.ouverte())
end)

T.test("pendant un combat, la proposition attend la fin du combat", function(B)
	local ns = demarrer(B)
	B.en_combat = true
	entrer(B, ns, "party", 50)
	T.faux(ns.Situation.cadre and ns.Situation.ouverte(), "pas de fenêtre en plein combat")
	B.en_combat = false
	B.evenement("PLAYER_REGEN_ENABLED")
	B.avancer(10)
	T.vrai(ns.Situation.ouverte(), "proposée dès que le combat finit")
end)

------------------------------------------------------------------ fenêtre et commandes
T.test("fenêtre des profils : liste, détail, confirmation +x / -y, application, recharger", function(B)
	local ns = demarrer(B)
	ns.Fenetre.ouvrir()
	T.vrai(ns.ProfilsUI.bouton, "bouton Profils dans l'en-tête de la fenêtre")
	ns.ProfilsUI.bouton:Click()
	T.vrai(ns.ProfilsUI.estOuvert())
	T.sans_erreur()
	-- 6 lignes : Tout, Rien et les 4 profils prêts
	local noms = {}
	for _, l in ipairs(ns.ProfilsUI.lignes) do
		if l:IsShown() then noms[#noms + 1] = l.nom:GetText() end
	end
	T.eq(#noms, 6)
	T.vrai(noms[1]:find("Tout", 1, true) and noms[3]:find("Leveling", 1, true))
	ns.ProfilsUI.choisir("donjon")
	T.vrai(ns.ProfilsUI.detail:GetText():find("Par rapport à maintenant", 1, true), "le détail dit ce qui change")
	T.eq(ns.ProfilsUI.champNom:GetText(), "Donjon")
	-- Appliquer : un bandeau demande de confirmer avec +x / -y
	ns.ProfilsUI.boutons.appliquer:Click()
	T.vrai(ns.ProfilsUI.confirmation:IsShown(), "confirmation demandée")
	local texte = ns.ProfilsUI.confirmation.texte:GetText()
	local a = ns.Profils.apercu(ns.Profils.obtenir("donjon"))
	T.vrai(texte:find("+" .. #a.plus .. " activés, -" .. #a.moins .. " désactivés", 1, true), texte)
	T.eq(ns.Liste.enAttente(), 0, "rien n'a bougé avant la confirmation")
	ns.ProfilsUI.confirmation.non:Click()
	T.faux(ns.ProfilsUI.confirmation:IsShown())
	T.eq(ns.Liste.enAttente(), 0)
	ns.ProfilsUI.boutons.appliquer:Click()
	ns.ProfilsUI.confirmation.oui:Click()
	T.eq(ns.Liste.enAttente(), #a.plus + #a.moins, "appliqué après confirmation")
	T.vrai(ns.ProfilsUI.boutonRecharger:IsShown(), "bouton Recharger visible")
	T.vrai(ns.ProfilsUI.lignes[4].nom:GetText():find(">", 1, true), "le profil en cours est marqué")
	ns.ProfilsUI.boutonRecharger:Click()
	T.eq(B.rechargements, 1)
	-- la fenêtre principale suit : bouton Profils indique le profil en cours
	T.vrai(ns.ProfilsUI.bouton.etiquette:GetText():find("Donjon", 1, true))
	T.sans_erreur()
end)

T.test("fenêtre des profils : sans confirmation (réglage), portée « tous », nouveau, renommer, supprimer", function(B)
	local ns = demarrer(B)
	ns.Reglages.ecrire("profils.confirmer", false)
	ns.ProfilsUI.ouvrir()
	ns.ProfilsUI.choisir("minimal")
	ns.ProfilsUI.boutons.appliquer:Click()
	T.faux(ns.ProfilsUI.confirmation:IsShown(), "pas de confirmation si on l'a coupée")
	T.vrai(ns.Liste.enAttente() > 0, "appliqué tout de suite")
	-- portée
	T.eq(ns.ProfilsUI.boutons.portee.etiquette:GetText(), "Ce personnage")
	ns.ProfilsUI.boutons.portee:Click()
	T.eq(ns.ProfilsUI.boutons.portee.etiquette:GetText(), "Tous les personnages")
	-- nouveau, depuis l'état actuel
	ns.ProfilsUI.champNom:SetText("Essai")
	ns.ProfilsUI.boutons.nouveau:Click()
	local p = ns.Profils.trouver("Essai")
	T.vrai(p, "profil créé")
	T.eq(ns.ProfilsUI.selection, p.id, "et choisi")
	T.eq(#p.addons, compte(actifs(ns)) - 1, "avec l'état actuel (sans ce gestionnaire)")
	-- renommer par le champ du nom
	ns.ProfilsUI.champNom:SetText("Nouveau nom")
	ns.ProfilsUI.champNom._scripts.OnEnterPressed(ns.ProfilsUI.champNom)
	T.eq(ns.Profils.nom(ns.Profils.obtenir(p.id)), "Nouveau nom")
	-- icône et couleur
	local icone, couleur = p.icone, p.couleur
	ns.ProfilsUI.icone:Click()
	ns.ProfilsUI.couleurBouton:Click()
	T.vrai(p.icone ~= icone and p.couleur ~= couleur)
	-- supprimer demande toujours confirmation
	ns.ProfilsUI.boutons.supprimer:Click()
	T.vrai(ns.ProfilsUI.confirmation:IsShown())
	T.vrai(ns.ProfilsUI.confirmation.texte:GetText():find("Nouveau nom", 1, true))
	T.vrai(ns.Profils.obtenir(p.id), "pas encore supprimé")
	ns.ProfilsUI.confirmation.oui:Click()
	T.faux(ns.Profils.obtenir(p.id), "supprimé")
	T.sans_erreur()
end)

T.test("fenêtre des profils : comparer, copier, coller, sauvegarde, Tout et Rien intouchables", function(B)
	local ns = demarrer(B)
	ns.ProfilsUI.ouvrir()
	ns.ProfilsUI.choisir("leveling")
	ns.ProfilsUI.boutons.comparer:Click()
	T.vrai(ns.ProfilsUI.partenaire and ns.ProfilsUI.partenaire ~= "leveling")
	T.vrai(ns.ProfilsUI.detail:GetText():find("Seulement dans le premier", 1, true), "comparaison affichée")
	T.vrai(ns.ProfilsUI.boutons.comparer.etiquette:GetText():find("Comparé à", 1, true))
	-- copier / coller
	ns.ProfilsUI.boutons.copier:Click()
	local texte = ns.ProfilsUI.champTexte:GetText()
	T.vrai(texte:find("^MAA1:P:nom=Leveling"), texte)
	ns.ProfilsUI.boutons.coller:Click()
	T.vrai(ns.Profils.trouver("Leveling (2)"), "recollé")
	T.eq(ns.ProfilsUI.champTexte:GetText(), "", "champ vidé après l'import")
	ns.ProfilsUI.boutons.sauvegarde:Click()
	T.vrai(ns.ProfilsUI.champTexte:GetText():find("^MAA1:S"), "sauvegarde complète")
	-- Tout et Rien : pas de suppression ni de renommage possibles
	ns.ProfilsUI.choisir("@rien")
	T.faux(ns.ProfilsUI.boutons.supprimer.actif)
	ns.ProfilsUI.boutons.supprimer:Click()
	T.faux(ns.ProfilsUI.confirmation:IsShown())
	ns.ProfilsUI.boutons.copier:Click()
	T.sans_erreur()
end)

T.test("commandes : profil, profil <nom>, profil tous, verrou, comparer, nouveau, renommer, importer", function(B)
	local ns = demarrer(B)
	B.chat = {}
	T.vrai(B.slash("/maa profil"))
	T.vrai(B.chat_contient("Profils (4)"), "liste des profils")
	T.vrai(B.chat_contient("Donjon"))
	B.chat = {}
	B.slash("/maa profil Donjon")
	T.vrai(B.chat_contient("appliqué : +"), "appliqué sans confirmation par la commande")
	T.vrai(ns.Liste.actif("DBM-Core"))
	T.eq(ns.Profils.actuel().id, "donjon")
	-- une abréviation suffit
	B.slash("/maa profil lev")
	T.vrai(ns.Liste.actif("Questie") and not ns.Liste.actif("DBM-Core"))
	B.chat = {}
	B.slash("/maa profil inexistant")
	T.vrai(B.chat_contient("Profil introuvable : inexistant"))
	-- verrou
	B.chat = {}
	B.slash("/maa verrou Questie")
	T.vrai(ns.Profils.verrou("Questie"))
	T.vrai(B.chat_contient("est verrouillé"))
	B.slash("/maa verrou")
	T.vrai(B.chat_contient("1 verrouillé(s)"))
	B.slash("/maa profil Rien")
	T.vrai(ns.Liste.actif("Questie") and not ns.Liste.actif("Pawn"), "le verrou tient")
	B.slash("/maa verrou questie")
	T.faux(ns.Profils.verrou("Questie"))
	-- comparer, nouveau, renommer, supprimer
	B.chat = {}
	B.slash("/maa profil comparer Leveling / Donjon")
	T.vrai(B.chat_contient("Seulement dans le premier"))
	B.slash("/maa profil nouveau Mon essai")
	T.vrai(ns.Profils.trouver("Mon essai"))
	B.slash("/maa profil renommer Mon essai / Autre nom")
	T.vrai(ns.Profils.trouver("Autre nom") and not ns.Profils.trouver("Mon essai"))
	B.slash("/maa profil supprimer Autre nom")
	T.faux(ns.Profils.trouver("Autre nom"))
	-- exporter / importer par commande
	B.chat = {}
	B.slash("/maa profil exporter Pêche")
	local ligne
	for _, l in ipairs(B.chat_texte()) do if l:find("MAA1:P:", 1, true) then ligne = l end end
	T.vrai(ligne, "le texte du profil est écrit dans le chat")
	B.slash("/maa profil importer " .. ligne:match("MAA1:P:%S+"))
	T.vrai(ns.Profils.trouver("Pêche (2)"), "importé")
	-- tous les personnages
	B.chat = {}
	B.slash("/maa profil tous Minimal")
	T.vrai(B.chat_contient("Minimal"))
	-- recréer les profils prêts effacés
	B.slash("/maa profil supprimer Minimal")
	B.chat = {}
	B.slash("/maa profil prets")
	T.vrai(B.chat_contient("1 profil(s) prêt(s) recréé(s)"))
	T.vrai(ns.Profils.obtenir("minimal"))
	-- la fenêtre des profils
	B.slash("/maa profils")
	T.vrai(ns.ProfilsUI.estOuvert())
	T.sans_erreur()
end)

T.test("commandes en anglais : profile, profile all, lock", function(B)
	local ns = demarrer(B, { locale = "enUS" })
	B.chat = {}
	B.slash("/maa profile Dungeon")
	T.vrai(B.chat_contient("applied: +"), "appliqué")
	T.vrai(ns.Liste.actif("DBM-Core"))
	B.slash("/maa profile all Minimal")
	T.vrai(B.chat_contient("Minimal"))
	B.slash("/maa lock Pawn")
	T.vrai(ns.Profils.verrou("Pawn"))
	B.slash("/maa profile new Test")
	T.vrai(ns.Profils.trouver("Test"))
	T.sans_erreur()
end)

T.test("le menu du clic droit propose Verrouiller / Déverrouiller", function(B)
	local ns = demarrer(B)
	ns.Fenetre.ouvrir()
	local e = ns.Liste.parNom("Questie")
	local function entree()
		for _, it in ipairs(ns.Menu.entrees(e)) do
			if it.texte == "Verrouiller" or it.texte == "Déverrouiller" then return it end
		end
	end
	T.eq(entree().texte, "Verrouiller")
	entree().action()
	T.vrai(ns.Profils.verrou("Questie"))
	T.eq(entree().texte, "Déverrouiller")
	T.sans_erreur()
end)

T.test("le panneau d'options a son groupe Profils et chaque réglage se change", function(B)
	local ns = demarrer(B)
	local groupe
	for _, g in ipairs(ns.donnees.options.groupes) do if g.id == "profils" then groupe = g end end
	T.vrai(groupe, "groupe Profils")
	T.eq(#groupe.elements, 9)
	ns.Reglages.ecrire("profils.portee", "tous")
	ns.ProfilsUI.ouvrir()
	T.eq(ns.ProfilsUI.portee(), "tous", "la portée de départ suit le réglage")
	T.sans_erreur()
end)

T.fin()
