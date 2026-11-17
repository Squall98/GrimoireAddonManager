-- Fenêtre Grimoire (B2-01) : thèmes, catégories, liste, sous-modules, activer, Recharger, Annuler, accès, réglages.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function ligne(ns, nom)
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l.entree.nom == nom and l:IsShown() then return l end
	end
end

local function visibles(ns)
	local n = 0
	for _, l in ipairs(ns.Vue.lignes) do if l.entree and l:IsShown() then n = n + 1 end end
	return n
end

local function categorie(ns, id)
	for _, l in ipairs(ns.Vue.lignesCat) do
		if l.id == id and l:IsShown() then return l end
	end
end

local function egal(a, b)
	return a and b and math.abs(a[1] - b[1]) < 0.01 and math.abs(a[2] - b[2]) < 0.01 and math.abs(a[3] - b[3]) < 0.01
end

local function couleur(ns, cle)
	local r, g, b = ns.Style.couleur(cle)
	return { r, g, b }
end

T.test("la fenêtre se construit sans erreur en Horde, avec son vrai emblème", function(B)
	local ns = B.demarrer({ faction = "Horde" })
	T.faux(ns.Fenetre.estOuverte())
	ns.Fenetre.ouvrir()
	T.sans_erreur()
	T.vrai(ns.Fenetre.estOuverte())
	T.eq(ns.Style.theme(), "horde")
	T.vrai(ns.Fenetre.embleme:GetTexture():find("Horde"), "emblème de la Horde")
	T.vrai(egal(ns.Fenetre.cadre._couleur_bord, couleur(ns, "dore")), "bord doré du thème")
	T.vrai(egal(ns.Fenetre.cadre._couleur_fond, couleur(ns, "fond")), "fond du thème")
	T.eq(ns.Fenetre.titre:GetText(), "Grimoire Addon Manager")
	T.vrai(ns.Fenetre.cadre._police == nil and ns.Fenetre.titre._police[1] == "Fonts\\FRIZQT__.TTF", "police du jeu par défaut")
end)

T.test("la fenêtre se construit sans erreur en Alliance et en Neutre", function(B)
	local ns = B.demarrer({ faction = "Alliance" })
	ns.Fenetre.ouvrir()
	T.sans_erreur()
	T.eq(ns.Style.theme(), "alliance")
	T.vrai(ns.Fenetre.embleme:GetTexture():find("Alliance"), "emblème de l'Alliance")
	T.vrai(egal(ns.Fenetre.cadre._couleur_fond, couleur(ns, "fond")))
	local bleu = ns.Fenetre.cadre._couleur_fond
	ns = B.demarrer({ faction = "Neutral" })
	ns.Fenetre.ouvrir()
	T.sans_erreur()
	T.eq(ns.Style.theme(), "neutre", "perso sans faction : thème neutre")
	T.faux(egal(ns.Fenetre.cadre._couleur_fond, bleu), "couleurs différentes de l'Alliance")
	T.vrai(ns.Fenetre.embleme:GetTexture():find("Book"), "icône de secours neutre")
end)

T.test("le thème se choisit : horde, alliance, neutre, auto ; la fenêtre ouverte est repeinte", function(B)
	local ns = B.demarrer({ faction = "Horde" })
	ns.Fenetre.ouvrir()
	B.slash("/maa theme alliance")
	T.sans_erreur()
	T.eq(ns.Style.theme(), "alliance")
	T.vrai(egal(ns.Fenetre.cadre._couleur_fond, couleur(ns, "fond")), "repeinte tout de suite")
	T.vrai(ns.Fenetre.embleme:GetTexture():find("Alliance"))
	B.slash("/maa theme neutre")
	T.eq(ns.Style.theme(), "neutre")
	B.slash("/maa theme auto")
	T.eq(ns.Style.theme(), "horde", "auto = faction du perso")
	B.chat = {}
	B.slash("/maa theme violet")
	T.vrai(B.chat_contient("Valeur inconnue : violet"))
	B.recharger({ faction = "Horde" })
	B.slash("/maa theme alliance")
	B.recharger({ faction = "Horde" })
	T.eq(MesAddonsDB.reglages.fenetre.theme, "alliance", "le choix est gardé")
end)

T.test("la police du jeu par défaut, gothique au choix, Cinzel absente : retour à la police du jeu", function(B)
	local ns = B.demarrer()
	B.polices_absentes = "cinzel"
	ns.Fenetre.ouvrir()
	B.slash("/maa police gothique")
	T.eq(ns.Fenetre.titre._police[1], "Fonts\\MORPHEUS.TTF")
	B.slash("/maa police cinzel")
	T.sans_erreur()
	T.eq(ns.Fenetre.titre._police[1], "Fonts\\FRIZQT__.TTF", "repli sur la police du jeu")
	local note
	for _, l in ipairs(MesAddonsDB.journal) do if l.k == "journal.police_absente" then note = l end end
	T.vrai(note, "l'absence est notée au journal")
	B.polices_absentes = nil
	B.slash("/maa police jeu")
	T.eq(ns.Fenetre.titre._police[1], "Fonts\\FRIZQT__.TTF")
end)

T.test("catégories à gauche, liste à droite, sous-modules repliés puis dépliés", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	T.vrai(categorie(ns, "tous"), "ligne « Tous »")
	T.vrai(categorie(ns, "combat"), "catégorie Combat")
	T.vrai(categorie(ns, "autres"), "catégorie Autres")
	T.eq(categorie(ns, "tous").nombre:GetText(), "101")
	-- repliés : DBM-Core visible, ses modules non
	local dbm = ligne(ns, "DBM-Core")
	T.vrai(dbm, "DBM-Core dans la liste")
	T.faux(ligne(ns, "DBM-GUI"), "module replié")
	T.eq(dbm.marque:GetText(), "25 modules")
	T.vrai(dbm.fleche:IsShown(), "flèche pour déplier")
	local avant = visibles(ns)
	dbm.fleche:Click()
	T.vrai(ligne(ns, "DBM-GUI"), "module visible une fois déplié")
	T.eq(visibles(ns), avant + 25)
	T.eq(ligne(ns, "DBM-GUI").niveau, 1, "module en retrait")
	T.eq(dbm.marque:GetText(), "", "plus de compteur une fois déplié")
	ligne(ns, "DBM-Core").fleche:Click()
	T.eq(visibles(ns), avant)
	-- catégorie choisie
	categorie(ns, "combat"):Click()
	T.eq(ns.Fenetre.memoire().categorie, "combat")
	T.eq(ns.Vue.nomCategorie:GetText(), "Combat")
	T.vrai(visibles(ns) < avant)
	T.sans_erreur()
end)

T.test("chaque add-on est dans une seule catégorie et le total est juste", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local somme = 0
	for _, c in ipairs(ns.Liste.categories()) do
		if c.id ~= "tous" then somme = somme + c.n end
	end
	T.eq(somme, #ns.Liste.entrees(), "somme des catégories = nombre d'add-ons")
	for _, e in ipairs(ns.Liste.entrees()) do
		if e.parent then T.eq(e.categorie, e.parent.categorie, "module dans la catégorie de son principal : " .. e.nom) end
	end
end)

T.test("activer et désactiver : la case change l'état des add-ons (C_AddOns simulé)", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local l = ligne(ns, "Auctionator")
	T.vrai(l.case:GetChecked(), "activé au départ")
	l.case:Click()
	T.eq(C_AddOns.GetAddOnEnableState("Auctionator"), 0, "désactivé dans le jeu")
	T.faux(ligne(ns, "Auctionator").case:GetChecked())
	T.vrai(ligne(ns, "Auctionator").point:IsShown(), "pastille : changement en attente")
	l.case:Click()
	T.eq(C_AddOns.GetAddOnEnableState("Auctionator"), 2, "réactivé")
	T.faux(ligne(ns, "Auctionator").point:IsShown(), "revenu à l'état de départ : plus en attente")
	T.sans_erreur()
end)

T.test("cocher le principal coche ses modules ; un module inutile sur Forever n'est pas activé", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local dbm = ns.Liste.parNom("DBM-Core")
	local utile, inutile
	for _, m in ipairs(dbm.modules) do
		if m.inutile then inutile = inutile or m else utile = utile or m end
	end
	T.vrai(utile and inutile, "DBM a des modules utiles et des modules inutiles sur Forever")
	ligne(ns, "DBM-Core").case:Click() -- décoche
	T.eq(C_AddOns.GetAddOnEnableState("DBM-Core"), 0)
	T.eq(C_AddOns.GetAddOnEnableState(utile.nom), 0, "module utile décoché avec le principal")
	T.eq(C_AddOns.GetAddOnEnableState(inutile.nom), 0)
	ligne(ns, "DBM-Core").case:Click() -- recoche
	T.eq(C_AddOns.GetAddOnEnableState("DBM-Core"), 2)
	T.eq(C_AddOns.GetAddOnEnableState(utile.nom), 2, "module utile recoché")
	T.eq(C_AddOns.GetAddOnEnableState(inutile.nom), 0, "module inutile laissé tel quel")
end)

T.test("les add-ons non prévus pour Forever sont grisés et signalés", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local gris
	for _, e in ipairs(ns.Liste.lesRacines()) do if e.inutile then gris = e break end end
	T.vrai(gris, "un principal inutile existe dans les données")
	local l = ligne(ns, gris.nom)
	T.eq(l.marque:GetText(), "non prévu pour Forever")
	T.vrai(egal(l.nom._couleur, couleur(ns, "texte_eteint")), "nom grisé")
	local bon = ligne(ns, "Auctionator")
	T.vrai(egal(bon.nom._couleur, couleur(ns, "dore_clair")), "add-on utile : couleur normale")
	-- les 16001 sont reconnus
	T.faux(ns.Liste.parNom("Auctionator").inutile)
end)

T.test("ce gestionnaire ne peut pas se désactiver lui-même", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local l = ligne(ns, "GrimoireAddonManager")
	T.vrai(l, "il est dans la liste")
	T.faux(l.case:IsEnabled(), "case verrouillée")
	T.eq(l.marque:GetText(), "ce gestionnaire")
	T.eq(ns.Liste.definir({ "GrimoireAddonManager" }, false), 0, "refusé aussi par le code")
	T.eq(C_AddOns.GetAddOnEnableState("GrimoireAddonManager"), 2)
end)

T.test("une case sur la catégorie active ou désactive toute la catégorie", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	categorie(ns, "boss-encounters"):Click()
	T.vrai(ns.Vue.caseCategorie:IsShown())
	local entrees = ns.Liste.entreesCategorie("boss-encounters")
	T.vrai(#entrees > 1)
	ns.Vue.caseCategorie:Click() -- tout est activé : tout se désactive
	for _, e in ipairs(entrees) do T.eq(C_AddOns.GetAddOnEnableState(e.nom), 0, e.nom) end
	T.faux(ns.Vue.caseCategorie:GetChecked())
	ns.Vue.caseCategorie:Click() -- tout s'active (sauf les inutiles)
	for _, e in ipairs(entrees) do
		T.eq(C_AddOns.GetAddOnEnableState(e.nom), e.inutile and 0 or 2, e.nom)
	end
	T.vrai(ns.Vue.caseCategorie:GetChecked(), "case cochée : tous les activables sont actifs")
	categorie(ns, "tous"):Click()
	T.faux(ns.Vue.caseCategorie:IsShown(), "pas de case sur « Tous »")
end)

T.test("compteur de changements, bouton Recharger qui s'allume, Recharger enregistre puis recharge", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local F = ns.Fenetre
	T.eq(F.recharger.etiquette:GetText(), "Recharger")
	T.faux(F.recharger.pulse)
	T.eq(F.texteAttente:GetText(), "Aucun changement en attente.")
	ligne(ns, "Auctionator").case:Click()
	ligne(ns, "Baganator").case:Click()
	T.eq(F.recharger.etiquette:GetText(), "Recharger (2)")
	T.vrai(F.recharger.pulse, "le bouton s'allume")
	T.vrai(F.recharger.halo:IsShown())
	T.eq(F.texteAttente:GetText(), "2 changement(s) en attente : recharge pour les appliquer.")
	T.eq(B.rechargements, 0, "aucun rechargement automatique")
	F.recharger:Click()
	T.eq(B.rechargements, 1, "ReloadUI appelé")
	T.eq(B.sauvegardes_addons, 1, "SaveAddOns appelé avant")
end)

T.test("Annuler : cinq états, dans l'ordre inverse", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local F = ns.Fenetre
	T.faux(F.annuler.actif, "rien à annuler au départ")
	local noms = { "Auctionator", "Baganator", "Details", "Pawn", "Plater", "Questie", "TomTom" }
	for _, n in ipairs(noms) do ligne(ns, n).case:Click() end
	T.eq(ns.Liste.nombreAnnulations(), 5, "au plus 5 états gardés")
	T.eq(F.annuler.etiquette:GetText(), "Annuler (5)")
	T.vrai(F.annuler.actif)
	F.annuler:Click() -- remet TomTom
	T.eq(C_AddOns.GetAddOnEnableState("TomTom"), 2)
	T.eq(C_AddOns.GetAddOnEnableState("Questie"), 0)
	F.annuler:Click() -- remet Questie
	T.eq(C_AddOns.GetAddOnEnableState("Questie"), 2)
	for _ = 1, 3 do F.annuler:Click() end
	T.eq(C_AddOns.GetAddOnEnableState("Pawn"), 2)
	T.eq(C_AddOns.GetAddOnEnableState("Plater"), 2)
	T.eq(C_AddOns.GetAddOnEnableState("Details"), 2)
	T.eq(C_AddOns.GetAddOnEnableState("Baganator"), 0, "le 2e état est le plus ancien gardé : Auctionator et Baganator restent")
	T.eq(C_AddOns.GetAddOnEnableState("Auctionator"), 0)
	T.faux(F.annuler.actif, "plus rien à annuler")
	T.eq(F.annuler.etiquette:GetText(), "Annuler")
	T.sans_erreur()
end)

T.test("un lot (catégorie) ne prend qu'une place dans l'historique", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	categorie(ns, "boss-encounters"):Click()
	ns.Vue.caseCategorie:Click()
	T.eq(ns.Liste.nombreAnnulations(), 1)
	ns.Fenetre.annuler:Click()
	for _, e in ipairs(ns.Liste.entreesCategorie("boss-encounters")) do T.eq(C_AddOns.GetAddOnEnableState(e.nom), 2, e.nom) end
	T.eq(ns.Liste.enAttente(), 0, "tout est revenu : rien en attente")
end)

T.test("déplaçable et redimensionnable : place et taille gardées après /reload", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local f = ns.Fenetre.cadre
	T.eq(f:GetWidth(), 940, "taille de départ : grande")
	T.eq(f:GetHeight(), 580)
	-- déplacement
	f.GetPoint = function() return "TOPLEFT", UIParent, "BOTTOMLEFT", 120, 700 end
	ns.Fenetre.entete._scripts.OnDragStart()
	T.vrai(f._deplace)
	ns.Fenetre.entete._scripts.OnDragStop()
	T.faux(f._deplace)
	-- redimensionnement par la poignée
	ns.Fenetre.poignee._scripts.OnMouseDown()
	T.vrai(f._redimensionne)
	f:SetSize(700, 450)
	ns.Fenetre.poignee._scripts.OnMouseUp()
	B.recharger()
	local ns2 = B.ns
	ns2.Fenetre.ouvrir()
	T.eq(ns2.Fenetre.cadre:GetWidth(), 700, "taille gardée")
	T.eq(ns2.Fenetre.cadre:GetHeight(), 450)
	local p, _, rp, x, y = ns2.Fenetre.cadre:GetPoint(1)
	T.eq(p, "TOPLEFT")
	T.eq(rp, "BOTTOMLEFT")
	T.eq(x, 120)
	T.eq(y, 700)
	T.vrai(ns2.Fenetre.cadre._clampe ~= false)
	T.sans_erreur()
end)

T.test("la taille de départ se règle : grande, moyenne, compacte ; elle remplace la taille gardée", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	B.slash("/maa taille moyenne")
	T.eq(ns.Fenetre.cadre:GetWidth(), 760)
	B.slash("/maa taille compacte")
	T.eq(ns.Fenetre.cadre:GetWidth(), 660)
	B.slash("/maa size large")
	T.eq(ns.Fenetre.cadre:GetWidth(), 940)
	B.slash("/maa taille immense")
	T.eq(ns.Fenetre.cadre:GetWidth(), 940, "valeur inconnue : rien ne change")
	-- l'écran est plus petit que la taille choisie : on reste dans l'écran
	UIParent._w, UIParent._h = 800, 500
	ns.Fenetre.reinitialiserTaille()
	T.eq(ns.Fenetre.cadre:GetWidth(), 760)
	T.eq(ns.Fenetre.cadre:GetHeight(), 460)
end)

T.test("version mini : liste seule, chaque mode garde sa taille", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local F = ns.Fenetre
	T.vrai(F.panneauCats:IsShown() and F.panneauFiche:IsShown())
	F.boutonMode:Click()
	T.eq(F.mode(), "mini")
	T.faux(F.panneauCats:IsShown(), "catégories cachées")
	T.faux(F.panneauFiche:IsShown(), "fiche cachée")
	T.vrai(F.panneauListe:IsShown())
	T.eq(F.cadre:GetWidth(), 660, "taille de la version mini (tout l'en-tête tient)")
	T.faux(ns.Barre.vue:IsShown(), "mini : Vue et Tri restent dans les options")
	T.faux(F.toutActiver:IsShown(), "mini : pas de Tout activer")
	T.eq(F.boutonMode.etiquette:GetText(), "Version complète")
	F.boutonMode:Click()
	T.eq(F.mode(), "complet")
	T.eq(F.cadre:GetWidth(), 940)
	T.vrai(F.panneauCats:IsShown())
	B.slash("/maa mini")
	T.eq(F.mode(), "mini")
	B.recharger()
	B.ns.Fenetre.ouvrir()
	T.eq(B.ns.Fenetre.mode(), "mini", "le mode est gardé")
	T.sans_erreur()
end)

T.test("Échap ferme la fenêtre ; le réglage peut le retirer", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	local nom = ns.Fenetre.cadre:GetName()
	local trouve = false
	for _, n in ipairs(UISpecialFrames) do if n == nom then trouve = true end end
	T.vrai(trouve, "dans la liste des fenêtres que Échap ferme")
	ns.Fenetre.fermer()
	ns.Reglages.ecrire("fenetre.fermer_avec_echap", false)
	ns.Fenetre.ouvrir()
	trouve = false
	for _, n in ipairs(UISpecialFrames) do if n == nom then trouve = true end end
	T.faux(trouve, "retiré quand le réglage est coupé")
end)

T.test("ouverture par /maa, /mesaddons et le bouton de la minicarte", function(B)
	local ns = B.demarrer()
	T.faux(ns.Fenetre.estOuverte())
	B.slash("/maa")
	T.vrai(ns.Fenetre.estOuverte(), "commande sans argument = ouvrir")
	B.slash("/mesaddons ouvrir")
	T.faux(ns.Fenetre.estOuverte(), "la même commande referme")
	local b = ns.Acces.bouton
	T.vrai(b and b:IsShown(), "bouton de minicarte présent")
	b:Click()
	T.vrai(ns.Fenetre.estOuverte())
	b:Click()
	T.faux(ns.Fenetre.estOuverte())
	b._scripts.OnEnter(b)
	T.vrai(GameTooltip.lignes[1] == "Grimoire Addon Manager")
	T.sans_erreur()
end)

T.test("le bouton de minicarte se cache par réglage et garde sa place", function(B)
	local ns = B.demarrer()
	ns.Reglages.ecrire("acces.bouton_minicarte", false)
	ns.Acces.majVisibilite()
	T.faux(ns.Acces.bouton:IsShown())
	ns.Reglages.ecrire("acces.angle_minicarte", 90)
	ns.Acces.placer()
	local _, _, _, x, y = ns.Acces.bouton:GetPoint(1)
	T.vrai(math.abs(x) < 0.01 and y > 60, "angle 90° : en haut de la minicarte")
end)

T.test("le bouton « Add-ons » du menu Échap ouvre notre fenêtre et masque celle du jeu", function(B)
	local ns = B.demarrer()
	-- le menu du jeu : un bouton dont le texte est « Add-ons », créé quand le menu s'ouvre
	local bouton = CreateFrame("Button", nil, GameMenuFrame)
	bouton:SetText(ADDONS)
	local autre = CreateFrame("Button", nil, GameMenuFrame)
	autre:SetText("Options")
	local liste_jeu = CreateFrame("Frame", "AddonList", UIParent)
	liste_jeu:Show()
	GameMenuFrame:Show() -- OnShow : nos crochets cherchent le bouton
	bouton:Click()
	B.avancer(0.1)
	T.vrai(ns.Fenetre.estOuverte(), "notre fenêtre s'ouvre")
	T.faux(liste_jeu:IsShown(), "la liste du jeu est masquée")
	ns.Fenetre.fermer()
	autre:Click()
	B.avancer(0.1)
	T.faux(ns.Fenetre.estOuverte(), "les autres boutons du menu ne sont pas touchés")
	ns.Reglages.ecrire("acces.bouton_menu_echap", false)
	liste_jeu:Show()
	bouton:Click()
	B.avancer(0.1)
	T.faux(ns.Fenetre.estOuverte(), "réglage coupé : le jeu garde sa liste")
	T.vrai(liste_jeu:IsShown())
	T.sans_erreur()
end)

T.test("français et anglais : tous les textes de la fenêtre suivent la langue", function(B)
	local ns = B.demarrer({ locale = "enUS" })
	ns.Fenetre.ouvrir()
	local F = ns.Fenetre
	T.eq(F.boutonMode.etiquette:GetText(), "Mini version")
	T.eq(F.texteAttente:GetText(), "No pending change.")
	T.eq(ns.Vue.nomCategorie:GetText(), "All add-ons")
	T.eq(F.annuler.etiquette:GetText(), "Undo")
	ligne(ns, "Auctionator").case:Click()
	T.eq(F.recharger.etiquette:GetText(), "Reload (1)")
	T.eq(ns.Vue.fiche.etCommandes:GetText(), "")
	ligne(ns, "Auctionator"):Click()
	T.eq(ns.Vue.fiche.etCommandes:GetText(), "Commands")
	T.vrai(ns.Vue.fiche.resume:GetText():find("auction house"), "fiche en anglais")
	T.eq(ns.Vue.fiche.sous:GetText():find("Main add%-on") ~= nil, true)
	B.slash("/maa size compact")
	T.eq(F.cadre:GetWidth(), 660)
	T.sans_erreur()
	local fr = B.demarrer({ locale = "frFR" })
	fr.Fenetre.ouvrir()
	T.eq(fr.Fenetre.boutonMode.etiquette:GetText(), "Version mini")
end)

T.test("la fiche courte s'affiche en cliquant un add-on", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	T.eq(ns.Vue.fiche.resume:GetText(), "Choisis un add-on dans la liste pour lire sa fiche.")
	ligne(ns, "Auctionator"):Click()
	T.eq(ns.Vue.fiche.titre:GetText(), "Auctionator")
	T.vrai(ns.Vue.fiche.resume:GetText():find("Hôtel des ventes"), "résumé de la fiche")
	T.vrai(ns.Vue.fiche.commandes:GetText():find("/atr"), "commandes de la fiche")
	T.vrai(ns.Vue.fiche.sous:GetText():find("Hôtel des ventes"), "catégorie sous le titre")
	T.vrai(egal(ns.Vue.fiche.titre._couleur, couleur(ns, "parchemin_titre")), "encre du parchemin")
	T.sans_erreur()
end)

T.test("un add-on sans fiche montre ses notes ; rien ne casse sur toute la liste", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	for _, c in ipairs(ns.Liste.categories()) do
		categorie(ns, c.id):Click()
		for _, l in ipairs(ns.Vue.lignes) do
			if l.entree and l:IsShown() then
				ns.Vue.selection = l.entree.nom
				ns.Vue.rafraichirFiche()
			end
		end
	end
	T.sans_erreur()
	T.eq(ns.Vue.fiche.titre:GetText() ~= nil, true)
end)

T.fin()
