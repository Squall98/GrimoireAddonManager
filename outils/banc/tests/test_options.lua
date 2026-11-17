-- Panneau d'options (volet de la fenêtre et page du jeu) : tous les réglages, leur effet, leur survie au /reload (B2-03).
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function ouvrir(B, opts)
	local ns = B.demarrer(opts)
	ns.Fenetre.ouvrir()
	ns.Options.ouvrirVolet()
	T.sans_erreur()
	return ns
end

local function ligne(ns, chemin)
	for _, l in ipairs(ns.Options.instVolet.lignes) do
		if l.el.chemin == chemin then return l end
	end
end

local function ligne_action(ns, action)
	for _, l in ipairs(ns.Options.instVolet.lignes) do
		if l.el.action == action then return l end
	end
end

-- Tous les réglages de départ, en chemins (« fenetre.theme », « liste.recherche.nom »…).
local function feuilles(t, prefixe, res)
	res = res or {}
	for k, v in pairs(t) do
		local chemin = prefixe and (prefixe .. "." .. k) or k
		if type(v) == "table" and v[1] == nil and next(v) ~= nil then
			feuilles(v, chemin, res)
		else
			res[#res + 1] = chemin
		end
	end
	table.sort(res)
	return res
end

local function visible(ns, nom)
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l.entree.nom == nom and l:IsShown() then return l end
	end
end

T.test("la page d'options regroupe tous les réglages créés, sauf ceux qu'elle exclut en le disant", function(B)
	local ns = B.demarrer()
	local dans = {}
	local n = 0
	for _, g in ipairs(ns.donnees.options.groupes) do
		for _, el in ipairs(g.elements) do
			if el.chemin then dans[el.chemin] = el end
			n = n + 1
		end
	end
	local manquants = {}
	for _, chemin in ipairs(feuilles(ns.donnees.reglages.defauts)) do
		if not dans[chemin] and not ns.donnees.options.exclus[chemin] then manquants[#manquants + 1] = chemin end
	end
	T.eq(table.concat(manquants, ", "), "", "réglages sans option")
	for chemin in pairs(ns.donnees.options.exclus) do
		T.vrai(not dans[chemin], "un réglage exclu n'est pas aussi dans le schéma : " .. chemin)
	end
	T.vrai(n >= 80, "au moins 80 éléments : " .. n)
	-- chaque réglage de fenetre.*, acces.* et fiche.* y est
	for _, chemin in ipairs(feuilles(ns.donnees.reglages.defauts)) do
		if chemin:find("^fenetre%.") or chemin:find("^acces%.") or chemin:find("^fiche%.") then
			T.vrai(dans[chemin], "dans les options : " .. chemin)
		end
	end
end)

T.test("chaque option a son texte en français et en anglais", function(B)
	local ns = B.demarrer()
	for _, code in ipairs({ "frFR", "enUS" }) do
		local t = ns.donnees.textes[code]
		for _, g in ipairs(ns.donnees.options.groupes) do
			T.vrai(t["opt.groupe." .. g.id], code .. " : groupe " .. g.id)
			for _, el in ipairs(g.elements) do
				if el.chemin then T.vrai(t["opt." .. el.chemin], code .. " : " .. el.chemin) end
				if el.action then T.vrai(t["opt.action." .. el.action], code .. " : action " .. el.action) end
				for _, v in ipairs(el.choix or {}) do
					T.vrai(t[string.format(el.texte_choix, v)], code .. " : choix " .. el.chemin .. "=" .. v)
				end
			end
		end
	end
end)

T.test("le volet s'ouvre dans la fenêtre : un contrôle par option, rien ne casse", function(B)
	local ns = ouvrir(B)
	T.vrai(ns.Options.voletOuvert())
	local attendu = 0
	for _, g in ipairs(ns.donnees.options.groupes) do attendu = attendu + #g.elements end
	T.eq(#ns.Options.instVolet.lignes, attendu, "une ligne par élément du schéma")
	T.eq(ns.Options.volet.titre:GetText(), "Options de Grimoire Addon Manager")
	T.eq(ns.Options.volet.retour.etiquette:GetText(), "Retour")
	T.eq(ligne(ns, "fenetre.theme").bouton.etiquette:GetText(), "auto")
	T.eq(ligne(ns, "fenetre.compact").texte:GetText(), "Version mini (liste seule)")
	T.vrai(ligne(ns, "fenetre.modules_replies").case:GetChecked(), "case cochée = réglage actif")
	ns.Options.volet.retour:Click()
	T.faux(ns.Options.voletOuvert(), "Retour ferme le volet")
	B.slash("/maa options")
	T.vrai(ns.Options.voletOuvert(), "/maa options")
	T.sans_erreur()
end)

T.test("chaque option se change par son contrôle, change vraiment le réglage, et survit au /reload", function(B)
	local ns = ouvrir(B)
	local attendu = {}
	local essayees = 0
	for _, g in ipairs(ns.donnees.options.groupes) do
		for _, el in ipairs(g.elements) do
			local l = ligne(ns, el.chemin)
			if el.chemin then
				T.vrai(l, "ligne de " .. el.chemin)
				local avant = ns.Reglages.lire(el.chemin)
				if el.type == "bool" then
					l.case:Click()
				elseif el.type == "choix" then
					l.bouton:Click()
				elseif el.type == "nombre" then
					-- vers le haut, sauf au maximum
					if avant >= el.max then l.moins:Click() else l.plus:Click() end
				elseif el.type == "texte" then
					l.champ:SetText("00ff00")
					l.champ._scripts.OnEnterPressed(l.champ)
				elseif el.type == "commandes" then
					l.champ:SetText("maa mesaddons ajout")
					l.champ._scripts.OnEnterPressed(l.champ)
				end
				T.sans_erreur()
				local apres = ns.Reglages.lire(el.chemin)
				if type(avant) == "table" then
					T.eq(#apres, 3, el.chemin .. " : 3 commandes")
					attendu[el.chemin] = table.concat(apres, " ")
				else
					T.vrai(apres ~= avant, el.chemin .. " a changé (" .. tostring(avant) .. " -> " .. tostring(apres) .. ")")
					attendu[el.chemin] = apres
				end
				essayees = essayees + 1
			end
		end
	end
	T.vrai(essayees >= 75, "options essayées : " .. essayees)
	ns = B.recharger()
	for chemin, valeur in pairs(attendu) do
		local v = ns.Reglages.lire(chemin)
		if type(v) == "table" then v = table.concat(v, " ") end
		T.eq(v, valeur, "après /reload : " .. chemin)
	end
	T.sans_erreur()
end)

T.test("les réglages de la fenêtre ont un effet visible tout de suite", function(B)
	local ns = ouvrir(B, { faction = "Horde" })
	ligne(ns, "fenetre.theme").bouton:Click() -- auto -> horde
	T.eq(ns.Reglages.lire("fenetre.theme"), "horde")
	ligne(ns, "fenetre.theme").bouton:Click() -- alliance
	T.eq(ns.Style.theme(), "alliance", "le thème change l'affichage")
	-- taille de départ
	local avant = ns.Fenetre.cadre:GetWidth()
	ligne(ns, "fenetre.taille").bouton:Click() -- moyenne
	T.vrai(ns.Fenetre.cadre:GetWidth() < avant, "taille moyenne plus petite")
	T.eq(ns.Fenetre.cadre:GetWidth(), ns.donnees.reglages.interface.tailles.moyenne.l)
	-- police
	ligne(ns, "fenetre.police").bouton:Click()
	T.vrai(ns.Fenetre.titre._police[1]:find("MORPHEUS"), "police gothique")
	-- version mini
	ligne(ns, "fenetre.compact").case:Click()
	T.eq(ns.Fenetre.mode(), "mini")
	ligne(ns, "fenetre.compact").case:Click()
	T.eq(ns.Fenetre.mode(), "complet")
	-- Échap
	ligne(ns, "fenetre.fermer_avec_echap").case:Click()
	T.faux(#UISpecialFrames > 0 and (function() for _, n in ipairs(UISpecialFrames) do if n == ns.donnees.reglages.interface.nom_cadre then return true end end end)(), "Échap ne ferme plus")
	-- modules repliés : DBM déplié, sans clic
	ligne(ns, "fenetre.modules_replies").case:Click()
	ns.Options.fermerVolet()
	ns.Fenetre.memoire().categorie = "tous"
	ns.Vue.deplie = {}
	ns.Fenetre.rafraichir()
	T.vrai(visible(ns, "DBM-GUI"), "modules dépliés au départ")
	-- bouton de la minicarte
	ligne(ns, "acces.bouton_minicarte").case:Click()
	T.faux(ns.Acces.bouton:IsShown(), "bouton de la minicarte caché")
	ligne(ns, "acces.angle_minicarte").plus:Click()
	T.eq(ns.Reglages.lire("acces.angle_minicarte"), 215)
	T.sans_erreur()
end)

T.test("les réglages de la liste ont un effet visible tout de suite", function(B)
	local ns = ouvrir(B)
	ns.Options.fermerVolet()
	local function a_puce(id)
		for _, e in ipairs(ns.Barre.entreesFiltre()) do if e.id == id then return true end end
		return false
	end
	T.vrai(a_puce("favoris"))
	ns.Options.ouvrirVolet()
	ligne(ns, "liste.filtres_visibles.favoris").case:Click()
	T.faux(a_puce("favoris"), "puce Favoris retirée")
	ligne(ns, "liste.filtres_visibles.erreurs").case:Click()
	T.vrai(a_puce("erreurs"), "puce Erreurs ajoutée")
	-- colonnes
	ligne(ns, "liste.colonnes.icone").case:Click()
	T.faux(visible(ns, "Auctionator").icone:IsShown(), "icône cachée")
	ligne(ns, "liste.colonnes.icone").case:Click()
	T.vrai(visible(ns, "Auctionator").icone:IsShown(), "icône de retour")
	-- mémoire
	ns.Fenetre.memoire().categorie = "tous"
	B.charge.TomTom = true
	B.memoire.TomTom = 2048
	ligne(ns, "liste.colonnes.memoire").case:Click()
	T.vrai(visible(ns, "TomTom").marque:GetText():find("2.0 Mo", 1, true) or visible(ns, "TomTom").marque:GetText():find("Mo", 1, true), "mémoire affichée : " .. visible(ns, "TomTom").marque:GetText())
	-- tri
	ligne(ns, "liste.tri").bouton:Click()
	T.eq(ns.Reglages.lire("liste.tri"), "categorie")
	ligne(ns, "liste.tri_inverse").case:Click()
	T.vrai(ns.Reglages.lire("liste.tri_inverse"))
	T.eq(ns.Barre.tri.etiquette:GetText(), "Tri : Catégorie (inversé)", "le bouton de tri suit l'option")
	-- badges (max)
	ligne(ns, "liste.badges_max").plus:Click()
	T.eq(ns.Reglages.lire("liste.badges_max"), 3)
	-- retour à 0 : minimum respecté
	for _ = 1, 10 do ligne(ns, "liste.badges_max").moins:Click() end
	T.eq(ns.Reglages.lire("liste.badges_max"), 0, "minimum respecté")
	for _ = 1, 20 do ligne(ns, "liste.badges_max").plus:Click() end
	T.eq(ns.Reglages.lire("liste.badges_max"), 6, "maximum respecté")
	T.sans_erreur()
end)

T.test("la langue et le message de chargement se règlent dans les options", function(B)
	local ns = ouvrir(B)
	ligne(ns, "langue.choix").bouton:Click() -- auto -> frFR
	ligne(ns, "langue.choix").bouton:Click() -- -> enUS
	T.eq(ns.Reglages.lire("langue.choix"), "enUS")
	T.eq(ligne(ns, "fenetre.theme").texte:GetText(), "Theme", "options en anglais")
	T.eq(ns.Options.volet.titre:GetText(), "Grimoire Addon Manager options")
	T.eq(ns.Barre.options.etiquette:GetText(), "Options")
	T.eq(ns.Barre.tri.etiquette:GetText(), "Sort: Name", "barre en anglais")
	-- clic droit = valeur précédente
	local b = ligne(ns, "langue.choix").bouton
	b._scripts.OnClick(b, "RightButton")
	T.eq(ns.Reglages.lire("langue.choix"), "frFR", "clic droit : choix précédent")
	-- message de chargement
	ligne(ns, "affichage.message_chargement").case:Click()
	ns = B.recharger()
	T.faux(B.chat_contient("chargé. Tape"), "plus de message au chargement")
	-- couleur du préfixe
	ns.Options.ouvrirVolet()
	local l = ligne(ns, "affichage.couleur_prefixe")
	l.champ:SetText("zzz")
	l.champ._scripts.OnEnterPressed(l.champ)
	T.eq(ns.Reglages.lire("affichage.couleur_prefixe"), "ffd100", "couleur invalide refusée")
	T.vrai(B.chat_contient("Couleur invalide"))
	l.champ:SetText("00FF00")
	l.champ._scripts.OnEnterPressed(l.champ)
	T.eq(ns.Reglages.lire("affichage.couleur_prefixe"), "00ff00")
	B.chat = {}
	ns.dire("test")
	T.vrai(B.chat[1]:find("00ff00", 1, true), "la couleur du préfixe change le chat")
end)

T.test("commandes d'ouverture : une commande déjà prise est signalée, avec une autre proposée", function(B)
	local ns = ouvrir(B)
	local l = ligne(ns, "commandes.liste")
	T.vrai(l.etat:GetText():find("/maa : libre, active", 1, true), "état au départ : " .. l.etat:GetText())
	l.champ:SetText("ma maa")
	l.champ._scripts.OnEnterPressed(l.champ)
	local etat = l.etat:GetText()
	T.vrai(etat:find("/ma : déjà prise", 1, true), "ma est prise par le jeu : " .. etat)
	T.vrai(etat:find("Essaie /ma2", 1, true), "propose ma2 : " .. etat)
	T.vrai(etat:find("/maa : libre, active", 1, true))
	T.eq(ns.Commandes.principale(), "maa", "seule /maa est enregistrée")
	T.eq(ns.Options.proposer("ma", { "ma" }), "ma2")
	l.champ:SetText("mes 'x")
	l.champ._scripts.OnEnterPressed(l.champ)
	T.vrai(l.etat:GetText():find("nom invalide", 1, true), "nom invalide signalé")
	l.champ:SetText("")
	l.champ._scripts.OnEnterPressed(l.champ)
	T.vrai(l.etat:GetText():find("Aucune commande", 1, true), "plus aucune commande")
	-- la commande seule ouvre la fenêtre, ou les options
	l.champ:SetText("maa")
	l.champ._scripts.OnEnterPressed(l.champ)
	ligne(ns, "commandes.sans_argument").bouton:Click() -- ouvrir -> aide
	T.eq(ns.Reglages.lire("commandes.sans_argument"), "aide")
	ligne(ns, "commandes.sans_argument").bouton:Click() -- -> options
	ns.Options.fermerVolet()
	B.slash("/maa")
	T.vrai(ns.Options.voletOuvert(), "/maa tout seul ouvre les options")
	T.sans_erreur()
end)

T.test("la page du menu Échap › Options › AddOns existe et reprend les mêmes réglages", function(B)
	local ns = B.demarrer()
	T.eq(#B.parametres.categories, 1, "une page enregistrée")
	local cat = B.parametres.categories[1]
	T.eq(cat.nom, "Grimoire Addon Manager")
	T.vrai(cat.ajoutee, "enregistrée comme page d'add-on")
	local page = cat.cadre
	T.vrai(page == ns.Options.page)
	page._scripts.OnShow(page)
	T.sans_erreur()
	local attendu = 0
	for _, g in ipairs(ns.donnees.options.groupes) do attendu = attendu + #g.elements end
	T.eq(#page.inst.lignes, attendu, "autant de réglages que dans la fenêtre")
	T.eq(page.titre:GetText(), "Options de Grimoire Addon Manager")
	-- un changement dans la page se voit dans la fenêtre, et l'inverse
	ns.Fenetre.ouvrir()
	ns.Options.ouvrirVolet()
	local dans_page
	for _, l in ipairs(page.inst.lignes) do if l.el.chemin == "liste.tri" then dans_page = l end end
	dans_page.bouton:Click()
	T.eq(ns.Reglages.lire("liste.tri"), "categorie")
	T.eq(ligne(ns, "liste.tri").bouton.etiquette:GetText(), "Catégorie", "le volet suit la page")
	T.eq(ns.Barre.tri.etiquette:GetText(), "Tri : Catégorie", "la barre aussi")
	-- ouverture
	B.slash("/maa options jeu")
	T.eq(B.parametres.ouvertures[1], 1, "la page du jeu est ouverte")
	-- « Ouvrir Grimoire Addon Manager » depuis la page
	ns.Fenetre.fermer()
	page.ouvrir:Click()
	T.vrai(ns.Fenetre.estOuverte())
end)

T.test("remettre toutes les valeurs de départ demande confirmation, et garde les favoris et notes", function(B)
	local ns = ouvrir(B)
	ligne(ns, "fenetre.theme").bouton:Click()
	ligne(ns, "liste.tri").bouton:Click()
	ligne(ns, "journal.taille_max").plus:Click()
	ns.Recherche.basculerFavori("TomTom")
	ns.FicheModele.definirNote("TomTom", "ma note")
	local b = ligne_action(ns, "tout_reinitialiser")
	b.bouton:Click()
	T.eq(b.bouton.etiquette:GetText(), "Confirmer ?", "premier clic = demande")
	T.eq(ns.Reglages.lire("liste.tri"), "categorie", "rien n'a bougé")
	b.bouton:Click()
	T.eq(ns.Reglages.lire("liste.tri"), "nom", "tri remis")
	T.eq(ns.Reglages.lire("fenetre.theme"), "auto", "thème remis")
	T.eq(ns.Reglages.lire("journal.taille_max"), 200)
	T.vrai(ns.Recherche.favori("TomTom"), "favoris gardés")
	T.eq(ns.FicheModele.note("TomTom"), "ma note", "notes gardées")
	T.eq(ligne(ns, "liste.tri").bouton.etiquette:GetText(), "Nom", "le volet est à jour")
	-- vider le journal : même précaution
	local j = ligne_action(ns, "effacer_journal")
	j.bouton:Click()
	T.vrai(#ns.Journal.lignes() > 0, "pas encore vidé")
	j.bouton:Click()
	T.eq(#ns.Journal.lignes(), 0, "journal vidé")
	-- oublier les tailles
	ns.Fenetre.cadre:SetSize(500, 400)
	ns.Fenetre.memoire().tailles.complet = { l = 500, h = 400 }
	ligne_action(ns, "reinit_tailles").bouton:Click()
	T.eq(ns.Fenetre.cadre:GetWidth(), ns.donnees.reglages.interface.tailles.grande.l, "taille de départ retrouvée")
	T.sans_erreur()
end)

T.test("marquer tout comme vu depuis les options", function(B)
	local ns = ouvrir(B)
	MesAddonsDB.liste.versions.TomTom = "ancienne"
	MesAddonsDB.liste.connus.Baganator = nil
	ns.ReglagesTmp = nil
	ns.Reglages.ecrire("liste.nouveau_sans_fiche", false)
	T.vrai(ns.Recherche.misAJour(ns.Liste.parNom("TomTom")))
	T.vrai(ns.Recherche.nouveau(ns.Liste.parNom("Baganator")))
	ligne_action(ns, "tout_vu").bouton:Click()
	T.faux(ns.Recherche.misAJour(ns.Liste.parNom("TomTom")))
	T.faux(ns.Recherche.nouveau(ns.Liste.parNom("Baganator")))
	T.sans_erreur()
end)

T.test("options humaines : onglets en colonne, essentiel d'abord, réglages avancés sur demande, cartes par groupe", function(B)
	local ns = ouvrir(B)
	local inst = ns.Options.instVolet
	T.faux(ns.Reglages.lire("options.avances"), "avancés cachés au départ")
	inst.montrer("liste")
	local l = ligne(ns, "liste.recherche.distance")
	T.vrai(l.el.avance and not l:IsShown(), "réglage fin caché")
	T.vrai(ligne(ns, "liste.grouper_tous"):IsShown(), "réglage de tous les jours visible")
	local cachees = 0
	for _, c in ipairs(inst.cartes) do if c.groupe == "badges" and not c:IsShown() then cachees = cachees + 1 end end
	T.eq(cachees, 1, "groupe sans réglage visible : carte cachée")
	inst.caseAvances:Click()
	T.sans_erreur()
	T.vrai(ns.Reglages.lire("options.avances"))
	T.vrai(ligne(ns, "liste.recherche.distance"):IsShown(), "avancés montrés")
	inst.caseAvances:Click()
	T.faux(ligne(ns, "liste.recherche.distance"):IsShown())
end)

T.test("colonnes repliables (boutons du bandeau et options), bouton Vue, taille du texte", function(B)
	local ns = ouvrir(B)
	ns.Options.fermerVolet()
	local F, V = ns.Fenetre, ns.Vue
	T.vrai(F.panneauCats:IsShown() and F.panneauFiche:IsShown())
	V.replierCats:Click()
	T.sans_erreur()
	T.faux(F.panneauCats:IsShown(), "catégories repliées")
	T.vrai(ns.Reglages.lire("fenetre.cats_repliee"))
	V.replierFiche:Click()
	T.faux(F.panneauFiche:IsShown(), "fiche repliée")
	V.replierCats:Click()
	V.replierFiche:Click()
	T.vrai(F.panneauCats:IsShown() and F.panneauFiche:IsShown(), "dépliées")
	-- bouton Vue : bascule entre catégories et liste
	T.vrai(ns.Reglages.lire("liste.grouper_tous"))
	ns.Deroulant.ouvrir(ns.Barre.vue)
	ns.Deroulant.lignes[2]:Click()
	T.faux(ns.Reglages.lire("liste.grouper_tous"), "vue en liste")
	ns.Deroulant.ouvrir(ns.Barre.vue)
	ns.Deroulant.lignes[1]:Click()
	T.vrai(ns.Reglages.lire("liste.grouper_tous"))
	-- tout activer / tout désactiver
	ns.Fenetre.toutActiver:Click()
	for _, e in ipairs(ns.Liste.entrees()) do
		if not e.inutile then T.vrai(ns.Liste.actif(e.nom), "tout activé : " .. e.nom) end
	end
	ns.Fenetre.toutDesactiver:Click()
	for _, e in ipairs(ns.Liste.entrees()) do
		T.eq(ns.Liste.actif(e.nom), e.moi and true or false, "tout désactivé sauf Grimoire Addon Manager : " .. e.nom)
	end
	ns.Fenetre.annuler:Click()
	T.sans_erreur()
	-- taille du texte
	local n = ns.Style.taille("normal")
	ns.Options.definir("fenetre.taille_texte", "grande", "peindre")
	T.vrai(ns.Style.taille("normal") > n, "texte plus grand")
	ns.Options.definir("fenetre.taille_texte", "petite", "peindre")
	T.vrai(ns.Style.taille("normal") < n, "texte plus petit")
	T.sans_erreur()
end)

T.fin()
