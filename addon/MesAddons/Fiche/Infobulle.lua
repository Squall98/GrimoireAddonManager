-- Infobulle au survol d'une ligne de la liste : résumé, commandes, à savoir, note, technique, dépendances, doublons.
-- Chaque partie suit les réglages « fiche.parties.* » ; l'infobulle entière se coupe avec « fiche.infobulle ».
local _, ns = ...
local I = {}
ns.Infobulle = I

local FM = ns.FicheModele
local S = ns.Style
local function cfg() return ns.donnees.reglages.interface.fiche end

local function coupe(texte, max)
	texte = string.gsub(texte, "%s*\n%s*", " ")
	if string.len(texte) > max then texte = string.sub(texte, 1, max) .. "…" end
	return texte
end

-- Lignes de l'infobulle, sans la dessiner : { { texte, couleur, retour }, ... } (sert aussi aux captures du banc d'essai).
function I.lignes(e)
	local L = {}
	local function ajouter(texte, couleur, retour)
		if texte and texte ~= "" then L[#L + 1] = { texte = texte, couleur = couleur or "texte", retour = retour ~= false } end
	end
	ajouter(e.titre, "dore_clair", false)
	local nature = ns.T(e.parent and "fiche.type_module" or "fiche.type_principal")
	ajouter(nature .. ns.donnees.reglages.interface.separateur_info .. ns.Liste.nomCategorie(e.categorie), "texte_doux")
	if FM.partie("badges") then
		local b = FM.badges(e)
		if #b > 0 then ajouter(table.concat(b, cfg().separateur_badges), "dore") end
	end
	if FM.partie("resume") then
		local resume, avec_fiche = FM.resume(e)
		ajouter(resume, avec_fiche and "texte" or "texte_eteint")
	end
	if FM.partie("commandes") then
		local c = FM.champ(e.nom, "commandes")
		if c ~= "" then ajouter(ns.T("fiche.commandes") .. " : " .. c, "texte_doux") end
	end
	if FM.partie("remarques") then
		local r = FM.champ(e.nom, "remarques")
		if r ~= "" then ajouter(ns.T("fiche.remarques") .. " : " .. r, "texte_doux") end
	end
	if FM.partie("note") then
		local n = FM.note(e.nom)
		if n ~= "" then ajouter(ns.T("fiche.note") .. " : " .. coupe(n, cfg().note_infobulle_max), "dore") end
	end
	if FM.partie("dependances") then
		local deps = FM.dependances(e)
		if #deps > 0 then
			ajouter(ns.T("fiche.dependances"), "dore", false)
			for _, d in ipairs(deps) do
				ajouter(cfg().marque_liste .. " " .. ns.T("fiche.dep." .. d.etat, d.titre), d.etat == "actif" and "texte_doux" or "dore_clair", false)
			end
		end
	end
	if FM.partie("doublons") then
		local dbl = FM.doublonsActifs(e)
		if #dbl > 0 then
			ajouter(ns.T("fiche.doublons"), "dore", false)
			for _, d in ipairs(dbl) do
				local t = d.texte and ns.T("fiche.doublon_avec", d.titre, d.texte) or d.titre
				ajouter(cfg().marque_liste .. " " .. t, "dore_clair")
			end
		end
	end
	if FM.partie("technique") then
		local t = FM.technique(e)
		ajouter(t[1] .. ns.donnees.reglages.interface.separateur_info .. t[3], "texte_eteint", false)
	end
	ajouter(ns.T("infobulle.clic"), "texte_eteint", false)
	return L
end

function I.montrer(ligne, e)
	if not e or not FM.infobulleActive() or not GameTooltip then return end
	local tip = GameTooltip
	tip:SetOwner(ligne, cfg().ancre_infobulle)
	tip:ClearLines()
	for _, l in ipairs(I.lignes(e)) do
		local r, g, b = S.couleur(l.couleur)
		tip:AddLine(l.texte, r, g, b, l.retour)
	end
	tip:Show()
	I.proprietaire = ligne
end

function I.cacher(ligne)
	if GameTooltip and (ligne == nil or I.proprietaire == ligne) then
		GameTooltip:Hide()
		I.proprietaire = nil
	end
end
