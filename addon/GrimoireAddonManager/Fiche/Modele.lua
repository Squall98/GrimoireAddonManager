-- Contenu d'une fiche : texte du fichier ou version modifiée en jeu (prioritaire), note perso, technique, dépendances, doublons, badges.
local _, ns = ...
local FM = {}
ns.FicheModele = FM

local function cfg() return ns.donnees.reglages.interface.fiche end

-- Sauvegardes du compte : compte.fiches = { textes = { [add-on] = { [langue de fiche] = {...} } }, notes = { [add-on] = "..." } }
local function stock()
	local c = ns.Reglages.compte
	c.fiches = c.fiches or {}
	c.fiches.textes = c.fiches.textes or {}
	c.fiches.notes = c.fiches.notes or {}
	return c.fiches
end

function FM.parties() return cfg().parties_ordre end
function FM.partie(id) return ns.Reglages.lire("fiche.parties." .. id) == true end
function FM.infobulleActive() return ns.Reglages.lire("fiche.infobulle") == true end

local CHAMPS = { "resume", "commandes", "remarques" }
FM.champs = CHAMPS

------------------------------------------------------------------ textes (fichier + version modifiée)
-- Texte du fichier de départ, dans la langue courante : { resume, commandes, remarques } ou nil.
function FM.original(nom) return ns.Fiches.texte(nom) end

-- Ce que le joueur a modifié en jeu pour la langue courante : { resume=..., ... } ou nil.
function FM.modifs(nom)
	local m = stock().textes[nom]
	return m and m[ns.Langue.codeFiche()] or nil
end

function FM.estModifiee(nom) return FM.modifs(nom) ~= nil end

-- Texte d'un champ : la version modifiée d'abord, sinon celle du fichier ("" si rien).
function FM.champ(nom, champ)
	local m = FM.modifs(nom)
	if m and m[champ] ~= nil then return m[champ] end
	local o = FM.original(nom)
	return o and o[champ] or ""
end

-- Résumé affiché : texte de la fiche, sinon notes du .toc, sinon « pas encore de fiche » (2e valeur : vrai si une fiche existe).
function FM.resume(e)
	local r = FM.champ(e.nom, "resume")
	if r ~= "" then return r, true end
	if e.notes and e.notes ~= "" then return e.notes, false end
	return ns.T("fiche.absente"), false
end

-- Enregistre les champs donnés (table champ -> texte) ; seuls ceux qui diffèrent du fichier sont gardés.
function FM.enregistrer(nom, valeurs)
	local max = ns.Reglages.lire("fiche.texte_max")
	local garde = {}
	for _, c in ipairs(CHAMPS) do
		local v = valeurs[c]
		if v ~= nil then
			v = string.sub(v, 1, max)
			local o = FM.original(nom)
			if v ~= (o and o[c] or "") then garde[c] = v end
		end
	end
	local s = stock()
	local code = ns.Langue.codeFiche()
	if next(garde) then
		s.textes[nom] = s.textes[nom] or {}
		s.textes[nom][code] = garde
		ns.Journal.ecrire("info", "journal.fiche_modifiee", nom, code)
	else
		FM.retablir(nom, true)
	end
end

-- Rend la fiche d'origine (pour la langue courante).
function FM.retablir(nom, silencieux)
	local s = stock()
	local m = s.textes[nom]
	if m then
		m[ns.Langue.codeFiche()] = nil
		if not next(m) then s.textes[nom] = nil end
		if not silencieux then ns.Journal.ecrire("info", "journal.fiche_retablie", nom) end
	end
end

------------------------------------------------------------------ note perso
function FM.note(nom) return stock().notes[nom] or "" end

function FM.definirNote(nom, texte)
	texte = string.sub(texte or "", 1, ns.Reglages.lire("fiche.note_max"))
	if texte == "" then stock().notes[nom] = nil else stock().notes[nom] = texte end
end

------------------------------------------------------------------ technique
function FM.memoire(nom)
	if not C_AddOns.IsAddOnLoaded(nom) then return ns.T("fiche.memoire_aucune") end
	if UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
	local ko = GetAddOnMemoryUsage and GetAddOnMemoryUsage(nom)
	if not ko then return ns.T("fiche.memoire_aucune") end
	local par_mo = cfg().memoire_ko_par_mo
	if ko >= par_mo then return ns.T("fiche.memoire_mo", ko / par_mo) end
	return ns.T("fiche.memoire_ko", math.floor(ko + 0.5))
end

function FM.etat(nom)
	if C_AddOns.IsAddOnLoaded(nom) then return ns.T("fiche.etat_charge") end
	if ns.Liste.actif(nom) then return ns.T("fiche.etat_actif") end
	return ns.T("fiche.etat_inactif")
end

-- Lignes de la partie « technique ».
function FM.technique(e)
	local f = e.fiche
	local inconnu = ns.T("fiche.inconnu")
	local function meta(champ)
		local v = C_AddOns.GetAddOnMetadata(e.nom, champ)
		if v == nil or v == "" then return inconnu end
		return v
	end
	local lignes = {
		ns.T("fiche.version", meta("Version")),
		ns.T("fiche.auteur", meta("Author")),
		ns.T("fiche.memoire", FM.memoire(e.nom)),
		ns.T("fiche.etat", FM.etat(e.nom)),
	}
	local utilite = ns.Recherche.utilite(e) -- le choix du joueur passe avant celui de la fiche
	if utilite then
		lignes[#lignes + 1] = ns.T("fiche.utilite", ns.T("utilite." .. utilite))
	end
	if f and f.verifie and f.verifie ~= "" then lignes[#lignes + 1] = ns.T("fiche.verifie", f.verifie) end
	return lignes
end

------------------------------------------------------------------ dépendances et doublons
-- Dépendances : celles de la fiche et celles du .toc, sans répétition. { nom, titre, etat = "actif"|"inactif"|"absent" }
function FM.dependances(e)
	local vus, res = {}, {}
	local function ajouter(d)
		if d and d ~= "" and d ~= e.nom and not vus[d] then
			vus[d] = true
			local autre = ns.Liste.parNom(d)
			local etat = "absent"
			if autre then etat = ns.Liste.actif(d) and "actif" or "inactif" end
			res[#res + 1] = { nom = d, titre = autre and autre.titre or d, etat = etat }
		end
	end
	if e.fiche then for _, d in ipairs(e.fiche.dependances or {}) do ajouter(d) end end
	for _, d in ipairs({ C_AddOns.GetAddOnDependencies(e.nom) }) do ajouter(d) end
	return res
end

-- Doublons activés en ce moment : { nom, titre, texte (explication ou nil) }.
function FM.doublonsActifs(e)
	local res, vus = {}, {}
	local function ajouter(d, texte)
		if d == e.nom then return end
		local autre = ns.Liste.parNom(d)
		if not autre or not ns.Liste.actif(d) then return end
		if vus[d] then
			if texte and not vus[d].texte then vus[d].texte = texte end
			return
		end
		vus[d] = { nom = d, titre = autre.titre, texte = texte }
		res[#res + 1] = vus[d]
	end
	local code = ns.Langue.codeFiche()
	for _, bloc in ipairs(ns.donnees.doublons or {}) do
		local dedans = false
		for _, n in ipairs(bloc.entre) do if n == e.nom then dedans = true end end
		if dedans then
			for _, n in ipairs(bloc.entre) do ajouter(n, bloc[code] or bloc.en) end
		end
	end
	if e.fiche then for _, d in ipairs(e.fiche.doublons or {}) do ajouter(d) end end
	return res
end

------------------------------------------------------------------ badges
function FM.badges(e)
	local res = {}
	local function b(id) res[#res + 1] = ns.T("badge." .. id) end
	if e.moi then b("moi") end
	if e.inutile then b("inutile") end
	if #FM.doublonsActifs(e) > 0 and ns.Liste.actif(e.nom) then b("doublon") end
	if ns.Liste.actif(e.nom) then
		for _, d in ipairs(FM.dependances(e)) do
			if d.etat ~= "actif" then b("dependance") break end
		end
	end
	if not e.fiche then b("sans_fiche") end
	if FM.estModifiee(e.nom) then b("perso") end
	if FM.note(e.nom) ~= "" then b("note") end
	return res
end

------------------------------------------------------------------ boutons : lien et réglages
-- Adresse CurseForge : celle de la fiche, sinon construite avec l'identifiant du .toc ; "" si inconnue.
function FM.lien(e)
	local f = e.fiche
	if f and f.curseforge and f.curseforge ~= "" then return f.curseforge end
	local id = C_AddOns.GetAddOnMetadata(e.nom, "X-Curse-Project-ID")
	if id and id ~= "" then return string.format(cfg().curse_projet, id) end
	return ""
end

-- Première commande de la fiche (ex. "/atr") ou nil.
function FM.premiereCommande(nom)
	local texte = FM.champ(nom, "commandes")
	return string.match(texte, cfg().commande_motif)
end

-- Fonction de la commande /xxx dans le jeu, ou nil.
local function chercherCommande(commande)
	local voulu = string.lower(commande)
	for k, v in pairs(_G) do
		if type(k) == "string" and type(v) == "string" and string.sub(k, 1, 6) == "SLASH_" and string.lower(v) == voulu then
			local cle = string.gsub(string.sub(k, 7), "%d+$", "")
			if SlashCmdList and SlashCmdList[cle] then return SlashCmdList[cle] end
		end
	end
end

-- Ouvre les réglages d'un add-on en lançant sa première commande. Renvoie "ok" + la commande, ou "inactif", "aucun", "erreur".
function FM.ouvrirReglages(e)
	if not C_AddOns.IsAddOnLoaded(e.nom) then return "inactif" end
	local commande = FM.premiereCommande(e.nom)
	local f = commande and chercherCommande(commande)
	if not f then return "aucun" end
	local ok = pcall(f, "")
	if not ok then return "erreur" end
	ns.Journal.ecrire("info", "journal.fiche_reglages", e.nom, commande)
	return "ok", commande
end
