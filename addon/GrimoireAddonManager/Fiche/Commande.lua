-- Sous-commande « fiche » : activer ou couper l'infobulle et chaque partie de la fiche (en attendant la page d'options).
local _, ns = ...
local FM = ns.FicheModele

-- Un mot est-il « oui » ou « non » ? (dans toutes les langues du gestionnaire) -> true, false ou nil
local function oui_non(mot)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		if mot == string.lower(ns.Langue.texte(code, "arg.on") or "") then return true end
		if mot == string.lower(ns.Langue.texte(code, "arg.off") or "") then return false end
	end
end

local function mot_est(mot, cle)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

-- Réglages commandés : l'infobulle puis chaque partie, avec leur chemin dans les réglages.
local function cibles()
	local res = { { cle = "fiche.infobulle", chemin = "fiche.infobulle" } }
	for _, id in ipairs(FM.parties()) do
		res[#res + 1] = { cle = "fiche.partie." .. id, chemin = "fiche.parties." .. id }
	end
	return res
end

local function etat(valeur) return ns.T(valeur and "arg.on" or "arg.off") end

ns.Commandes.sous.fiche = function(reste)
	local mot, valeur = string.match(reste or "", "^%s*(%S*)%s*(.-)%s*$")
	local liste = cibles()
	if mot == "" then
		for _, c in ipairs(liste) do
			ns.dire(ns.T("fiche.reglage_ligne", ns.T(c.cle), etat(ns.Reglages.lire(c.chemin) == true)))
		end
		return
	end
	local noms = {}
	for _, c in ipairs(liste) do
		noms[#noms + 1] = ns.T(c.cle)
		if mot_est(mot, c.cle) or string.lower(mot) == string.lower(c.chemin:match("[^%.]+$")) then
			local v = oui_non(valeur)
			if v == nil then
				if valeur ~= "" then return ns.dire(ns.T("fiche.usage", table.concat(noms, ", "))) end
				v = not (ns.Reglages.lire(c.chemin) == true)
			end
			ns.Reglages.ecrire(c.chemin, v)
			ns.Journal.ecrire("info", "journal.fiche_choix", ns.T(c.cle), etat(v))
			ns.dire(ns.T("fiche.reglage_change", ns.T(c.cle), etat(v)))
			if ns.Fenetre and ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
			return
		end
	end
	local tous = {}
	for _, c in ipairs(liste) do tous[#tous + 1] = ns.T(c.cle) end
	ns.dire(ns.T("fiche.usage", table.concat(tous, ", ")))
end
