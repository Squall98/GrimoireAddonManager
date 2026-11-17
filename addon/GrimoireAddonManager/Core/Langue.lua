-- Langue de l'interface : français et anglais, choix automatique selon le jeu ou réglage.
local _, ns = ...
local L = {}
ns.Langue = L

local function reglages() return ns.donnees.reglages.langue end

function L.disponibles()
	local liste = {}
	for code in pairs(reglages().disponibles) do liste[#liste + 1] = code end
	table.sort(liste)
	return liste
end

-- Code de langue réellement utilisé (ex. "frFR").
function L.code()
	local dispo = reglages().disponibles
	local choix = ns.Reglages.lire("langue.choix")
	if choix == "auto" or choix == nil then choix = GetLocale() end
	if dispo[choix] then return choix end
	return reglages().repli
end

-- Code de langue des fiches (ex. "fr").
function L.codeFiche(code)
	return reglages().disponibles[code or L.code()].fiche
end

function L.nom(code)
	local d = reglages().disponibles[code]
	return d and d.nom or tostring(code)
end

-- Texte traduit ; repli sur la langue de repli, puis sur la clé elle-même.
function ns.T(cle, ...)
	local textes = ns.donnees.textes
	local t = textes[L.code()]
	local s = t and t[cle]
	if s == nil then
		local repli = textes[reglages().repli]
		s = repli and repli[cle]
	end
	if s == nil then return cle end
	if select("#", ...) > 0 then
		local ok, res = pcall(string.format, s, ...)
		if ok then return res end
	end
	return s
end

-- Texte dans une langue précise (sans repli sur la langue courante).
function L.texte(code, cle)
	local t = ns.donnees.textes[code]
	return t and t[cle]
end
