-- Actions rapides (B3-02) : activer seul, avec ses modules (Maj+clic), essai d'une session, dépannage et retour,
-- commandes et macros, périmés, minicarte (compteur, clic droit), résumé, raccourcis, verrou sur la ligne.
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

local function memes(a, b)
	for k in pairs(a) do if not b[k] then return false, k end end
	for k in pairs(b) do if not a[k] then return false, k end end
	return true
end

local function ligne(ns, nom)
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l.entree.nom == nom and l:IsShown() then return l end
	end
end

local function entreeMenu(ns, nom, cle)
	local e = ns.Liste.parNom(nom)
	local texte = ns.T(cle)
	for _, it in ipairs(ns.Menu.entrees(e)) do
		if it.texte == texte then return it end
	end
end

------------------------------------------------------------------ activer seul
T.test("activer seul : tout est coupé sauf l'add-on, ses dépendances, les verrouillés et ce gestionnaire", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("Questie", true)
	local plus, moins = ns.Actions.seul("DBM-Core")
	local a = actifs(ns)
	T.vrai(a["DBM-Core"], "l'add-on reste")
	T.vrai(a["DBM-StatusBarTimers"], "sa dépendance requise reste")
	T.vrai(a["Questie"], "le verrouillé reste")
	T.vrai(a["MesAddons"], "ce gestionnaire reste")
	T.eq(compte(a), 4, "rien d'autre")
	T.vrai(moins > 0 and plus >= 0)
	-- un seul Annuler remet tout
	T.vrai(ns.Liste.annuler())
	T.vrai(compte(actifs(ns)) > 4)
	T.sans_erreur()
end)

T.test("le menu clic droit propose activer seul, avec ses modules, copier le lien, essai", function(B)
	local ns = demarrer(B)
	ns.Fenetre.ouvrir()
	T.vrai(entreeMenu(ns, "Questie", "menu.seul"), "activer seul")
	T.vrai(entreeMenu(ns, "Questie", "menu.complet"), "avec ses modules")
	T.vrai(entreeMenu(ns, "Questie", "menu.essai"), "essai")
	T.vrai(entreeMenu(ns, "Questie", "menu.favori"), "favori (déjà là)")
	entreeMenu(ns, "Questie", "menu.seul").action()
	T.eq(compte(actifs(ns)) <= 3, true, "Questie, ses dépendances et le gestionnaire")
	T.sans_erreur()
end)

T.test("copier le lien ouvre le volet du lien dans la fiche", function(B)
	local ns = demarrer(B)
	ns.Fenetre.ouvrir()
	local e = ns.Liste.parNom("Questie")
	local it = entreeMenu(ns, "Questie", "menu.lien")
	if ns.FicheModele.lien(e) ~= "" then
		T.vrai(it, "entrée présente quand un lien existe")
		it.action()
		T.vrai(ns.Parchemin.volet_lien:IsShown(), "volet du lien visible")
		T.eq(ns.Vue.selection, "Questie")
	else
		T.faux(it, "pas de lien : pas d'entrée")
	end
	T.sans_erreur()
end)

------------------------------------------------------------------ Maj+clic
T.test("Maj + clic sur la case : l'add-on, sa dépendance et ses modules utiles s'allument", function(B)
	local ns = demarrer(B, { addons_actifs = { ["DBM-Core"] = false, ["DBM-StatusBarTimers"] = false, ["DBM-Party-Forever"] = false } })
	ns.Fenetre.ouvrir()
	T.faux(ns.Liste.actif("DBM-Core"))
	T.faux(ns.Liste.actif("DBM-Party-Forever"))
	local l = ligne(ns, "DBM-Core")
	T.vrai(l, "ligne DBM-Core visible")
	local avant = actifs(ns)
	B.maj = true
	l.case:Click()
	B.maj = false
	T.vrai(ns.Liste.actif("DBM-Core"))
	T.vrai(ns.Liste.actif("DBM-StatusBarTimers"), "dépendance requise")
	local utiles, inutiles = 0, 0
	for _, m in ipairs(ns.Liste.parNom("DBM-Core").modules) do
		if m.inutile then
			inutiles = inutiles + 1
			T.eq(ns.Liste.actif(m.nom), avant[m.nom] == true, m.nom .. " : un module inutile n'est pas allumé")
		else
			utiles = utiles + 1
			T.vrai(ns.Liste.actif(m.nom), m.nom .. " : module utile allumé")
		end
	end
	T.vrai(utiles > 0 and inutiles > 0, "le jeu d'essai a des modules utiles et inutiles")
	T.sans_erreur()
end)

T.test("sans Maj, la case garde son comportement d'avant (pas de dépendance ajoutée)", function(B)
	local ns = demarrer(B, { addons_actifs = { ["DBM-Core"] = false, ["DBM-StatusBarTimers"] = false } })
	ns.Fenetre.ouvrir()
	ligne(ns, "DBM-Core").case:Click()
	T.vrai(ns.Liste.actif("DBM-Core"))
	T.faux(ns.Liste.actif("DBM-StatusBarTimers"))
	T.sans_erreur()
end)

T.test("la touche Maj se règle (actions.maj_clic)", function(B)
	local ns = demarrer(B, { addons_actifs = { ["DBM-Core"] = false, ["DBM-StatusBarTimers"] = false } })
	ns.Reglages.ecrire("actions.maj_clic", false)
	ns.Fenetre.ouvrir()
	B.maj = true
	ligne(ns, "DBM-Core").case:Click()
	T.faux(ns.Liste.actif("DBM-StatusBarTimers"), "réglage coupé : Maj ne change rien")
	T.sans_erreur()
end)

------------------------------------------------------------------ commandes et macros
T.test("une macro change de profil : /maa profil Donjon donne exactement ce que donne le profil", function(B)
	-- référence : le profil appliqué par le code des profils
	local ns = demarrer(B)
	ns.Profils.appliquer(ns.Profils.trouver("Donjon"), "perso")
	local attendu = actifs(ns)
	-- la macro, dans une session toute neuve
	ns = demarrer(B)
	local avant = actifs(ns)
	T.vrai(B.slash("/maa profil Donjon"))
	local a = actifs(ns)
	local ok, qui = memes(attendu, a)
	T.vrai(ok, "différence avec le profil : " .. tostring(qui))
	T.vrai(compte(a) < compte(avant), "le profil a bien coupé des add-ons")
	T.vrai(ns.Liste.actif("MesAddons"))
	T.vrai(B.chat_contient("appliqué"))
	T.eq(ns.Profils.actuel().id, "donjon")
	-- en anglais aussi
	ns = demarrer(B, { locale = "enUS" })
	T.vrai(B.slash("/maa profile Dungeon"))
	T.vrai(memes(attendu, actifs(ns)))
	T.sans_erreur()
end)

T.test("commandes : activer, desactiver, seul, annuler (français et anglais)", function(B)
	local ns = demarrer(B, { addons_actifs = { Auctionator = false } })
	B.slash("/maa activer Auctionator")
	T.vrai(ns.Liste.actif("Auctionator"))
	B.slash("/maa annuler")
	T.faux(ns.Liste.actif("Auctionator"))
	B.slash("/maa annuler")
	B.slash("/maa enable Auctionator")
	T.vrai(ns.Liste.actif("Auctionator"))
	B.slash("/maa desactiver auctionator")
	T.faux(ns.Liste.actif("Auctionator"))
	B.slash("/maa seul TomTom")
	T.vrai(ns.Liste.actif("TomTom") and ns.Liste.actif("MesAddons"))
	T.faux(ns.Liste.actif("Questie"))
	B.slash("/maa activer ZzzInconnu")
	T.vrai(B.chat_contient("inconnu"))
	B.slash("/maa activer")
	T.sans_erreur()
end)

T.test("/maa recharger enregistre puis recharge", function(B)
	local ns = demarrer(B)
	local avant = B.sauvegardes_addons or 0
	B.slash("/maa recharger")
	T.vrai((B.sauvegardes_addons or 0) > avant, "SaveAddOns appelé")
	T.sans_erreur()
end)

T.test("/maa perimes charge ou vérifie les périmés (réglage du jeu)", function(B)
	local ns = demarrer(B)
	T.faux(ns.Actions.perimesActif())
	B.slash("/maa perimes on")
	T.vrai(ns.Actions.perimesActif())
	T.eq(GetCVar("checkAddonVersion"), "0")
	B.slash("/maa perimes")
	T.faux(ns.Actions.perimesActif(), "sans mot : bascule")
	B.slash("/maa outdated on")
	T.vrai(ns.Actions.perimesActif())
	B.slash("/maa perimes off")
	T.eq(GetCVar("checkAddonVersion"), "1")
	T.sans_erreur()
end)

------------------------------------------------------------------ dépannage
T.test("dépannage puis retour remet tout comme avant (même après un rechargement)", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("TomTom", true)
	local avant = actifs(ns)
	B.slash("/maa depannage Questie")
	local a = actifs(ns)
	T.vrai(a["Questie"] and a["TomTom"] and a["MesAddons"], "cité, verrouillé et gestionnaire")
	T.vrai(compte(a) < compte(avant) / 2, "presque tout est coupé")
	T.vrai(ns.Actions.depannageActif())
	-- un second dépannage ne perd pas l'état d'origine
	B.slash("/maa depannage Auctionator")
	T.vrai(B.chat_contient("déjà"))
	-- on recharge : le dépannage survit
	ns = B.recharger()
	T.vrai(ns.Actions.depannageActif(), "sauvegardé")
	B.slash("/maa retour")
	local apres = actifs(ns)
	local ok, qui = memes(avant, apres)
	T.vrai(ok, "identique à l'état d'avant, différence : " .. tostring(qui))
	T.faux(ns.Actions.depannageActif())
	B.slash("/maa retour")
	T.vrai(B.chat_contient("Pas de dépannage"))
	T.sans_erreur()
end)

T.test("dépannage sans nom : seulement les verrouillés et le gestionnaire ; un nom inconnu ne change rien", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("TomTom", true)
	local avant = actifs(ns)
	B.slash("/maa safe Zzz")
	T.vrai(memes(avant, actifs(ns)), "rien changé")
	T.faux(ns.Actions.depannageActif())
	B.slash("/maa safe")
	local a = actifs(ns)
	T.vrai(a["TomTom"] and a["MesAddons"])
	T.eq(compte(a), 2)
	B.slash("/maa back")
	T.vrai(memes(avant, actifs(ns)))
	T.sans_erreur()
end)

------------------------------------------------------------------ essai
T.test("un add-on en essai est allumé, puis éteint au rechargement suivant", function(B)
	local ns = demarrer(B, { addons_actifs = { DBM = false, ["DBM-Core"] = false, ["DBM-StatusBarTimers"] = false } })
	T.faux(ns.Liste.actif("DBM-Core"))
	B.slash("/maa essai DBM-Core")
	T.vrai(ns.Liste.actif("DBM-Core"), "allumé pour la session")
	T.vrai(ns.Liste.actif("DBM-StatusBarTimers"), "avec sa dépendance")
	T.vrai(ns.Recherche.essai("DBM-Core"), "marqué en essai")
	-- le rechargement qui charge l'add-on : il est éteint pour le suivant
	ns = B.recharger()
	T.faux(ns.Liste.actif("DBM-Core"), "éteint dès cette connexion pour le prochain rechargement")
	T.faux(ns.Liste.actif("DBM-StatusBarTimers"), "ce qu'il avait allumé aussi")
	T.faux(ns.Recherche.essai("DBM-Core"), "plus marqué")
	T.vrai(B.chat_contient("Essai terminé"), "dit dans le chat")
	-- et il reste éteint au rechargement d'après
	ns = B.recharger()
	T.faux(ns.Liste.actif("DBM-Core"))
	T.sans_erreur()
end)

T.test("l'essai ne touche pas un add-on verrouillé ni ce gestionnaire, et se retire à la main", function(B)
	local ns = demarrer(B)
	ns.Profils.basculerVerrou("Questie", true)
	ns.Actions.basculerEssai("Questie")
	ns.Actions.basculerEssai("TomTom")
	T.vrai(ns.Actions.basculerEssai("TomTom") == false, "second appel : fin de l'essai")
	T.faux(ns.Recherche.essai("TomTom"))
	ns = B.recharger()
	T.vrai(ns.Liste.actif("Questie"), "verrouillé : jamais coupé")
	T.faux(ns.Recherche.essai("Questie"), "marque retirée")
	T.vrai(ns.Liste.actif("TomTom"), "essai retiré à la main : reste allumé")
	T.sans_erreur()
end)

T.test("/maa essai sans nom liste les essais ; le menu du clic droit bascule l'essai", function(B)
	local ns = demarrer(B)
	B.slash("/maa essai")
	T.vrai(B.chat_contient("Aucun add-on en essai"))
	entreeMenu(ns, "TomTom", "menu.essai").action()
	T.vrai(ns.Recherche.essai("TomTom"))
	B.slash("/maa essai")
	T.vrai(B.chat_contient("1 add-on(s) en essai"))
	T.vrai(entreeMenu(ns, "TomTom", "menu.essai_fin"))
	T.sans_erreur()
end)

------------------------------------------------------------------ minicarte, résumé, raccourcis
T.test("le bouton de minicarte montre le compteur d'erreurs et de changements", function(B)
	local ns = demarrer(B)
	local b = ns.Acces.bouton
	T.eq(b.compteur:GetText(), "", "rien quand tout est calme")
	ns.Liste.definir({ "Questie" }, false)
	B.avancer(3)
	T.vrai(b.compteur:GetText():find("1"), "1 changement en attente")
	ns.Reglages.ecrire("acces.compteur_minicarte", false)
	B.avancer(3)
	T.eq(b.compteur:GetText(), "", "le compteur se coupe")
	T.sans_erreur()
end)

T.test("clic droit sur la minicarte : liste des profils, un clic applique le profil", function(B)
	local ns = demarrer(B)
	local b = ns.Acces.bouton
	b._scripts.OnClick(b, "RightButton")
	T.vrai(ns.Rapide.ouvert(), "menu ouvert")
	local trouve
	for _, bt in ipairs(ns.Rapide.boutons) do
		if bt.entree and bt.entree.action and bt.entree.texte:find("Donjon", 1, true) then trouve = bt end
	end
	T.vrai(trouve, "le profil Donjon est dans la liste")
	trouve:Click()
	T.faux(ns.Rapide.ouvert(), "le menu se ferme")
	T.eq(ns.Profils.actuel().id, "donjon")
	T.vrai(ns.Liste.enAttente() > 0)
	-- maintenant des changements attendent : le menu propose Recharger en premier
	b._scripts.OnClick(b, "RightButton")
	T.vrai(ns.Rapide.boutons[1].entree.texte:find("Recharger"), "Recharger en tête")
	b._scripts.OnClick(b, "RightButton") -- referme
	T.faux(ns.Rapide.ouvert())
	-- clic gauche : la fenêtre
	b._scripts.OnClick(b, "LeftButton")
	T.vrai(ns.Fenetre.estOuverte())
	T.sans_erreur()
end)

T.test("clic droit réglé sur « recharger » : recharge tout de suite quand des changements attendent", function(B)
	local ns = demarrer(B)
	ns.Reglages.ecrire("acces.clic_droit", "recharger")
	local b = ns.Acces.bouton
	b._scripts.OnClick(b, "RightButton")
	T.vrai(ns.Rapide.ouvert(), "rien n'attend : le menu")
	b._scripts.OnClick(b, "RightButton")
	ns.Liste.definir({ "Questie" }, false)
	local avant = B.sauvegardes_addons or 0
	b._scripts.OnClick(b, "RightButton")
	T.vrai((B.sauvegardes_addons or 0) > avant, "rechargement demandé")
	T.sans_erreur()
end)

T.test("menu de la minicarte : dépannage, retour, périmés", function(B)
	local ns = demarrer(B)
	local function entree(cle)
		ns.Rapide.remplir()
		for _, bt in ipairs(ns.Rapide.boutons) do
			if bt:IsShown() and bt.entree and bt.entree.texte == ns.T(cle) then return bt end
		end
	end
	entree("rapide.depannage"):Click()
	T.vrai(ns.Actions.depannageActif())
	entree("rapide.retour"):Click()
	T.faux(ns.Actions.depannageActif())
	entree("rapide.perimes_non"):Click()
	T.vrai(ns.Actions.perimesActif())
	T.vrai(entree("rapide.perimes_oui"))
	T.sans_erreur()
end)

T.test("résumé à la connexion : une ligne dans le chat, désactivable", function(B)
	local ns = demarrer(B)
	B.avancer(10)
	T.vrai(B.chat_contient("add-ons,"), "la ligne est là")
	T.vrai(B.chat_contient("allumés"))
	-- coupé par réglage
	ns.Reglages.ecrire("actions.resume_connexion", false)
	local ns2 = B.recharger()
	B.avancer(10)
	local n = 0
	for _, l in ipairs(B.chat_texte()) do if l:find("allumés", 1, true) then n = n + 1 end end
	T.eq(n, 0, "aucune ligne de résumé")
	B.slash("/maa resume")
	T.vrai(B.chat_contient("allumés"), "la commande donne toujours la ligne")
	T.sans_erreur()
end)

T.test("le résumé parle du profil, des changements en attente et du dépannage", function(B)
	local ns = demarrer(B)
	B.slash("/maa profil Donjon")
	B.slash("/maa depannage")
	local r = ns.Actions.resume()
	T.vrai(r:find("profil Donjon", 1, true), r)
	T.vrai(r:find("en attente", 1, true), r)
	T.vrai(r:find("dépannage", 1, true), r)
	T.sans_erreur()
end)

T.test("raccourcis clavier : fonction globale et noms dans le menu Raccourcis", function(B)
	local ns = demarrer(B)
	local f = _G[ns.Reglages.technique().fonction_raccourci]
	T.eq(type(f), "function")
	T.faux(ns.Fenetre.estOuverte())
	f("fenetre")
	T.vrai(ns.Fenetre.estOuverte())
	f("fenetre")
	T.faux(ns.Fenetre.estOuverte())
	T.eq(BINDING_HEADER_MESADDONS, "Mes Add-ons")
	T.eq(BINDING_NAME_MESADDONS_FENETRE, "Ouvrir ou fermer la fenêtre")
	T.vrai(BINDING_NAME_MESADDONS_PROFILS and BINDING_NAME_MESADDONS_RECHARGER)
	-- chaque raccourci du fichier de réglages a bien son nom, et le Bindings.xml les cite tous
	local f2 = io.open((os.getenv("MAA_RACINE") or ".") .. "/addon/MesAddons/Bindings.xml", "rb")
	local xml = f2:read("*a")
	f2:close()
	for _, id in ipairs(ns.donnees.reglages.actions.raccourcis) do
		T.vrai(xml:find('MesAddonsRaccourci("' .. id .. '")', 1, true), "Bindings.xml : " .. id)
		T.vrai(_G["BINDING_NAME_MESADDONS_" .. string.upper(id)], "nom : " .. id)
	end
	T.sans_erreur()
end)

T.test("le raccourci « recharger » enregistre puis recharge", function(B)
	local ns = demarrer(B)
	local avant = B.sauvegardes_addons or 0
	_G[ns.Reglages.technique().fonction_raccourci]("recharger")
	T.vrai((B.sauvegardes_addons or 0) > avant)
	T.sans_erreur()
end)

------------------------------------------------------------------ verrou sur la ligne
T.test("la ligne d'un add-on verrouillé porte la marque Verrou, qui se règle", function(B)
	local ns = demarrer(B)
	ns.Fenetre.ouvrir()
	T.faux(ns.Vue.texteBadges(ns.Liste.parNom("Questie")):find("Verrou", 1, true))
	ns.Profils.basculerVerrou("Questie", true)
	T.vrai(ns.Vue.texteBadges(ns.Liste.parNom("Questie")):find("Verrou", 1, true), "marque visible")
	ns.Reglages.ecrire("liste.badges.verrou", false)
	T.faux(ns.Vue.texteBadges(ns.Liste.parNom("Questie")):find("Verrou", 1, true), "réglable")
	T.sans_erreur()
end)

T.test("en anglais, tout parle anglais : commandes, menu, résumé", function(B)
	local ns = demarrer(B, { locale = "enUS" })
	B.slash("/maa safe")
	T.vrai(B.chat_contient("Safe mode"))
	B.slash("/maa back")
	T.vrai(B.chat_contient("Safe mode over"))
	T.eq(ns.T("menu.seul"), "Enable only this one")
	T.vrai(ns.Actions.resume():find("add-ons,", 1, true))
	T.eq(BINDING_NAME_MESADDONS_FENETRE, "Open or close the window")
	T.sans_erreur()
end)

T.test("le panneau d'options a le groupe Actions rapides et les réglages du bouton", function(B)
	local ns = demarrer(B)
	local groupes = {}
	for _, g in ipairs(ns.donnees.options.groupes) do groupes[g.id] = g end
	T.vrai(groupes.actions, "groupe actions")
	for _, chemin in ipairs({ "actions.resume_connexion", "actions.maj_clic", "actions.essai_message" }) do
		local ok
		for _, el in ipairs(groupes.actions.elements) do if el.chemin == chemin then ok = true end end
		T.vrai(ok, chemin)
	end
	for _, chemin in ipairs({ "acces.compteur_minicarte", "acces.clic_droit", "acces.profils_minicarte" }) do
		local ok
		for _, el in ipairs(groupes.acces.elements) do if el.chemin == chemin then ok = true end end
		T.vrai(ok, chemin)
	end
	T.sans_erreur()
end)

T.fin()
