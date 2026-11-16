-- Sous-commandes : erreurs (fenêtre, effacer, un add-on), memoire, cpu (activer, couper, zero) ; boutons d'options.
local _, ns = ...
local E, H, W = ns.Erreurs, ns.Sante, ns.ErreursFenetre
local sous = ns.Commandes.sous

local function lire(chemin) return ns.Reglages.lire("erreurs." .. chemin) end

local function mot_est(mot, cle)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

-- Retrouve la clé d'un add-on qui a des erreurs, sans tenir compte des majuscules, ou par le début de son nom.
local function trouverAddon(mot)
	local bas, candidat = string.lower(mot), nil
	for _, a in ipairs(E.addons()) do
		local nom = string.lower(a.addon)
		if nom == bas then return a.addon end
		if not candidat and string.sub(nom, 1, #bas) == bas then candidat = a.addon end
	end
	return candidat
end

function sous.erreurs(reste)
	if not lire("actif") then ns.dire(ns.T("erreurs.desactive")) end
	if reste ~= "" and mot_est(reste, "arg.effacer") then
		local n = E.effacer()
		ns.Journal.ecrire("info", "journal.erreurs_effacees", n)
		return ns.dire(ns.T("erreurs.efface", n))
	end
	if reste ~= "" then
		local addon = trouverAddon(reste)
		if not addon then return ns.dire(ns.T("erreurs.inconnue_cible", reste)) end
		W.filtre = addon
	else
		W.filtre = nil
	end
	W.page, W.selection = 1, nil
	W.ouvrir()
	W.rafraichir()
end

function sous.memoire()
	local liste, total = H.memoire()
	if #liste == 0 then return ns.dire(ns.T("memoire.aucune")) end
	local n = math.min(#liste, lire("memoire_lignes"))
	ns.dire(ns.T("memoire.titre", H.formaterKo(total), #liste, n))
	for i = 1, n do ns.dire(ns.T("memoire.ligne", i, liste[i].nom, H.formaterKo(liste[i].ko))) end
end

function sous.cpu(reste)
	local principale = ns.Commandes.principale() or ns.Reglages.technique().cle_commande
	if reste ~= "" and mot_est(reste, "arg.activer") then
		return ns.dire(ns.T("cpu." .. H.cpuDefinir(true)) )
	elseif reste ~= "" and mot_est(reste, "arg.couper") then
		return ns.dire(ns.T("cpu." .. H.cpuDefinir(false)))
	elseif reste ~= "" and mot_est(reste, "arg.zero") then
		H.cpuZero()
		return ns.dire(ns.T("cpu.remis"))
	end
	if not H.cpuAllume() then return ns.dire(ns.T("cpu.eteint", principale)) end
	local liste, total = H.cpuMesures()
	if #liste == 0 then return ns.dire(ns.T("cpu.aucune")) end
	local n = math.min(#liste, lire("cpu_lignes"))
	local duree = math.max(H.cpuDuree(), 1)
	ns.dire(ns.T("cpu.titre", ns.T("cpu.duree", duree), total, n))
	for i = 1, n do ns.dire(ns.T("cpu.ligne", i, liste[i].nom, liste[i].ms, liste[i].ms / duree)) end
end

-- Boutons du panneau d'options (schéma : actions ouvrir_erreurs et effacer_erreurs).
if ns.Options and ns.Options.actions then
	ns.Options.actions.ouvrir_erreurs = function() W.ouvrir() end
	ns.Options.actions.effacer_erreurs = function()
		ns.Journal.ecrire("info", "journal.erreurs_effacees", E.effacer())
	end
end
