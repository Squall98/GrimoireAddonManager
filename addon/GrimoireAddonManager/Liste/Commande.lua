-- Sous-commandes de la liste : chercher, tri, etiquette, favori, desinstaller, sansfiche, vus.
local _, ns = ...
local R, M = ns.Recherche, ns.Liste
local sous = ns.Commandes.sous

local function cfg() return ns.donnees.reglages.interface.liste end

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

-- Retrouve un add-on par son dossier (sans tenir compte des majuscules), sinon par le début de son nom.
local function trouver(mot)
	if mot == "" then return nil end
	local bas = string.lower(mot)
	local candidat
	for _, e in ipairs(M.entrees()) do
		if string.lower(e.nom) == bas or e.cle == R.normaliser(mot) then return e end
		if not candidat and string.sub(string.lower(e.nom), 1, #bas) == bas then candidat = e end
	end
	return candidat
end

local function titres(entrees)
	local noms = {}
	local max = cfg().noms_max_chat
	for i, e in ipairs(entrees) do
		if i > max then
			noms[#noms + 1] = "…"
			break
		end
		noms[#noms + 1] = e.titre
	end
	return table.concat(noms, cfg().separateur_liste)
end

function sous.chercher(reste)
	if reste == "" then return ns.dire(ns.T("cherche.usage")) end
	local res = R.chercher(reste)
	if #res == 0 then return ns.dire(ns.T("cherche.aucun", reste)) end
	local entrees = {}
	for _, r in ipairs(res) do entrees[#entrees + 1] = r.e end
	ns.dire(ns.T("cherche.resultat", #res, reste, titres(entrees)))
end

function sous.tri(reste)
	local ids = cfg().tris_ordre
	local noms = {}
	for _, id in ipairs(ids) do noms[#noms + 1] = ns.T("tri." .. id) end
	local liste = table.concat(noms, cfg().separateur_liste)
	local actuel = ns.Reglages.lire("liste.tri")
	if reste == "" then
		local note = ns.Reglages.lire("liste.tri_inverse") and ns.T("tri.inverse_note") or ""
		return ns.dire(ns.T("tri.actuel", ns.T("tri." .. actuel), note, liste))
	end
	if mot_est(reste, "arg.inverser") then
		ns.Reglages.ecrire("liste.tri_inverse", not ns.Reglages.lire("liste.tri_inverse"))
		ns.dire(ns.T("tri.inverse_change", ns.T("tri." .. actuel)))
	else
		local choisi
		for _, id in ipairs(ids) do
			if string.lower(reste) == id or mot_est(reste, "tri." .. id) then choisi = id end
		end
		if not choisi then return ns.dire(ns.T("tri.invalide", reste, liste)) end
		ns.Reglages.ecrire("liste.tri", choisi)
		ns.dire(ns.T("tri.change", ns.T("tri." .. choisi)))
	end
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end

function sous.etiquette(reste)
	local mot, tags = decouper(reste)
	if mot == "" then return ns.dire(ns.T("etiquette.usage")) end
	local e = trouver(mot)
	if not e then return ns.dire(ns.T("addon.inconnu", mot)) end
	R.definirEtiquettes(e.nom, R.analyserEtiquettes(tags))
	local txt = R.texteEtiquettes(e.nom)
	ns.dire(ns.T("etiquette.fait", e.titre, txt ~= "" and txt or ns.T("etiquette.aucune")))
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end

-- favori et desinstaller marchent pareil : sans nom, la liste ; avec un nom, on ajoute ou on retire.
local function bascule(reste, id, est, basculer)
	if reste == "" then
		local liste = {}
		for _, e in ipairs(M.entrees()) do if est(e.nom) then liste[#liste + 1] = e end end
		if #liste == 0 then return ns.dire(ns.T(id .. ".vide")) end
		return ns.dire(ns.T(id .. ".liste", titres(liste)))
	end
	local e = trouver(reste)
	if not e then return ns.dire(ns.T("addon.inconnu", reste)) end
	local v = basculer(e.nom)
	ns.dire(ns.T(id .. (v and ".ajoute" or ".retire"), e.titre))
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end

function sous.favori(reste) bascule(reste, "favori", R.favori, R.basculerFavori) end
function sous.desinstaller(reste) bascule(reste, "desinstaller", R.aDesinstaller, R.basculerDesinstaller) end

function sous.sansfiche()
	local liste = {}
	for _, e in ipairs(M.entrees()) do if not e.fiche then liste[#liste + 1] = e end end
	if #liste == 0 then return ns.dire(ns.T("sansfiche.vide")) end
	ns.dire(ns.T("sansfiche.liste", #liste, titres(liste)))
end

function sous.vus()
	ns.Journal.ecrire("info", "journal.vus", R.toutVu())
	ns.dire(ns.T("vus.fait"))
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end
