-- À la connexion : fin des essais, résumé d'une ligne dans le chat, textes des raccourcis clavier.
-- Raccourcis : Bindings.xml appelle la fonction globale dont le nom est dans reglages.technique.fonction_raccourci.
local _, ns = ...
local A = ns.Actions
local M = ns.Liste

local function cfg() return ns.donnees.reglages.actions end

-- Ce que fait chaque raccourci (identifiants dans reglages.actions.raccourcis).
function A.raccourci(id)
	if id == "fenetre" then
		ns.Fenetre.basculer()
	elseif id == "profils" then
		if ns.ProfilsUI then ns.ProfilsUI.basculer() end
	elseif id == "recharger" then
		M.recharger()
	elseif id == "antiseche" then
		ns.AideFenetre.basculer()
	elseif id == "mini" then
		ns.Fenetre.definirMini(ns.Fenetre.mode() ~= "mini")
	end
end

_G[ns.Reglages.technique().fonction_raccourci] = function(id) ns.Journal.proteger(A.raccourci, id) end

-- Les noms affichés dans Échap › Raccourcis.
function A.texteRaccourcis()
	local cle = ns.Reglages.technique().cle_commande
	_G["BINDING_HEADER_" .. cle] = ns.T("nom")
	for _, id in ipairs(cfg().raccourcis) do
		_G["BINDING_NAME_" .. cle .. "_" .. string.upper(id)] = ns.T("raccourci." .. id)
	end
end

function A.annoncerFinEssais(noms)
	if #noms == 0 or not ns.Reglages.lire("actions.essai_message") then return end
	local titres = {}
	for _, nom in ipairs(noms) do
		local e = M.parNom(nom)
		titres[#titres + 1] = e and e.titre or nom
	end
	ns.dire(ns.T("actions.essai_termine", #noms, table.concat(titres, cfg().separateur_liste)))
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function()
	ns.Journal.proteger(A.texteRaccourcis)
	-- les essais de la session qui vient de finir : éteints pour le prochain rechargement
	ns.Journal.proteger(function() A.annoncerFinEssais(A.finirEssais()) end)
	if ns.Reglages.lire("actions.resume_connexion") then
		C_Timer.After(cfg().delai_resume, function()
			ns.Journal.proteger(function() ns.dire(A.resume()) end)
		end)
	end
end)
