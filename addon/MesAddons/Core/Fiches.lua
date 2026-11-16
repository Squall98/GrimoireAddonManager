-- Accès aux fiches d'add-ons (données de départ, Donnees\Fiches.lua).
local _, ns = ...
local F = {}
ns.Fiches = F

local function compter(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

function F.obtenir(dossier) return ns.donnees.fiches[dossier] end
function F.nombre() return compter(ns.donnees.fiches) end
function F.nombreCategories() return compter(ns.donnees.categories) end
function F.nombreProfils() return compter(ns.donnees.profils) end

-- Texte de la fiche dans la langue courante : { resume, commandes, remarques } ou nil si pas de fiche.
function F.texte(dossier)
	local f = ns.donnees.fiches[dossier]
	if not f then return nil end
	return f[ns.Langue.codeFiche()] or f[ns.Langue.codeFiche(ns.donnees.reglages.langue.repli)]
end

-- Résumé affichable : le texte de la fiche, ou « pas encore de fiche » (2e valeur : false).
function F.resume(dossier)
	local t = F.texte(dossier)
	if t and t.resume and t.resume ~= "" then return t.resume, true end
	return ns.T("fiche.absente"), false
end

-- Nom d'affichage d'une catégorie dans la langue courante.
function F.nomCategorie(id)
	local c = ns.donnees.categories[id]
	if not c then return id end
	return c[ns.Langue.codeFiche()] or c.en or id
end
