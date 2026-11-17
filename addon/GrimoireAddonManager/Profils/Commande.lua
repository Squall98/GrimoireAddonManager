-- Sous-commandes des profils : profils, profil, verrou.
local _, ns = ...
local P = ns.Profils
local sous = ns.Commandes.sous

local function cfg() return ns.donnees.reglages.profils end

local function mot_est(mot, cle)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

local function decouper(texte)
	local mot, reste = string.match(texte or "", "^%s*(%S*)%s*(.-)%s*$")
	return mot or "", reste or ""
end

local function actionDe(mot)
	for _, id in ipairs(cfg().actions) do
		if mot_est(mot, "profil.act." .. id) then return id end
	end
end

-- « a / b » -> a, b
local function deux(reste)
	local a, b = string.match(reste, "^(.-)%s*" .. cfg().separateur_arguments .. "%s*(.-)$")
	if not a then return reste, "" end
	return a, b
end

local function rafraichir()
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
	if ns.ProfilsUI then ns.ProfilsUI.surChangement() end
end

local function trouverAddon(mot)
	if mot == "" then return nil end
	local e = ns.Liste.parNom(mot)
	if e then return e end
	local bas = ns.Liste.cleTri(mot)
	local candidat
	for _, x in ipairs(ns.Liste.entrees()) do
		if x.cle == bas or ns.Liste.cleTri(x.nom) == bas then return x end
		if not candidat and string.sub(ns.Liste.cleTri(x.nom), 1, #bas) == bas then candidat = x end
	end
	return candidat
end

local function lister()
	ns.dire(ns.T("profil.liste_titre", P.nombre()))
	local actuel = P.actuel()
	for _, p in ipairs(P.tous()) do
		local marque = (actuel and actuel.id == p.id) and ns.T("profil.marque_actuel") or ""
		if P.incomplet(p) then marque = marque .. ns.T("profil.marque_incomplet") end
		ns.dire(ns.T("profil.liste_ligne", marque, P.nom(p), P.taille(p)))
	end
end

local function trouverOuDire(texte)
	local p = P.trouver(texte)
	if not p then ns.dire(ns.T("profil.inconnu", texte)) end
	return p
end

local function appliquer(texte, portee, mode)
	local p = trouverOuDire(texte)
	if not p then return end
	local a, touches = P.appliquer(p, portee, mode)
	ns.dire(ns.T(mode and "profil.fusionne" or "profil.applique", P.nom(p), #a.plus, #a.moins, touches))
	for _, d in ipairs(a.deps_absentes) do ns.dire(ns.T("profil.alerte_dep", d.dep, d.addon)) end
	if #a.absents > 0 then ns.dire(ns.T("profil.alerte_absents", #a.absents, P.nom(p))) end
	rafraichir()
end

function sous.profils()
	if ns.ProfilsUI then ns.ProfilsUI.basculer() end
end

function sous.profil(reste)
	local mot, suite = decouper(reste)
	if mot == "" then return lister() end
	local act = actionDe(mot)
	if act == "tous" then return appliquer(suite, "tous") end
	if act == "fusionner" then return appliquer(suite, ns.Reglages.lire("profils.portee"), "fusion") end
	if act == "comparer" then
		local a, b = deux(suite)
		local pa, pb = P.trouver(a), P.trouver(b)
		if not pa or not pb then return ns.dire(ns.T("profil.comparer_usage")) end
		local d = P.comparer(pa, pb)
		ns.dire(ns.T("profil.compare_titre", P.nom(pa), P.nom(pb)))
		ns.dire(ns.T("profil.compare_a", #d.seulA, table.concat(d.seulA, cfg().separateur_liste)))
		ns.dire(ns.T("profil.compare_b", #d.seulB, table.concat(d.seulB, cfg().separateur_liste)))
		return ns.dire(ns.T("profil.compare_commun", #d.commun))
	elseif act == "nouveau" then
		local p, err = P.creer(suite)
		if not p then return ns.dire(ns.T(err)) end
		ns.dire(ns.T("profil.cree", P.nom(p)))
	elseif act == "enregistrer" then
		local p = trouverOuDire(suite)
		if p and P.enregistrerActuel(p) then ns.dire(ns.T("profil.enregistre", P.nom(p), #p.addons)) end
	elseif act == "renommer" then
		local a, b = deux(suite)
		local p = trouverOuDire(a)
		if not p then return end
		if p.virtuel or b == "" then return ns.dire(ns.T("profil.renommer_usage")) end
		P.renommer(p, b)
		ns.dire(ns.T("profil.renomme", P.nom(p)))
	elseif act == "supprimer" then
		local p = trouverOuDire(suite)
		if p and not p.virtuel and P.supprimer(p) then ns.dire(ns.T("profil.supprime", P.nom(p))) end
	elseif act == "nettoyer" then
		local p = trouverOuDire(suite)
		if p then ns.dire(ns.T("profil.retire_absents", P.retirerAbsents(p), P.nom(p))) end
	elseif act == "exporter" then
		local p = trouverOuDire(suite)
		if p and not p.virtuel then ns.dire(P.exporter(p)) end
	elseif act == "sauvegarde" then
		ns.dire(P.exporterTout())
	elseif act == "importer" then
		local res, err = P.importer(suite)
		if not res then return ns.dire(ns.T(err)) end
		ns.dire(ns.T("profil.importe", res.profils, res.notes, res.etiquettes + res.favoris + res.verrous))
	elseif act == "prets" then
		ns.dire(ns.T("profil.prets", P.completerPrets()))
	else
		return appliquer(reste, "perso")
	end
	rafraichir()
end

function sous.verrou(reste)
	if reste == "" then
		local v = P.verrous()
		if #v == 0 then return ns.dire(ns.T("verrou.vide")) end
		return ns.dire(ns.T("verrou.liste", #v, table.concat(v, cfg().separateur_liste)))
	end
	local e = trouverAddon(reste)
	if not e then return ns.dire(ns.T("addon.inconnu", reste)) end
	local v = P.basculerVerrou(e.nom)
	ns.dire(ns.T(v and "verrou.pose" or "verrou.retire", e.titre))
	rafraichir()
end
