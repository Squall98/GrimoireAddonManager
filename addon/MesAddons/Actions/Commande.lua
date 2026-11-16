-- Sous-commandes des actions rapides : activer, desactiver, seul, essai, depannage, retour, recharger, perimes, annuler, resume.
local _, ns = ...
local A = ns.Actions
local M = ns.Liste
local sous = ns.Commandes.sous

local function cfg() return ns.donnees.reglages.actions end

local function mot_est(mot, cle)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

local function rafraichir()
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
	if ns.ProfilsUI then ns.ProfilsUI.surChangement() end
end

-- Un add-on cité par la commande ; dit pourquoi si on ne le trouve pas.
local function addon(reste, usage)
	if reste == "" then ns.dire(ns.T(usage)) return nil end
	local e = A.trouver(reste)
	if not e then ns.dire(ns.T("addon.inconnu", reste)) end
	return e
end

function sous.activer(reste)
	local e = addon(reste, "actions.usage_activer")
	if not e then return end
	local n = A.activerComplet(e.nom)
	ns.dire(ns.T("actions.active", e.titre, n))
	rafraichir()
end

function sous.desactiver(reste)
	local e = addon(reste, "actions.usage_desactiver")
	if not e then return end
	local n = A.desactiver(e.nom)
	ns.dire(ns.T("actions.desactive", e.titre, n))
	rafraichir()
end

function sous.seul(reste)
	local e = addon(reste, "actions.usage_seul")
	if not e then return end
	local plus, moins = A.seul(e.nom)
	ns.dire(ns.T("actions.seul", e.titre, plus, moins))
	rafraichir()
end

function sous.essai(reste)
	if reste == "" then
		local noms = {}
		for _, e in ipairs(M.entrees()) do if ns.Recherche.essai(e.nom) then noms[#noms + 1] = e.titre end end
		if #noms == 0 then return ns.dire(ns.T("actions.essai_vide")) end
		return ns.dire(ns.T("actions.essai_liste", #noms, table.concat(noms, cfg().separateur_liste)))
	end
	local e = addon(reste, "actions.essai_vide")
	if not e then return end
	local debut = A.basculerEssai(e.nom)
	ns.dire(ns.T(debut and "actions.essai_debut" or "actions.essai_arret", e.titre))
	rafraichir()
end

-- Mots séparés par des espaces ou des virgules.
local function mots(texte)
	local res = {}
	for mot in string.gmatch(texte or "", cfg().motif_mots) do res[#res + 1] = mot end
	return res
end

function sous.depannage(reste)
	if A.depannageActif() then return ns.dire(ns.T("actions.depannage_deja")) end
	local noms = {}
	for _, mot in ipairs(mots(reste)) do
		local e = A.trouver(mot)
		if not e then return ns.dire(ns.T("addon.inconnu", mot)) end
		noms[#noms + 1] = e.nom
	end
	local plus, moins = A.depannage(noms)
	ns.dire(ns.T("actions.depannage", #noms, plus, moins))
	rafraichir()
end

function sous.retour()
	local ok, plus, moins = A.retour()
	if not ok then return ns.dire(ns.T("actions.retour_rien")) end
	ns.dire(ns.T("actions.retour", plus, moins))
	rafraichir()
end

function sous.recharger()
	ns.dire(ns.T("actions.recharge", (M.enAttente())))
	M.recharger()
end

function sous.annuler()
	if not M.annuler() then return ns.dire(ns.T("actions.annuler_rien")) end
	ns.dire(ns.T("actions.annule"))
	rafraichir()
end

function sous.perimes(reste)
	local oui
	if reste == "" then
		oui = not A.perimesActif()
	elseif mot_est(reste, "arg.on") then
		oui = true
	elseif mot_est(reste, "arg.off") then
		oui = false
	else
		return ns.dire(ns.T("actions.usage_perimes"))
	end
	A.definirPerimes(oui)
	ns.dire(ns.T(A.perimesActif() and "actions.perimes_oui" or "actions.perimes_non"))
end

function sous.resume()
	ns.dire(A.resume())
end
