-- Fiche et infobulle (B2-02) : infobulle au survol, parchemin, note qui survit au /reload, fiche modifiable,
-- boutons « Ses réglages » et « Lien CurseForge », parties réglables, français et anglais.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function ligne(ns, nom)
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l.entree.nom == nom and l:IsShown() then return l end
	end
end

local function survoler(ns, nom)
	local l = ligne(ns, nom)
	T.vrai(l, "ligne visible : " .. nom)
	l:GetScript("OnEnter")(l)
	return l
end

local function tip_contient(morceau)
	for _, t in ipairs(GameTooltip.lignes) do
		if t:find(morceau, 1, true) then return true end
	end
	return false
end

local function ouvrir(B, opts)
	local ns = B.demarrer(opts)
	ns.Fenetre.ouvrir()
	return ns
end

-- simule la frappe dans un champ de saisie
local function saisir(box, texte)
	box:SetText(texte)
	box:GetScript("OnTextChanged")(box, true)
end

T.test("infobulle : survoler un add-on montre titre, résumé, commandes, badges et l'invitation au clic", function(B)
	local ns = ouvrir(B)
	local l = survoler(ns, "Auctionator")
	T.vrai(GameTooltip:IsShown(), "infobulle affichée")
	T.eq(GameTooltip._proprietaire, l)
	T.eq(GameTooltip.lignes[1], "Auctionator")
	T.vrai(tip_contient("Hôtel des ventes plus rapide"), "résumé")
	T.vrai(tip_contient("/atr"), "commandes")
	T.vrai(tip_contient("doublon actif"), "badge doublon actif (Naowh Forever : The Market)")
	T.vrai(tip_contient("NaowhForever_Market") or tip_contient("The Market") or tip_contient("Naowh"), "le doublon est nommé")
	T.vrai(tip_contient("Clic : fiche complète"))
	l:GetScript("OnLeave")(l)
	T.faux(GameTooltip:IsShown(), "infobulle cachée en quittant la ligne")
	T.sans_erreur()
end)

T.test("infobulle : un sous-module et un add-on sans fiche", function(B)
	local ns = ouvrir(B)
	ns.Vue.deplie["DBM-Core"] = true
	ns.Vue.rafraichirListe()
	survoler(ns, "DBM-GUI")
	T.vrai(tip_contient("Module"), "nature : module")
	T.vrai(tip_contient("DBM Core"), "dépendance citée")
	-- un add-on sans fiche : notes du .toc ou « pas encore de fiche », badge « sans fiche »
	local sans
	for _, e in ipairs(ns.Liste.lesRacines()) do if not e.fiche then sans = e break end end
	if sans then
		ns.Vue.selection = nil
		ns.Fenetre.memoire().categorie = "autres"
		ns.Vue.rafraichir()
		survoler(ns, sans.nom)
		T.vrai(tip_contient("sans fiche"))
	end
	T.sans_erreur()
end)

T.test("infobulle : coupée par le réglage, et chaque partie s'active ou se coupe", function(B)
	local ns = ouvrir(B)
	B.slash("/maa fiche infobulle non")
	T.faux(ns.Reglages.lire("fiche.infobulle"))
	local l = survoler(ns, "Auctionator")
	T.faux(GameTooltip:IsShown(), "pas d'infobulle")
	l:GetScript("OnLeave")(l)
	B.slash("/maa fiche infobulle oui")
	survoler(ns, "Auctionator")
	T.vrai(tip_contient("/atr"))
	B.slash("/maa fiche commandes non")
	T.faux(ns.Reglages.lire("fiche.parties.commandes"))
	survoler(ns, "Auctionator")
	T.faux(tip_contient("/atr"), "partie « commandes » coupée")
	T.vrai(tip_contient("Hôtel des ventes plus rapide"), "les autres restent")
	B.slash("/maa fiche commandes")
	T.vrai(ns.Reglages.lire("fiche.parties.commandes"), "sans valeur : on bascule")
	B.chat = {}
	B.slash("/maa fiche")
	T.vrai(B.chat_contient("infobulle : oui"))
	B.slash("/maa fiche note peut-etre")
	T.vrai(B.chat_contient("Usage : fiche infobulle"))
	T.sans_erreur()
end)

T.test("parchemin : la fiche complète d'un add-on, avec ses parties", function(B)
	local ns = ouvrir(B)
	B.charge["Auctionator"] = true
	B.memoire["Auctionator"] = 2048
	ligne(ns, "Auctionator"):Click()
	local f = ns.Vue.fiche
	T.eq(f.titre:GetText(), "Auctionator")
	T.vrai(f.sous:GetText():find("Add%-on principal"), "nature")
	T.vrai(f.badges:GetText():find("doublon actif"), "badge doublon")
	T.eq(f.etSert:GetText(), "À quoi il sert")
	T.vrai(f.resume:GetText():find("Hôtel des ventes"))
	T.vrai(f.commandes:GetText():find("/atr"))
	T.vrai(f.remarques:GetText():find("Naowh"))
	T.eq(f.etNote:GetText(), "Ma note")
	T.vrai(f.note:IsShown(), "champ de note visible")
	T.vrai(f.technique:GetText():find("Mémoire : 2.0 Mo"), "mémoire")
	T.vrai(f.technique:GetText():find("Version : "), "version")
	T.vrai(f.technique:GetText():find("Auteur : plusmouse"), "auteur")
	T.vrai(f.technique:GetText():find("État : chargé"), "état")
	T.vrai(f.technique:GetText():find("Utilité : confort"), "utilité")
	T.eq(f.etDoublons:GetText(), "Doublons actifs")
	T.vrai(f.doublons:GetText():find("The Market") or f.doublons:GetText():find("Naowh"), "doublon nommé")
	T.vrai(f.doublons:GetText():find("l'un ou l'autre suffit"), "explication du doublon")
	T.sans_erreur()
end)

T.test("parchemin : un sous-module montre sa dépendance et son état", function(B)
	local ns = ouvrir(B)
	ns.Vue.deplie["DBM-Core"] = true
	ns.Vue.rafraichirListe()
	ligne(ns, "DBM-GUI"):Click()
	local f = ns.Vue.fiche
	T.vrai(f.sous:GetText():find("Module"))
	T.eq(f.etDependances:GetText(), "Dépendances")
	T.vrai(f.dependances:GetText():find("DBM Core"), "dépendance : le titre de DBM-Core")
	T.vrai(f.dependances:GetText():find("activé"))
	-- on désactive la dépendance : le badge « dépendance à régler » apparaît
	ns.Liste.definir({ "DBM-Core" }, false)
	ns.Vue.rafraichirFiche()
	T.vrai(f.dependances:GetText():find("désactivé"))
	T.vrai(f.badges:GetText():find("dépendance à régler"))
	T.vrai(f.technique:GetText():find("État : activé"), "activé mais pas encore chargé")
	T.sans_erreur()
end)

T.test("note perso : écrite dans la fiche, elle survit au /reload et se voit dans l'infobulle", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Baganator"):Click()
	local f = ns.Vue.fiche
	T.eq(f.note:GetText(), "", "pas de note au départ")
	T.vrai(ns.Parchemin.indice:IsShown(), "invite de saisie")
	saisir(f.note, "Mon sac principal, à garder.")
	T.faux(ns.Parchemin.indice:IsShown(), "l'invite disparaît")
	T.vrai(f.badges:GetText():find("note perso"), "badge note")
	T.eq(ns.FicheModele.note("Baganator"), "Mon sac principal, à garder.")
	B.recharger()
	ns = B.ns
	ns.Fenetre.ouvrir()
	T.eq(MesAddonsDB.fiches.notes.Baganator, "Mon sac principal, à garder.", "gardée dans les sauvegardes")
	ligne(ns, "Baganator"):Click()
	T.eq(ns.Vue.fiche.note:GetText(), "Mon sac principal, à garder.", "revue après /reload")
	survoler(ns, "Baganator")
	T.vrai(tip_contient("Ma note : Mon sac principal"), "note dans l'infobulle")
	-- vider la note l'efface
	saisir(ns.Vue.fiche.note, "")
	T.eq(MesAddonsDB.fiches.notes.Baganator, nil)
	-- note trop longue : coupée
	saisir(ns.Vue.fiche.note, string.rep("x", 1500))
	T.eq(#ns.FicheModele.note("Baganator"), ns.Reglages.lire("fiche.note_max"))
	T.sans_erreur()
end)

T.test("fiche modifiable en jeu : ta version passe avant le fichier, rétablir revient à l'original", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Baganator"):Click()
	local original = ns.donnees.fiches.Baganator.fr.resume
	ns.Parchemin.boutons.modifier:Click()
	local v = ns.Parchemin.edition
	T.vrai(v:IsShown(), "éditeur ouvert")
	T.eq(v.champ_resume:GetText(), original, "préremplie avec la fiche actuelle")
	T.vrai(v.titre:GetText():find("Baganator"))
	T.faux(v.boutons.retablir.actif, "rien à rétablir au départ")
	saisir(v.champ_resume, "Mes sacs, tout en un.")
	v.boutons.enregistrer:Click()
	T.faux(v:IsShown(), "éditeur fermé")
	T.eq(ns.Vue.fiche.resume:GetText(), "Mes sacs, tout en un.")
	T.vrai(ns.Vue.fiche.badges:GetText():find("fiche modifiée"))
	T.eq(ns.donnees.fiches.Baganator.fr.resume, original, "le fichier de départ n'est pas touché")
	T.eq(MesAddonsDB.fiches.textes.Baganator.fr.resume, "Mes sacs, tout en un.")
	T.eq(MesAddonsDB.fiches.textes.Baganator.fr.commandes, nil, "seul ce qui change est gardé")
	survoler(ns, "Baganator")
	T.vrai(tip_contient("Mes sacs, tout en un."), "infobulle aussi")
	-- /reload : la version de Nykaro passe toujours avant
	B.recharger()
	ns = B.ns
	ns.Fenetre.ouvrir()
	ligne(ns, "Baganator"):Click()
	T.eq(ns.Vue.fiche.resume:GetText(), "Mes sacs, tout en un.", "survit au /reload")
	-- en anglais, la fiche d'origine (la modification est celle du français)
	B.recharger({ locale = "enUS" })
	ns = B.ns
	ns.Fenetre.ouvrir()
	ligne(ns, "Baganator"):Click()
	T.vrai(ns.Vue.fiche.resume:GetText():find("All bags merged"), "fiche anglaise intacte")
	-- retour au français, puis rétablir
	B.recharger({ locale = "frFR" })
	ns = B.ns
	ns.Fenetre.ouvrir()
	ligne(ns, "Baganator"):Click()
	ns.Parchemin.boutons.modifier:Click()
	T.vrai(ns.Parchemin.edition.boutons.retablir.actif, "rétablir possible")
	ns.Parchemin.edition.boutons.retablir:Click()
	T.eq(ns.Vue.fiche.resume:GetText(), original)
	T.eq(MesAddonsDB.fiches.textes.Baganator, nil, "plus rien de gardé")
	-- enregistrer sans rien changer ne crée pas de version modifiée
	ns.Parchemin.boutons.modifier:Click()
	ns.Parchemin.edition.boutons.enregistrer:Click()
	T.eq(MesAddonsDB.fiches.textes.Baganator, nil)
	T.sans_erreur()
end)

T.test("changer d'add-on ferme l'éditeur ; cocher une case ne perd pas ce qu'on écrit", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Baganator"):Click()
	ns.Parchemin.boutons.modifier:Click()
	saisir(ns.Parchemin.edition.champ_resume, "en cours")
	ligne(ns, "Auctionator").case:Click() -- rafraîchit la fenêtre
	T.vrai(ns.Parchemin.edition:IsShown(), "l'éditeur reste ouvert")
	T.eq(ns.Parchemin.edition.champ_resume:GetText(), "en cours")
	ligne(ns, "Auctionator"):Click()
	T.faux(ns.Parchemin.edition:IsShown(), "autre add-on : éditeur fermé")
	T.eq(ns.FicheModele.modifs("Baganator"), nil, "rien enregistré sans clic sur Enregistrer")
	T.sans_erreur()
end)

T.test("Ses réglages : lance la commande de l'add-on s'il est chargé", function(B)
	local ns = ouvrir(B)
	local appels = 0
	SlashCmdList["ATR"] = function(texte) appels = appels + 1 end
	_G["SLASH_ATR1"] = "/atr"
	_G["SLASH_ATR2"] = "/auctionator"
	ligne(ns, "Auctionator"):Click()
	B.chat = {}
	ns.Parchemin.boutons.reglages:Click()
	T.eq(appels, 0, "add-on pas chargé : rien n'est lancé")
	T.vrai(B.chat_contient("n'est pas chargé"))
	B.charge["Auctionator"] = true
	B.chat = {}
	ns.Parchemin.boutons.reglages:Click()
	T.eq(appels, 1, "commande /atr lancée")
	T.vrai(B.chat_contient("Réglages de Auctionator ouverts (/atr)"))
	-- une commande introuvable dans le jeu : message clair
	B.charge["Baganator"] = true
	ligne(ns, "Baganator"):Click()
	B.chat = {}
	ns.Parchemin.boutons.reglages:Click()
	T.vrai(B.chat_contient("Pas de réglages connus"))
	-- une commande qui plante : pas d'erreur chez nous
	SlashCmdList["BGR"] = function() error("boum") end
	_G["SLASH_BGR1"] = "/bgr"
	B.chat = {}
	ns.Parchemin.boutons.reglages:Click()
	T.vrai(B.chat_contient("Impossible d'ouvrir"))
	T.sans_erreur()
end)

T.test("Lien CurseForge : affiche l'adresse à copier, sans pouvoir la changer", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Auctionator"):Click()
	T.vrai(ns.Parchemin.boutons.curseforge.actif)
	ns.Parchemin.boutons.curseforge:Click()
	local v = ns.Parchemin.volet_lien
	T.vrai(v:IsShown(), "volet du lien ouvert")
	T.eq(v.adresseBox:GetText(), "https://www.curseforge.com/wow/addons/auctionator")
	T.vrai(v.titre:GetText():find("Auctionator"))
	T.vrai(v.aide:GetText():find("Ctrl+C", 1, true))
	v.adresseBox:SetText("n'importe quoi")
	v.adresseBox:GetScript("OnTextChanged")(v.adresseBox, true)
	T.eq(v.adresseBox:GetText(), "https://www.curseforge.com/wow/addons/auctionator", "l'adresse ne se modifie pas")
	v.boutons.fermer:Click()
	T.faux(v:IsShown())
	-- une fiche sans adresse : bouton grisé
	local sans
	for _, e in ipairs(ns.Liste.entrees()) do
		if ns.FicheModele.lien(e) == "" then sans = e break end
	end
	T.vrai(sans, "il existe un add-on sans adresse")
	ns.Vue.selection = sans.nom
	ns.Vue.rafraichirFiche()
	T.faux(ns.Parchemin.boutons.curseforge.actif)
	T.sans_erreur()
end)

T.test("parties de la fiche : chacune se coupe dans les réglages", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Auctionator"):Click()
	local f = ns.Vue.fiche
	local cas = {
		{ "resume", function() return f.resume:GetText() == "" and f.etSert:GetText() == "" end },
		{ "commandes", function() return f.commandes:GetText() == "" and f.etCommandes:GetText() == "" end },
		{ "remarques", function() return f.remarques:GetText() == "" end },
		{ "note", function() return f.etNote:GetText() == "" and not ns.Parchemin.el("note").vu end },
		{ "technique", function() return f.technique:GetText() == "" end },
		{ "doublons", function() return f.doublons:GetText() == "" end },
		{ "badges", function() return f.badges:GetText() == "" end },
	}
	for _, c in ipairs(cas) do
		T.faux(c[2](), c[1] .. " visible au départ")
		B.slash("/maa fiche " .. c[1] .. " non")
		ns.Vue.rafraichirFiche()
		T.vrai(c[2](), c[1] .. " coupée")
		B.slash("/maa fiche " .. c[1] .. " oui")
		ns.Vue.rafraichirFiche()
		T.faux(c[2](), c[1] .. " rétablie")
	end
	-- les dépendances, sur un module
	ns.Vue.deplie["DBM-Core"] = true
	ns.Vue.rafraichirListe()
	ligne(ns, "DBM-GUI"):Click()
	T.faux(f.dependances:GetText() == "")
	B.slash("/maa fiche dependances non")
	ns.Vue.rafraichirFiche()
	T.eq(f.dependances:GetText(), "")
	T.sans_erreur()
end)

T.test("les réglages de la fiche sont gardés d'une session à l'autre", function(B)
	local ns = ouvrir(B)
	B.slash("/maa fiche technique non")
	B.slash("/maa fiche infobulle non")
	B.recharger()
	T.faux(B.ns.Reglages.lire("fiche.parties.technique"))
	T.faux(B.ns.Reglages.lire("fiche.infobulle"))
	T.vrai(B.ns.Reglages.lire("fiche.parties.note"))
end)

T.test("français et anglais : infobulle, parchemin et boutons suivent la langue", function(B)
	local ns = ouvrir(B, { locale = "enUS" })
	B.charge["Auctionator"] = true
	ligne(ns, "Auctionator"):Click()
	local f = ns.Vue.fiche
	T.eq(f.etSert:GetText(), "What it does")
	T.eq(f.etNote:GetText(), "My note")
	T.vrai(f.badges:GetText():find("active duplicate"))
	T.vrai(f.technique:GetText():find("Version: "))
	T.eq(ns.Parchemin.boutons.reglages.etiquette:GetText(), "Its settings")
	T.eq(ns.Parchemin.boutons.curseforge.etiquette:GetText(), "CurseForge link")
	T.eq(ns.Parchemin.boutons.modifier.etiquette:GetText(), "Edit sheet")
	survoler(ns, "Auctionator")
	T.vrai(tip_contient("Click: full sheet"))
	T.vrai(tip_contient("Faster auction house") or tip_contient("auction house"))
	ns.Parchemin.boutons.modifier:Click()
	T.vrai(ns.Parchemin.edition.titre:GetText():find("Edit the sheet of Auctionator"))
	T.vrai(ns.Parchemin.edition.aide:GetText():find("English"))
	T.sans_erreur()
end)

T.test("couleurs du parchemin : l'encre suit le thème, aucune erreur sur toute la liste, dans les deux langues", function(B)
	for _, locale in ipairs({ "frFR", "enUS" }) do
		local ns = ouvrir(B, { locale = locale })
		ns.Fenetre.memoire().categorie = "tous"
		for _, e in ipairs(ns.Liste.entrees()) do
			ns.Vue.selection = e.nom
			ns.Vue.rafraichirFiche()
			ns.Infobulle.lignes(e)
			T.vrai(ns.Vue.fiche.titre:GetText() ~= nil)
		end
		B.slash("/maa theme alliance")
		T.sans_erreur()
	end
end)

T.test("la zone qui défile suit la hauteur du contenu", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Auctionator"):Click()
	local court = ns.Parchemin.zone.contenu:GetHeight()
	saisir(ns.Vue.fiche.note, string.rep("beaucoup de texte ", 40))
	T.vrai(ns.Parchemin.zone.contenu:GetHeight() > court, "le champ de note grandit avec son texte")
	T.sans_erreur()
end)

T.test("note : curseur visible pendant la saisie, « Tout effacer » et « Annuler »", function(B)
	local ns = ouvrir(B)
	ligne(ns, "Baganator"):Click()
	local n = ns.Vue.fiche.note
	saisir(n, "Première version")
	-- on entre dans la case : le curseur apparaît, le texte d'avant est retenu
	n:GetScript("OnEditFocusGained")(n)
	T.vrai(n.curseur:IsShown(), "curseur visible")
	saisir(n, "Première version, modifiée")
	ns.Parchemin.boutonsNote.annuler:Click()
	T.eq(n:GetText(), "Première version", "Annuler revient au texte d'avant")
	T.eq(ns.FicheModele.note("Baganator"), "Première version")
	ns.Parchemin.boutonsNote.effacer:Click()
	T.eq(n:GetText(), "", "Tout effacer vide la note")
	T.eq(ns.FicheModele.note("Baganator"), "")
	ns.Parchemin.boutonsNote.annuler:Click()
	T.eq(n:GetText(), "Première version", "et Annuler la rend")
	n:GetScript("OnEditFocusLost")(n)
	T.faux(n.curseur:IsShown(), "curseur caché hors saisie")
	T.sans_erreur()
end)

T.fin()
