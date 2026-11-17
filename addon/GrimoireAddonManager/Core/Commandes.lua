-- Commandes « slash » : noms pris dans les réglages (modifiables), détection des commandes déjà prises, sous-commandes.
local _, ns = ...
local C = {}
ns.Commandes = C

C.actives = {}  -- noms enregistrés, dans l'ordre
C.refusees = {} -- nom -> commande du jeu ou de l'add-on qui l'occupe déjà
C.sous = {}     -- identifiant de sous-commande -> fonction(arguments)

local function cle() return ns.Reglages.technique().cle_commande end

-- Quelle commande (clé SlashCmdList) occupe déjà /nom ? nil si libre. Nos propres commandes sont ignorées.
function C.prise_par(nom)
	local voulu = string.lower("/" .. nom)
	for k, v in pairs(_G) do
		if type(k) == "string" and type(v) == "string" and string.sub(k, 1, 6) == "SLASH_" and string.lower(v) == voulu then
			local autre = string.gsub(string.sub(k, 7), "%d+$", "")
			if autre ~= cle() then return autre end
		end
	end
	return nil
end

local function nom_valide(nom)
	return type(nom) == "string" and string.find(nom, "^[A-Za-z0-9]+$") ~= nil
end
C.nom_valide = nom_valide

-- Premier mot du texte tapé, et le reste.
local function decouper(texte)
	local mot, reste = string.match(texte or "", "^%s*(%S*)%s*(.-)%s*$")
	return mot or "", reste or ""
end

-- Un mot correspond-il au texte `cle` dans une langue quelconque ?
local function mot_est(mot, cle_texte)
	mot = string.lower(mot)
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle_texte)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

function C.principale() return C.actives[1] end

-- (Re)enregistre les commandes de la liste des réglages ; les noms déjà pris sont refusés et notés au journal.
function C.enregistrer()
	local k = cle()
	local i = 1
	while _G["SLASH_" .. k .. i] do
		_G["SLASH_" .. k .. i] = nil
		i = i + 1
	end
	C.actives, C.refusees = {}, {}
	for _, nom in ipairs(ns.Reglages.lire("commandes.liste")) do
		if not nom_valide(nom) then
			ns.Journal.ecrire("avertissement", "journal.commande_invalide", nom)
		else
			local autre = C.prise_par(nom)
			if autre then
				C.refusees[nom] = autre
				ns.Journal.ecrire("avertissement", "journal.commande_prise", nom, autre)
			else
				C.actives[#C.actives + 1] = nom
				_G["SLASH_" .. k .. #C.actives] = "/" .. nom
				ns.Journal.ecrire("info", "journal.commande_ok", nom)
			end
		end
	end
	SlashCmdList[k] = C.executer
end

function C.executer(texte)
	local mot, reste = decouper(texte)
	if mot == "" then
		mot = ns.T("sous." .. ns.Reglages.lire("commandes.sans_argument") .. ".nom")
	end
	for _, id in ipairs(ns.donnees.reglages.sous_commandes) do
		if mot_est(mot, "sous." .. id .. ".nom") then
			return ns.Journal.proteger(C.sous[id], reste)
		end
	end
	ns.dire(ns.T("commandes.inconnue", mot, C.principale() or ns.Reglages.technique().cle_commande))
end

function C.sous.aide()
	ns.dire(ns.T("aide.titre", C.principale() or ""))
	for _, id in ipairs(ns.donnees.reglages.sous_commandes) do
		ns.dire(ns.T("aide.ligne", ns.T("sous." .. id .. ".nom"), ns.T("sous." .. id .. ".desc")))
	end
end

function C.sous.ouvrir()
	if ns.ouvrirFenetre then ns.ouvrirFenetre() else ns.dire(ns.T("ouvrir.bientot")) end
end

function C.sous.version()
	local version = C_AddOns.GetAddOnMetadata(ns.nom, "Version")
	local interface = select(4, GetBuildInfo())
	ns.dire(ns.T("version.ligne", version, interface, ns.Langue.nom(ns.Langue.code()),
		ns.Fiches.nombre(), ns.Fiches.nombreCategories(), ns.Fiches.nombreProfils()))
end

function C.sous.journal(reste)
	if reste ~= "" and mot_est(reste, "arg.effacer") then
		ns.Journal.effacer()
		return ns.dire(ns.T("journal.efface"))
	end
	local lignes = ns.Journal.lignes()
	if #lignes == 0 then return ns.dire(ns.T("journal.vide")) end
	local n = math.min(#lignes, ns.Reglages.lire("journal.lignes_chat"))
	ns.dire(ns.T("journal.titre", #lignes, n))
	for i = #lignes - n + 1, #lignes do ns.dire(ns.Journal.formater(lignes[i])) end
end

function C.sous.langue(reste)
	local dispo = table.concat(ns.Langue.disponibles(), ", ") .. ", " .. ns.T("arg.auto")
	if reste == "" then
		return ns.dire(ns.T("langue.actuelle", ns.Langue.nom(ns.Langue.code()), ns.Reglages.lire("langue.choix"), dispo))
	end
	local choix
	if mot_est(reste, "arg.auto") then
		choix = "auto"
	else
		for _, code in ipairs(ns.Langue.disponibles()) do
			if string.lower(code) == string.lower(reste) then choix = code end
		end
	end
	if not choix then return ns.dire(ns.T("langue.invalide", reste, dispo)) end
	ns.Reglages.ecrire("langue.choix", choix)
	ns.Journal.ecrire("info", "journal.langue", choix)
	ns.dire(ns.T("langue.changee", ns.Langue.nom(ns.Langue.code())))
end

local function position(liste, nom)
	for i, n in ipairs(liste) do
		if string.lower(n) == string.lower(nom) then return i end
	end
end

function C.sous.commandes(reste)
	local action, nom = decouper(reste)
	if action == "" then
		ns.dire(ns.T("commandes.titre"))
		local vu = false
		for _, n in ipairs(ns.Reglages.lire("commandes.liste")) do
			if C.refusees[n] then
				ns.dire(ns.T("commandes.prise", n, C.refusees[n]))
				vu = true
			elseif position(C.actives, n) then
				ns.dire(ns.T("commandes.active", n))
				vu = true
			end
		end
		if not vu or #C.actives == 0 then ns.dire(ns.T("commandes.aucune")) end
		return
	end
	local liste = ns.Reglages.copie(ns.Reglages.lire("commandes.liste"))
	if mot_est(action, "arg.ajouter") then
		if not nom_valide(nom) then return ns.dire(ns.T("commandes.invalide", nom)) end
		if position(liste, nom) then return ns.dire(ns.T("commandes.deja", nom)) end
		liste[#liste + 1] = string.lower(nom)
		ns.Reglages.ecrire("commandes.liste", liste)
		C.enregistrer()
		if C.refusees[string.lower(nom)] then
			return ns.dire(ns.T("commandes.prise", string.lower(nom), C.refusees[string.lower(nom)]))
		end
		return ns.dire(ns.T("commandes.ajoutee", string.lower(nom)))
	elseif mot_est(action, "arg.retirer") then
		local i = position(liste, nom)
		if not i then return ns.dire(ns.T("commandes.absente", nom)) end
		table.remove(liste, i)
		ns.Reglages.ecrire("commandes.liste", liste)
		C.enregistrer()
		return ns.dire(ns.T("commandes.retiree", string.lower(nom)))
	end
	ns.dire(ns.T("commandes.usage"))
end
