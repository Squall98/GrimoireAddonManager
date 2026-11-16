-- Recherche, tris, filtres, favoris, étiquettes, badges, raison en clair, menu du clic droit (B2-03).
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function noms(res)
	local t = {}
	for _, r in ipairs(res) do t[#t + 1] = r.e.nom end
	return t
end

local function contient(liste, nom)
	for _, n in ipairs(liste) do if n == nom then return true end end
	return false
end

local function rangs(ns)
	local t = {}
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l:IsShown() and l.niveau == 0 then t[#t + 1] = l.entree.nom end
	end
	return t
end

local function ligne(ns, nom)
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l.entree.nom == nom and l:IsShown() then return l end
	end
end

-- Ouvre une liste déroulante de la barre et clique l'entrée `id`.
local function choisir(ns, bouton, id)
	ns.Deroulant.ouvrir(bouton)
	for _, l in ipairs(ns.Deroulant.lignes) do
		if l:IsShown() and l.entree and l.entree.id == id then return l:Click() end
	end
	error("entrée absente : " .. tostring(id))
end

local function taper(ns, texte)
	ns.Barre.champ:SetText(texte)
end

local function ouvrir(opts)
	local B = opts.B
	local ns = B.demarrer(opts.demarrage)
	ns.Fenetre.ouvrir()
	T.sans_erreur()
	return ns
end

local function sans_fiche(ns)
	for _, e in ipairs(ns.Liste.entrees()) do if not e.fiche and not e.moi then return e end end
end

T.test("« pêche » trouve les deux add-ons de pêche", function(B)
	local ns = ouvrir({ B = B })
	local trouves = noms(ns.Recherche.chercher("pêche"))
	T.vrai(contient(trouves, "BetterFishing"), "BetterFishing")
	T.vrai(contient(trouves, "FishyWashy"), "FishyWashy")
	-- dans la fenêtre : la barre de recherche filtre la liste, toutes catégories confondues
	taper(ns, "pêche")
	T.sans_erreur()
	local r = rangs(ns)
	T.vrai(contient(r, "BetterFishing") and contient(r, "FishyWashy"), "les deux sont affichés")
	T.eq(#r, #trouves, "la liste affiche exactement les résultats")
	T.vrai(ns.Vue.nomCategorie:GetText():find("Résultats : " .. #trouves, 1, true), "bandeau « Résultats »")
	-- effacer remet tout
	ns.Barre.effacer:Click()
	T.eq(ns.Barre.champ:GetText(), "")
	T.vrai(#rangs(ns) > #r, "liste complète de nouveau")
end)

T.test("« /way » trouve TomTom (recherche par commande)", function(B)
	local ns = ouvrir({ B = B })
	local res = noms(ns.Recherche.chercher("/way"))
	T.vrai(contient(res, "TomTom"), "TomTom trouvé")
	T.eq(res[1], "TomTom", "TomTom en premier")
	taper(ns, "/way")
	T.vrai(contient(rangs(ns), "TomTom"))
	T.eq(#rangs(ns), #res)
end)

T.test("la recherche tolère les fautes de frappe, et se règle", function(B)
	local ns = ouvrir({ B = B })
	T.vrai(contient(noms(ns.Recherche.chercher("pehce")), "BetterFishing"), "lettres échangées")
	T.vrai(contient(noms(ns.Recherche.chercher("/wya")), "TomTom"), "commande avec faute")
	T.vrai(contient(noms(ns.Recherche.chercher("auctionnator")), "Auctionator"), "lettre en trop dans le nom")
	T.faux(contient(noms(ns.Recherche.chercher("zzzxqj")), "TomTom"), "mot sans rapport")
	ns.Reglages.ecrire("liste.recherche.tolerance", false)
	T.faux(contient(noms(ns.Recherche.chercher("pehce")), "BetterFishing"), "tolérance coupée")
	ns.Reglages.ecrire("liste.recherche.tolerance", true)
	ns.Reglages.ecrire("liste.recherche.distance", 0)
	T.faux(contient(noms(ns.Recherche.chercher("pehce")), "BetterFishing"), "zéro faute tolérée")
end)

T.test("chaque zone de recherche se coupe séparément", function(B)
	local ns = ouvrir({ B = B })
	-- le mot « pêche » n'est que dans la fiche
	T.vrai(contient(noms(ns.Recherche.chercher("pêche")), "FishyWashy"))
	ns.Reglages.ecrire("liste.recherche.fiche", false)
	T.faux(contient(noms(ns.Recherche.chercher("pêche")), "FishyWashy"), "plus dans la fiche")
	ns.Reglages.ecrire("liste.recherche.fiche", true)
	-- nom
	T.vrai(contient(noms(ns.Recherche.chercher("tomtom")), "TomTom"))
	ns.Reglages.ecrire("liste.recherche.nom", false)
	T.faux(contient(noms(ns.Recherche.chercher("tomtom")), "TomTom"), "plus dans le nom")
	ns.Reglages.ecrire("liste.recherche.nom", true)
	-- commandes
	ns.Reglages.ecrire("liste.recherche.commandes", false)
	T.faux(contient(noms(ns.Recherche.chercher("/way")), "TomTom"), "plus dans les commandes")
	ns.Reglages.ecrire("liste.recherche.commandes", true)
	-- ma note perso
	ns.FicheModele.definirNote("TomTom", "pense au grimoire violet")
	T.vrai(contient(noms(ns.Recherche.chercher("violet")), "TomTom"), "dans ma note")
	ns.Reglages.ecrire("liste.recherche.note", false)
	T.faux(contient(noms(ns.Recherche.chercher("violet")), "TomTom"), "note coupée")
	-- étiquettes
	ns.Recherche.definirEtiquettes("TomTom", ns.Recherche.analyserEtiquettes("#pvp, à tester"))
	T.vrai(contient(noms(ns.Recherche.chercher("#pvp")), "TomTom"), "étiquette #pvp")
	T.vrai(contient(noms(ns.Recherche.chercher("tester")), "TomTom"), "mot d'une étiquette")
	T.faux(contient(noms(ns.Recherche.chercher("#absent")), "TomTom"))
	ns.Reglages.ecrire("liste.recherche.etiquettes", false)
	T.faux(contient(noms(ns.Recherche.chercher("#pvp")), "TomTom"), "étiquettes coupées")
end)

T.test("plusieurs mots : tous doivent correspondre ; la recherche reste dans la catégorie si on le demande", function(B)
	local ns = ouvrir({ B = B })
	local deux = noms(ns.Recherche.chercher("pêche statistiques"))
	T.vrai(contient(deux, "FishyWashy"), "les deux mots dans la même fiche")
	T.faux(contient(deux, "BetterFishing"), "un mot manque : écarté")
	ns.Reglages.ecrire("liste.recherche.toutes_categories", false)
	ns.Fenetre.memoire().categorie = "bags-inventory"
	taper(ns, "pêche")
	T.eq(#rangs(ns), 0, "pas de pêche dans les sacs")
	T.vrai(ns.Vue.vide:GetText():find("Aucun add-on ne correspond", 1, true), "message « aucun résultat »")
end)

T.test("tri : nom, catégorie, état, mémoire, utilité, et ordre inversé", function(B)
	local ns = ouvrir({ B = B })
	ns.Reglages.ecrire("liste.grouper_tous", false) -- ordre à plat (le regroupement a son propre test)
	ns.Fenetre.rafraichir()
	local avant = rangs(ns)
	T.eq(ns.Reglages.lire("liste.tri"), "nom")
	ns.Reglages.ecrire("liste.tri_inverse", true)
	ns.Fenetre.rafraichir()
	local apres = rangs(ns)
	T.eq(apres[1], avant[#avant], "inversé : le dernier devient premier")
	ns.Reglages.ecrire("liste.tri_inverse", false)
	-- état : les chargés d'abord
	B.charge.Questie = true
	B.charge.TomTom = true
	ns.Reglages.ecrire("liste.tri", "etat")
	ns.Fenetre.memoire().categorie = "tous"
	ns.Fenetre.rafraichir()
	local r = rangs(ns)
	T.vrai(r[1] == "MesAddons" or r[1] == "Questie" or r[1] == "TomTom", "un add-on chargé en tête : " .. tostring(r[1]))
	-- mémoire : le plus gros d'abord
	B.memoire.TomTom = 5000
	B.memoire.Questie = 12000
	ns.Reglages.ecrire("liste.tri", "memoire")
	ns.Fenetre.rafraichir()
	r = rangs(ns)
	T.eq(r[1], "Questie", "le plus gros en premier")
	T.eq(r[2], "TomTom")
	T.vrai((B.memoire_mesures or 0) >= 1, "mémoire mesurée")
	-- utilité : indispensable avant confort avant gadget
	ns.Reglages.ecrire("liste.tri", "utilite")
	ns.Fenetre.rafraichir()
	r = rangs(ns)
	local function rang(nom) return ns.Recherche.utilite(ns.Liste.parNom(nom)) end
	T.vrai(rang(r[1]) == "indispensable" or rang(r[1]) == "confort", "utilité : " .. tostring(rang(r[1])))
	-- catégorie : regroupés par catégorie
	ns.Reglages.ecrire("liste.tri", "categorie")
	ns.Fenetre.rafraichir()
	r = rangs(ns)
	local prec
	for _, n in ipairs(r) do
		local c = ns.Liste.cleTri(ns.Liste.nomCategorie(ns.Liste.parNom(n).categorie))
		T.vrai(not prec or prec <= c, "catégories dans l'ordre")
		prec = c
	end
	T.sans_erreur()
end)

T.test("la liste déroulante de tri choisit le tri et l'ordre inversé", function(B)
	local ns = ouvrir({ B = B })
	T.eq(ns.Barre.tri.etiquette:GetText(), "Tri : Nom")
	ns.Barre.tri:Click()
	T.vrai(ns.Deroulant.ouvert(), "la liste s'ouvre")
	ns.Barre.tri:Click()
	T.faux(ns.Deroulant.ouvert(), "un second clic la referme")
	choisir(ns, ns.Barre.tri, "categorie")
	T.faux(ns.Deroulant.ouvert(), "fermée après le choix")
	T.eq(ns.Reglages.lire("liste.tri"), "categorie")
	T.eq(ns.Barre.tri.etiquette:GetText(), "Tri : Catégorie")
	choisir(ns, ns.Barre.tri, "inverse")
	T.vrai(ns.Reglages.lire("liste.tri_inverse"))
	T.eq(ns.Barre.tri.etiquette:GetText(), "Tri : Catégorie (inversé)")
end)

T.test("favoris : étoile, en haut de la liste, gardés au /reload", function(B)
	local ns = ouvrir({ B = B })
	ns.Reglages.ecrire("liste.grouper_tous", false)
	ns.Fenetre.rafraichir()
	local l = ligne(ns, "Questie")
	T.vrai(l and l.etoile:IsShown(), "étoile affichée")
	T.eq(l.etoile.image:GetAlpha(), ns.donnees.reglages.interface.liste.etoile.alpha_vide, "étoile éteinte")
	l.etoile:Click()
	T.sans_erreur()
	T.vrai(ns.Recherche.favori("Questie"))
	T.eq(rangs(ns)[1], "Questie", "le favori passe en haut")
	T.eq(ligne(ns, "Questie").etoile.image:GetAlpha(), 1, "étoile allumée")
	ns.Reglages.ecrire("liste.favoris_en_haut", false)
	ns.Fenetre.rafraichir()
	T.vrai(rangs(ns)[1] ~= "Questie", "réglage : favoris plus en haut")
	ns.Reglages.ecrire("liste.favoris_en_haut", true)
	ns = B.recharger()
	ns.Fenetre.ouvrir()
	T.vrai(ns.Recherche.favori("Questie"), "favori gardé")
	T.eq(rangs(ns)[1], "Questie")
	-- étoile coupée dans les options
	ns.Reglages.ecrire("liste.colonnes.etoile", false)
	ns.Fenetre.rafraichir()
	T.faux(ligne(ns, "Questie").etoile:IsShown(), "étoile cachée")
end)

T.test("filtres rapides : puces, comptes, un seul à la fois", function(B)
	local ns = ouvrir({ B = B })
	local tous = #ns.Liste.entrees()
	local function puce(id)
		for _, e in ipairs(ns.Barre.entreesFiltre()) do
			if e.id == id then return { Click = function() choisir(ns, ns.Barre.filtreBouton, id) end } end
		end
	end
	T.vrai(puce("tous") and puce("actives") and puce("desactivees") and puce("perimes") and puce("doublons")
		and puce("sans_fiche") and puce("favoris") and puce("nouveaux"), "puces par défaut")
	T.faux(puce("erreurs"), "puce « erreurs » cachée par défaut")
	T.eq(ns.Recherche.compter("actives") + ns.Recherche.compter("desactivees"), tous)
	puce("desactivees"):Click()
	T.eq(ns.Reglages.lire("liste.filtre"), "desactivees")
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l:IsShown() then T.faux(ns.Liste.actif(l.entree.nom), "seulement des désactivés") end
	end
	T.vrai(ns.Barre.filtreBouton.etiquette:GetText():find("Désactivés", 1, true), "le bouton montre le filtre choisi")
	puce("tous"):Click()
	T.eq(ns.Reglages.lire("liste.filtre"), "tous", "retour à tous")
	puce("perimes"):Click()
	local parents = {}
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l:IsShown() and l.niveau == 1 then
			T.vrai(l.entree.inutile, "module périmé")
			parents[l.entree.parent.nom] = true
		end
	end
	local n = 0
	for _, l in ipairs(ns.Vue.lignes) do
		if l.entree and l:IsShown() then
			n = n + 1
			T.vrai(l.entree.inutile or parents[l.entree.nom], "seulement des périmés (ou le parent d'un module périmé)")
		end
	end
	T.vrai(n > 0, "il y a des périmés")
end)


T.test("« Tous les add-ons » rangé par catégories : en-têtes repliables, case, compteur, pas pendant une recherche", function(B)
	local ns = ouvrir({ B = B })
	local V, M = ns.Vue, ns.Liste
	T.vrai(ns.Reglages.lire("liste.grouper_tous"), "regroupé par défaut")
	local function entetes()
		local t = {}
		for _, h in ipairs(V.entetes) do if h.id and h:IsShown() then t[#t + 1] = h end end
		return t
	end
	local hs = entetes()
	T.vrai(#hs >= 2, "plusieurs en-têtes")
	-- chaque add-on affiché est sous l'en-tête de sa catégorie, dans l'ordre de la colonne
	local ordre = {}
	for i, c in ipairs(M.categories()) do ordre[c.id] = i end
	for i = 2, #hs do T.vrai(ordre[hs[i - 1].id] < ordre[hs[i].id], "ordre des catégories") end
	local n_avant = #rangs(ns)
	local h = hs[1]
	local _, total = M.etatCategorie(h.id)
	T.vrai(h.compteur:GetText():find(tostring(total), 1, true), "compteur de la catégorie")
	-- replier la première : ses add-ons disparaissent, l'en-tête reste
	h:Click()
	T.sans_erreur()
	T.vrai(V.estReplie(h.id))
	T.vrai(#rangs(ns) < n_avant, "catégorie repliée")
	T.eq(entetes()[1].id, h.id, "l'en-tête reste")
	h:Click()
	T.eq(#rangs(ns), n_avant, "dépliée à nouveau")
	-- case de l'en-tête : bascule toute la catégorie
	local avant = M.categorieToutActive(h.id)
	h.case:Click()
	T.vrai(M.categorieToutActive(h.id) ~= avant, "la case bascule la catégorie")
	-- recherche : liste à plat
	taper(ns, "questie")
	T.eq(#entetes(), 0, "pas d'en-tête pendant une recherche")
	taper(ns, "")
	-- dans une catégorie : pas d'en-tête
	V.choisirCategorie(h.id)
	T.eq(#entetes(), 0, "pas d'en-tête dans une catégorie")
	V.choisirCategorie(ns.donnees.reglages.interface.categorie_tous)
	-- réglages : coupé, et replié au départ
	ns.Reglages.ecrire("liste.grouper_tous", false)
	ns.Fenetre.rafraichir()
	T.eq(#entetes(), 0, "réglage coupé : à plat")
	ns.Reglages.ecrire("liste.grouper_tous", true)
	ns.Reglages.ecrire("liste.groupes_replies", true)
	V.replie = {}
	ns.Fenetre.rafraichir()
	T.eq(#rangs(ns), 0, "tout replié au départ")
	T.vrai(#entetes() >= 2)
end)

T.fin()
