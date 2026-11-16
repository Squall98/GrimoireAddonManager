-- Liste des add-ons : lecture dans le jeu, catégories, sous-modules, état coché, changements en attente, annuler.
local _, ns = ...
local M = {}
ns.Liste = M

M.historique = {} -- états précédents (les plus anciens d'abord), au plus `fenetre.annuler_max`

local function ui() return ns.donnees.reglages.interface end

-- Titre ou notes sans codes de couleur ni images en ligne.
local function nettoyer(texte)
	texte = string.gsub(texte or "", "|c%x%x%x%x%x%x%x%x", "")
	texte = string.gsub(texte, "|r", "")
	texte = string.gsub(texte, "|T.-|t", "")
	return texte
end

-- Clé de tri : minuscules, sans accents.
function M.cleTri(texte)
	texte = string.lower(texte or "")
	for avec, sans in pairs(ui().sans_accent) do
		texte = string.gsub(texte, avec, sans)
	end
	return texte
end

-- Un add-on est « prévu pour Forever » s'il n'annonce pas de numéro d'interface, ou s'il cite celui du jeu.
local function prevuPourForever(nom)
	local interface = C_AddOns.GetAddOnMetadata(nom, "Interface")
	if (not interface or interface == "") and C_AddOns.GetAddOnInterfaceVersion then
		interface = tostring(C_AddOns.GetAddOnInterfaceVersion(nom) or "")
		if interface == "0" then interface = "" end
	end
	if not interface or interface == "" then return true end
	local voulu = tostring(select(4, GetBuildInfo()))
	for numero in string.gmatch(interface, "%d+") do
		if numero == voulu then return true end
	end
	return false
end

-- Construit (une fois) le modèle : entrées, parents, modules, catégories.
function M.construire()
	local entrees, par_nom = {}, {}
	for i = 1, C_AddOns.GetNumAddOns() do
		local nom, titre, notes = C_AddOns.GetAddOnInfo(i)
		if nom then
			local propre = nettoyer(titre)
			if propre == "" then propre = nom end
			local e = {
				nom = nom, titre = propre, notes = nettoyer(notes), fiche = ns.Fiches.obtenir(nom),
				modules = {}, moi = (nom == ns.nom), inutile = not prevuPourForever(nom),
			}
			e.cle = M.cleTri(propre)
			entrees[#entrees + 1] = e
			par_nom[nom] = e
		end
	end
	-- parents : un module cite un add-on principal installé (dans la fiche, ou dans ses dépendances)
	for _, e in ipairs(entrees) do
		local f = e.fiche
		local module = (f and f.type == "module") or (not f and C_AddOns.IsAddOnLoadOnDemand(e.nom))
		if module then
			local candidats = {}
			if f then for _, d in ipairs(f.dependances) do candidats[#candidats + 1] = d end end
			for _, d in ipairs({ C_AddOns.GetAddOnDependencies(e.nom) }) do candidats[#candidats + 1] = d end
			for _, d in ipairs(candidats) do
				if par_nom[d] and d ~= e.nom then e.parent = par_nom[d] break end
			end
		end
	end
	-- un seul niveau : un module d'un module est rattaché au principal du dessus
	for _, e in ipairs(entrees) do
		local garde = 0
		while e.parent and e.parent.parent and garde < 5 do
			e.parent = e.parent.parent
			garde = garde + 1
		end
		if e.parent == e then e.parent = nil end
	end
	local racines = {}
	for _, e in ipairs(entrees) do
		if e.parent then
			table.insert(e.parent.modules, e)
		else
			racines[#racines + 1] = e
		end
	end
	local function par_titre(a, b) return a.cle < b.cle end
	table.sort(racines, par_titre)
	local categories_connues = ns.donnees.categories
	local autres = ui().categorie_autres
	for _, e in ipairs(racines) do
		table.sort(e.modules, par_titre)
		local c = e.fiche and e.fiche.categories and e.fiche.categories[1]
		e.categorie = (c and categories_connues[c]) and c or autres
		for _, m in ipairs(e.modules) do m.categorie = e.categorie end
	end
	M.liste, M.par_nom, M.racines = entrees, par_nom, racines
	return M
end

local function pret()
	if not M.liste then M.construire() end
	return M
end

function M.entrees() return pret().liste end
function M.parNom(nom) return pret().par_nom[nom] end
function M.lesRacines() return pret().racines end

-- Entrées d'une catégorie (modules compris) ; "tous" = toutes.
function M.entreesCategorie(id)
	local res = {}
	for _, e in ipairs(M.entrees()) do
		if id == ui().categorie_tous or e.categorie == id then res[#res + 1] = e end
	end
	return res
end

-- Catégories non vides : { id, nom, n }, « Tous » en tête, « Autres » en dernier.
function M.categories()
	local comptes = {}
	for _, e in ipairs(M.entrees()) do
		comptes[e.categorie] = (comptes[e.categorie] or 0) + 1
	end
	local res = {}
	for id, n in pairs(comptes) do
		if id ~= ui().categorie_autres then
			res[#res + 1] = { id = id, nom = ns.Fiches.nomCategorie(id), n = n }
		end
	end
	table.sort(res, function(a, b) return M.cleTri(a.nom) < M.cleTri(b.nom) end)
	table.insert(res, 1, { id = ui().categorie_tous, nom = ns.T("cat.tous"), n = #M.entrees() })
	if comptes[ui().categorie_autres] then
		res[#res + 1] = { id = ui().categorie_autres, nom = ns.T("cat.autres"), n = comptes[ui().categorie_autres] }
	end
	return res
end

function M.nomCategorie(id)
	if id == ui().categorie_tous then return ns.T("cat.tous") end
	if id == ui().categorie_autres then return ns.T("cat.autres") end
	return ns.Fiches.nomCategorie(id)
end

------------------------------------------------------------------ états
function M.actif(nom) return C_AddOns.GetAddOnEnableState(nom) ~= 0 end

function M.etats()
	local t = {}
	for _, e in ipairs(M.entrees()) do t[e.nom] = M.actif(e.nom) end
	return t
end

-- État au démarrage de la session (pris à la connexion) : sert à compter les changements en attente.
function M.capturer() M.base_etats = M.etats() end
function M.base()
	if not M.base_etats then M.capturer() end
	return M.base_etats
end

function M.modifie(nom) return M.actif(nom) ~= M.base()[nom] end

function M.enAttente()
	local n, noms = 0, {}
	local base = M.base()
	for _, e in ipairs(M.entrees()) do
		if M.actif(e.nom) ~= base[e.nom] then
			n = n + 1
			noms[#noms + 1] = e.nom
		end
	end
	return n, noms
end

-- Compte les activés d'une catégorie : actifs, total, et pareil pour les seuls activables.
function M.etatCategorie(id)
	local actifs, total, actifsA, totalA = 0, 0, 0, 0
	for _, e in ipairs(M.entreesCategorie(id)) do
		total = total + 1
		local on = M.actif(e.nom)
		if on then actifs = actifs + 1 end
		if not e.inutile then
			totalA = totalA + 1
			if on then actifsA = actifsA + 1 end
		end
	end
	return actifs, total, actifsA, totalA
end

------------------------------------------------------------------ actions
local function appliquer(nom, valeur)
	if valeur then C_AddOns.EnableAddOn(nom) else C_AddOns.DisableAddOn(nom) end
end

local function pousserHistorique()
	local h = M.historique
	h[#h + 1] = M.etats()
	local max = ns.Reglages.lire("fenetre.annuler_max")
	while #h > max do table.remove(h, 1) end
end

-- Met la liste de noms à `valeur` d'un seul geste (une seule entrée dans l'historique). Renvoie le nombre de changements.
function M.definir(noms, valeur)
	local changes = {}
	for _, nom in ipairs(noms) do
		local e = M.parNom(nom)
		if e and M.actif(nom) ~= valeur and not (e.moi and not valeur) then changes[#changes + 1] = nom end
	end
	if #changes == 0 then return 0 end
	pousserHistorique()
	for _, nom in ipairs(changes) do appliquer(nom, valeur) end
	if #changes == 1 then
		ns.Journal.ecrire("info", valeur and "journal.liste_active" or "journal.liste_desactive", changes[1])
	else
		ns.Journal.ecrire("info", valeur and "journal.liste_lot_active" or "journal.liste_lot_desactive", #changes)
	end
	return #changes
end

-- Active `on` et désactive `off` d'un seul geste (une seule entrée dans l'historique) ; ce gestionnaire n'est jamais coupé.
-- Renvoie le nombre de changements. Sert à appliquer un profil.
function M.lot(on, off)
	local changes = {}
	for _, nom in ipairs(on or {}) do
		if M.parNom(nom) and not M.actif(nom) then changes[#changes + 1] = { nom, true } end
	end
	for _, nom in ipairs(off or {}) do
		local e = M.parNom(nom)
		if e and M.actif(nom) and not e.moi then changes[#changes + 1] = { nom, false } end
	end
	if #changes == 0 then return 0 end
	pousserHistorique()
	for _, c in ipairs(changes) do appliquer(c[1], c[2]) end
	return #changes
end

-- Coche ou décoche un add-on ; un principal entraîne ses modules (sauf les modules inutiles qu'on n'active pas).
function M.basculer(nom, valeur)
	local e = M.parNom(nom)
	if not e then return 0 end
	local cibles = { nom }
	for _, m in ipairs(e.modules) do
		if not (valeur and m.inutile) then cibles[#cibles + 1] = m.nom end
	end
	return M.definir(cibles, valeur)
end

-- La case de la catégorie est cochée quand tous ses add-ons activables sont actifs
-- (une catégorie sans aucun add-on activable compte alors tous ses add-ons).
function M.categorieToutActive(id)
	local actifs, total, actifsA, totalA = M.etatCategorie(id)
	if totalA > 0 then return actifsA == totalA end
	return total > 0 and actifs == total
end

-- Tous les add-ons d'un coup : activer (sauf ceux qui ne sont pas prévus pour le jeu) ou désactiver (sauf ce gestionnaire).
function M.tout(valeur)
	local cibles = {}
	for _, e in ipairs(M.entrees()) do
		if not (valeur and e.inutile) then cibles[#cibles + 1] = e.nom end
	end
	return M.definir(cibles, valeur)
end

-- Une case sur la catégorie : si tout est déjà actif, tout se désactive, sinon tout s'active.
function M.basculerCategorie(id)
	local valeur = not M.categorieToutActive(id)
	local cibles = {}
	for _, e in ipairs(M.entreesCategorie(id)) do
		if valeur then
			if not e.inutile then cibles[#cibles + 1] = e.nom end
		else
			cibles[#cibles + 1] = e.nom
		end
	end
	return valeur, M.definir(cibles, valeur)
end

function M.nombreAnnulations() return #M.historique end

-- Revient à l'état d'avant la dernière modification.
function M.annuler()
	local dernier = table.remove(M.historique)
	if not dernier then return false end
	for nom, valeur in pairs(dernier) do
		if M.actif(nom) ~= valeur then appliquer(nom, valeur) end
	end
	ns.Journal.ecrire("info", "journal.liste_annule")
	return true
end

-- Enregistre les choix puis recharge l'interface (les activations ne prennent effet qu'au rechargement).
function M.recharger()
	local n = M.enAttente()
	ns.Journal.ecrire("info", "journal.liste_recharge", n)
	if C_AddOns.SaveAddOns then pcall(C_AddOns.SaveAddOns) end
	ReloadUI()
end

-- État de départ de la session : pris à la connexion du personnage.
local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function() M.capturer() end)
