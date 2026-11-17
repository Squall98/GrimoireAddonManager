-- Recherche (tolérante aux fautes), tris, filtres rapides, favoris, étiquettes, niveau d'utilité, badges et raison en clair.
-- Modèle de la liste : rien n'est dessiné ici (la barre est dans Barre.lua, les lignes dans Vue.lua).
local _, ns = ...
local R = {}
ns.Recherche = R

local M = ns.Liste
local function cfg() return ns.donnees.reglages.interface.liste end
local function lire(chemin) return ns.Reglages.lire(chemin) end

R.texte = ""      -- recherche en cours (non gardée au rechargement, sauf si le réglage le demande)
R.erreurs = {}    -- add-on -> nombre d'erreurs Lua vues depuis la connexion

------------------------------------------------------------------ sauvegardes du compte
-- compte.liste = { favoris, etiquettes, desinstaller, essais, utilite, connus, versions } : tout par nom d'add-on.
local function stock()
	local c = ns.Reglages.compte
	c.liste = c.liste or {}
	local s = c.liste
	s.favoris = s.favoris or {}
	s.etiquettes = s.etiquettes or {}
	s.desinstaller = s.desinstaller or {}
	s.essais = s.essais or {}
	s.utilite = s.utilite or {}
	return s
end

local function versionDe(nom)
	return C_AddOns.GetAddOnMetadata(nom, "Version") or ""
end

-- Première utilisation : tout ce qui est installé est « connu » (rien n'est nouveau le premier jour).
local function amorcer()
	local s = stock()
	if s.connus then return s end
	s.connus, s.versions = {}, {}
	for _, e in ipairs(M.entrees()) do
		s.connus[e.nom] = true
		s.versions[e.nom] = versionDe(e.nom)
	end
	return s
end
R.amorcer = amorcer

local function bascule(table_, nom, valeur)
	if valeur == nil then valeur = not table_[nom] end
	if valeur then table_[nom] = true else table_[nom] = nil end
	return valeur
end

function R.favori(nom) return stock().favoris[nom] == true end
function R.basculerFavori(nom, v) return bascule(stock().favoris, nom, v) end
function R.aDesinstaller(nom) return stock().desinstaller[nom] == true end
function R.basculerDesinstaller(nom, v) return bascule(stock().desinstaller, nom, v) end
function R.essai(nom) return stock().essais[nom] == true end
function R.basculerEssai(nom, v) return bascule(stock().essais, nom, v) end

------------------------------------------------------------------ nouveau, mis à jour, vu
function R.nouveau(e)
	local s = amorcer()
	if s.connus[e.nom] then return false end
	if lire("liste.nouveau_sans_fiche") and e.fiche then return false end
	return true
end

function R.misAJour(e)
	local s = amorcer()
	local v = s.versions[e.nom]
	return v ~= nil and v ~= versionDe(e.nom)
end

function R.reconnaitre(nom)
	local s = amorcer()
	s.connus[nom] = true
	s.versions[nom] = versionDe(nom)
end

-- Marque comme vus tous les nouveaux et mis à jour ; renvoie combien.
function R.toutVu()
	local n = 0
	for _, e in ipairs(M.entrees()) do
		if R.nouveau(e) or R.misAJour(e) or not amorcer().connus[e.nom] then
			R.reconnaitre(e.nom)
			n = n + 1
		end
	end
	return n
end

------------------------------------------------------------------ étiquettes et utilité
-- « #pvp, à tester » -> { "pvp", "à tester" } (minuscules, sans doublon, au plus `liste.etiquettes_max`).
function R.analyserEtiquettes(texte)
	local res, vus = {}, {}
	local max = lire("liste.etiquettes_max")
	local longueur = ns.donnees.reglages.interface.liste.menu.longueur_etiquette
	for morceau in string.gmatch(texte or "", cfg().motif_etiquettes) do
		local mot = string.gsub(string.gsub(morceau, "^%s+", ""), "%s+$", "")
		mot = string.lower(string.sub(mot, 1, longueur))
		if mot ~= "" and not vus[mot] and #res < max then
			vus[mot] = true
			res[#res + 1] = mot
		end
	end
	return res
end

function R.etiquettes(nom) return stock().etiquettes[nom] or {} end

function R.definirEtiquettes(nom, liste)
	if #liste == 0 then stock().etiquettes[nom] = nil else stock().etiquettes[nom] = liste end
	ns.Journal.ecrire("info", "journal.etiquettes", nom, table.concat(liste, cfg().separateur_liste))
end

function R.texteEtiquettes(nom) return table.concat(R.etiquettes(nom), cfg().separateur_liste) end

-- Utilité d'un add-on : le choix du joueur, sinon celle de la fiche, sinon nil.
function R.utilite(e)
	local u = stock().utilite[e.nom]
	if u then return u end
	return e.fiche and e.fiche.utilite ~= "" and e.fiche.utilite or nil
end

-- Passe à l'utilité suivante : indispensable, confort, gadget, puis retour à celle de la fiche.
function R.utiliteSuivante(nom)
	local liste = cfg().utilites
	local s = stock()
	local actuelle = s.utilite[nom]
	if not actuelle then
		s.utilite[nom] = liste[1]
	else
		local suivante
		for i, u in ipairs(liste) do if u == actuelle then suivante = liste[i + 1] end end
		s.utilite[nom] = suivante
	end
	return s.utilite[nom]
end

------------------------------------------------------------------ erreurs Lua des autres add-ons
function R.noterErreur(message)
	local nom = string.match(tostring(message), cfg().motif_erreur)
	if nom and nom ~= ns.nom then
		R.erreurs[nom] = (R.erreurs[nom] or 0) + 1
		ns.Journal.ecrire("avertissement", "journal.erreur_addon", nom)
	end
end

function R.surveillerErreurs()
	if R.surveille then return end
	R.surveille = true
	local ancien = geterrorhandler()
	seterrorhandler(function(message, ...)
		pcall(R.noterErreur, message)
		if ancien then return ancien(message, ...) end
	end)
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function()
	R.surveillerErreurs()
	ns.Journal.proteger(amorcer)
	if lire("liste.recherche.garder") then R.texte = stock().texte or "" end
end)

function R.definirTexte(texte)
	R.texte = texte or ""
	if lire("liste.recherche.garder") then stock().texte = R.texte end
end

------------------------------------------------------------------ raison en clair
-- Pourquoi un add-on est (ou n'est pas) chargé : { id, texte }.
function R.raison(e)
	local function r(id, ...) return { id = id, texte = ns.T("raison." .. id, ...) } end
	if e.inutile then return r("inutile") end
	local actif = M.actif(e.nom)
	local charge = C_AddOns.IsAddOnLoaded(e.nom)
	local _, _, _, _, raison = C_AddOns.GetAddOnInfo(e.nom)
	if raison == "INTERFACE_VERSION" or raison == "INCOMPATIBLE" then return r("perime") end
	if actif then
		local manque, coupe = {}, {}
		for _, d in ipairs(ns.FicheModele.dependances(e)) do
			if d.etat == "absent" then manque[#manque + 1] = d.titre end
			if d.etat == "inactif" then coupe[#coupe + 1] = d.titre end
		end
		if #manque > 0 then return r("dep_absente", table.concat(manque, cfg().separateur_liste)) end
		if #coupe > 0 then return r("dep_desactivee", table.concat(coupe, cfg().separateur_liste)) end
		if charge then return r("charge") end
		if C_AddOns.IsAddOnLoadOnDemand(e.nom) then return r("a_la_demande") end
		if M.modifie(e.nom) then return r("coche") end
		return r("non_charge")
	end
	if charge then return r("decoche") end
	return r("desactive")
end

-- Raisons « ordinaires » : montrées dans la liste seulement si `liste.colonnes.etat_charge` est actif.
function R.ordinaire(id)
	for _, x in ipairs(cfg().raisons_ordinaires) do if x == id then return true end end
	return false
end

------------------------------------------------------------------ badges
-- Identifiants des badges d'un add-on, du plus important au moins important (réglages `liste.badges.*`).
function R.badges(e)
	local res = {}
	local function si(id, condition)
		if condition and lire("liste.badges." .. id) then res[#res + 1] = id end
	end
	si("erreur", (R.erreurs[e.nom] or 0) > 0)
	si("nouveau", R.nouveau(e))
	si("mis_a_jour", R.misAJour(e))
	si("doublon", M.actif(e.nom) and #ns.FicheModele.doublonsActifs(e) > 0)
	si("essai", R.essai(e.nom))
	si("verrou", ns.Profils and ns.Profils.verrou(e.nom))
	si("desinstaller", R.aDesinstaller(e.nom))
	si("inutile", e.inutile)
	return res
end

------------------------------------------------------------------ filtres rapides
local filtres = {
	tous = function() return true end,
	actives = function(e) return M.actif(e.nom) end,
	desactivees = function(e) return not M.actif(e.nom) end,
	perimes = function(e) return e.inutile end,
	doublons = function(e) return #ns.FicheModele.doublonsActifs(e) > 0 end,
	sans_fiche = function(e) return not e.fiche end,
	favoris = function(e) return R.favori(e.nom) end,
	a_desinstaller = function(e) return R.aDesinstaller(e.nom) end,
	nouveaux = function(e) return R.nouveau(e) end,
	mis_a_jour = function(e) return R.misAJour(e) end,
	erreurs = function(e) return (R.erreurs[e.nom] or 0) > 0 end,
	essais = function(e) return R.essai(e.nom) end,
	en_attente = function(e) return M.modifie(e.nom) end,
}

function R.filtre()
	local id = lire("liste.filtre")
	return filtres[id] and id or "tous"
end

function R.definirFiltre(id)
	if not filtres[id] then return false end
	ns.Reglages.ecrire("liste.filtre", id)
	return true
end

function R.filtresVisibles()
	local res = {}
	for _, id in ipairs(cfg().filtres_ordre) do
		if lire("liste.filtres_visibles." .. id) or id == R.filtre() then res[#res + 1] = id end
	end
	return res
end

function R.compter(id)
	local n = 0
	for _, e in ipairs(M.entrees()) do
		if filtres[id](e) then n = n + 1 end
	end
	return n
end

------------------------------------------------------------------ recherche
local function normaliser(texte) return M.cleTri(texte) end
R.normaliser = normaliser

-- Distance entre deux mots (insertion, retrait, remplacement, échange de deux lettres), coupée à `max`+1.
local function distance(a, b, max)
	local la, lb = #a, #b
	if math.abs(la - lb) > max then return max + 1 end
	local avant2, avant, courant = {}, {}, {}
	for j = 0, lb do avant[j] = j end
	for i = 1, la do
		courant = { [0] = i }
		local mini = i
		for j = 1, lb do
			local cout = (string.byte(a, i) == string.byte(b, j)) and 0 or 1
			local v = math.min(avant[j] + 1, courant[j - 1] + 1, avant[j - 1] + cout)
			if i > 1 and j > 1 and string.byte(a, i) == string.byte(b, j - 1) and string.byte(a, i - 1) == string.byte(b, j) then
				v = math.min(v, avant2[j - 2] + 1)
			end
			courant[j] = v
			if v < mini then mini = v end
		end
		if mini > max then return max + 1 end
		avant2, avant = avant, courant
	end
	return avant[lb]
end
R.distance = distance

-- Le mot cherché est-il dans le texte (déjà normalisé) ? 0 = non, 1 = tolérance, 2 = contenu, 3 = mot entier.
local function trouve(texte, mot, tolerance)
	if texte == "" then return 0 end
	local debut, fin = string.find(texte, mot, 1, true)
	if debut then
		local avant = debut == 1 or string.find(string.sub(texte, debut - 1, debut - 1), "[^%w_]") ~= nil
		local apres = fin == #texte or string.find(string.sub(texte, fin + 1, fin + 1), "[^%w_]") ~= nil
		return (avant and apres) and 3 or 2
	end
	if tolerance and #mot >= lire("liste.recherche.longueur_min") then
		local d = lire("liste.recherche.distance")
		if d > 0 and #mot >= cfg().longueur_longue then d = d + 1 end
		for w in string.gmatch(texte, cfg().motif_mot) do
			if distance(mot, w, d) <= d then return 1 end
		end
	end
	return 0
end

-- Textes d'un add-on où chercher, déjà normalisés : { nom, commandes, etiquettes, fiche, note, categorie, notes_toc }.
local function champs(e)
	local FM = ns.FicheModele
	local c = {}
	if lire("liste.recherche.nom") then c.nom = normaliser(e.titre .. " " .. e.nom) end
	if lire("liste.recherche.commandes") then c.commandes = normaliser(FM.champ(e.nom, "commandes")) end
	if lire("liste.recherche.etiquettes") then c.etiquettes = normaliser(table.concat(R.etiquettes(e.nom), " ")) end
	if lire("liste.recherche.fiche") then
		c.fiche = normaliser(FM.champ(e.nom, "resume") .. " " .. FM.champ(e.nom, "remarques"))
	end
	if lire("liste.recherche.note") then c.note = normaliser(FM.note(e.nom)) end
	if lire("liste.recherche.categorie") then c.categorie = normaliser(M.nomCategorie(e.categorie)) end
	if lire("liste.recherche.notes_toc") then c.notes_toc = normaliser(e.notes) end
	return c
end

-- Score d'un add-on pour la recherche : nil s'il ne correspond pas, sinon plus c'est grand mieux c'est.
function R.score(e, mots)
	if #mots == 0 then return 1 end
	local c = champs(e)
	local p = cfg().poids
	local tol = lire("liste.recherche.tolerance")
	local total = 0
	for _, mot in ipairs(mots) do
		local meilleur = 0
		local function essai(champ, poids, mot_)
			if c[champ] then
				local k = trouve(c[champ], mot_, tol)
				if k > 0 then
					local v = poids * (k == 1 and 0.5 or 1) + (k == 3 and p.mot_exact or 0)
					if v > meilleur then meilleur = v end
				end
			end
		end
		local premier = string.sub(mot, 1, 1)
		if premier == "/" then
			essai("commandes", p.commandes, mot)
		elseif premier == "#" then
			local seul = string.sub(mot, 2)
			if seul ~= "" then essai("etiquettes", p.etiquettes, seul) end
		else
			essai("nom", p.nom, mot)
			if c.nom and string.sub(c.nom, 1, #mot) == mot then meilleur = meilleur + p.debut_nom end
			essai("commandes", p.commandes, mot)
			essai("etiquettes", p.etiquettes, mot)
			essai("fiche", p.fiche, mot)
			essai("note", p.note, mot)
			essai("categorie", p.categorie, mot)
			essai("notes_toc", p.notes_toc, mot)
		end
		if meilleur == 0 then return nil end
		total = total + meilleur
	end
	return total
end

-- Mots de la recherche (normalisés).
function R.mots(texte)
	local res = {}
	for mot in string.gmatch(normaliser(texte or R.texte), "%S+") do res[#res + 1] = mot end
	return res
end

-- Recherche simple pour les commandes et les tests : entrées triées par score.
function R.chercher(texte)
	local mots = R.mots(texte)
	local res = {}
	for _, e in ipairs(M.entrees()) do
		local s = R.score(e, mots)
		if s then res[#res + 1] = { e = e, score = s } end
	end
	table.sort(res, function(a, b)
		if a.score ~= b.score then return a.score > b.score end
		return a.e.cle < b.e.cle
	end)
	return res
end

------------------------------------------------------------------ tris
local rang_etat = function(e)
	if C_AddOns.IsAddOnLoaded(e.nom) then return 0 end
	if M.actif(e.nom) then return 1 end
	return 2
end

-- Mémoire (Ko) des add-ons chargés ; mesurée une seule fois par appel de `contexte`.
local function mesurerMemoire()
	local m = {}
	if UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
	for _, e in ipairs(M.entrees()) do
		if C_AddOns.IsAddOnLoaded(e.nom) and GetAddOnMemoryUsage then m[e.nom] = GetAddOnMemoryUsage(e.nom) or 0 end
	end
	return m
end

-- Ce qui sert à toute la liste affichée : recherche, filtre, tri (calculé une fois par rafraichissement).
function R.contexte()
	local ctx = {
		mots = R.mots(), filtre = R.filtre(), tri = lire("liste.tri"), inverse = lire("liste.tri_inverse"),
	}
	ctx.cherche = #ctx.mots > 0
	ctx.actif = ctx.cherche or ctx.filtre ~= "tous"
	if ctx.tri == "memoire" or lire("liste.colonnes.memoire") then ctx.memoire = mesurerMemoire() end
	return ctx
end

-- Un add-on passe-t-il le filtre et la recherche ? Renvoie son score, ou nil.
function R.evaluer(ctx, e)
	if not filtres[ctx.filtre](e) then return nil end
	return R.score(e, ctx.mots)
end

local rang_utilite = function(e)
	local u = R.utilite(e)
	for i, id in ipairs(cfg().utilites) do if id == u then return i end end
	return #cfg().utilites + 1
end

-- Ordre d'une liste d'éléments { e, score } : favoris et nouveaux en haut, puis le tri choisi.
function R.ordonner(items, ctx)
	local function groupe(e)
		if lire("liste.favoris_en_haut") and R.favori(e.nom) then return 0 end
		if lire("liste.nouveaux_en_haut") and R.nouveau(e) then return 1 end
		return 2
	end
	local function valeur(e)
		if ctx.tri == "categorie" then return M.cleTri(M.nomCategorie(e.categorie)) end
		if ctx.tri == "etat" then return rang_etat(e) end
		if ctx.tri == "memoire" then return -((ctx.memoire and ctx.memoire[e.nom]) or -1) end
		if ctx.tri == "utilite" then return rang_utilite(e) end
		return e.cle
	end
	for _, it in ipairs(items) do
		it.groupe, it.valeur = groupe(it.e), valeur(it.e)
	end
	local pertinence = ctx.cherche and lire("liste.recherche.pertinence")
	table.sort(items, function(a, b)
		if pertinence and a.score ~= b.score then return a.score > b.score end
		if a.groupe ~= b.groupe then return a.groupe < b.groupe end
		if a.valeur ~= b.valeur then
			if ctx.inverse then return a.valeur > b.valeur end
			return a.valeur < b.valeur
		end
		if a.e.cle ~= b.e.cle then return a.e.cle < b.e.cle end
		return a.e.nom < b.e.nom
	end)
	return items
end
