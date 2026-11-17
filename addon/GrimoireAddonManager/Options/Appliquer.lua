-- Options : changer un réglage et en appliquer tout de suite l'effet (peinture, taille, commandes, accès…).
local _, ns = ...
local O = {}
ns.Options = O

O.instances = {} -- panneaux d'options construits (volet de la fenêtre, page du jeu) : tous suivent les changements

local function ui() return ns.donnees.reglages.interface.options end

-- Ce qui doit suivre un changement : nom donné par le schéma (`apres`).
local suites = {
	peindre = function() ns.Style.repeindre() end,
	taille = function() ns.Fenetre.reinitialiserTaille() end,
	mini = function() ns.Fenetre.definirMini(ns.Reglages.lire("fenetre.compact")) end,
	echap = function() ns.Fenetre.majEchap() end,
	minicarte = function() ns.Acces.placer() ns.Acces.majVisibilite() end,
	commandes = function() ns.Commandes.enregistrer() end,
	langue = function() end,
	disposer = function() if ns.Fenetre.cadre then ns.Fenetre.disposer() end end,
}

function O.toutRafraichir()
	for _, inst in ipairs(O.instances) do inst.rafraichir() end
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end

function O.suite(apres)
	if apres and suites[apres] then ns.Journal.proteger(suites[apres]) end
end

-- Écrit un réglage (si la valeur a le bon type), applique la suite, met tout à jour. Renvoie vrai ou faux.
function O.definir(chemin, valeur, apres)
	local ok = ns.Reglages.ecrire(chemin, valeur)
	if not ok then
		ns.Journal.ecrire("avertissement", "journal.reglage_refuse", chemin, type(valeur))
		return false
	end
	ns.Journal.ecrire("debug", "journal.option", chemin, tostring(valeur))
	O.suite(apres)
	O.toutRafraichir()
	return true
end

-- Les groupes de réglages remis à leur valeur de départ (tout sauf les sauvegardes de données : favoris, notes…).
function O.toutReinitialiser()
	for cle in pairs(ns.Reglages.defauts()) do ns.Reglages.reinitialiser(cle) end
	for _, apres in ipairs({ "peindre", "taille", "echap", "minicarte", "commandes" }) do O.suite(apres) end
	ns.Journal.ecrire("info", "journal.option_reinit")
	O.toutRafraichir()
end

-- Actions des boutons du panneau (schéma : type "action").
O.actions = {
	reinit_tailles = function()
		ns.Fenetre.reinitialiserTaille()
		if ns.AideFenetre and ns.AideFenetre.reinitialiserTaille then ns.AideFenetre.reinitialiserTaille() end
	end,
	tout_vu = function() ns.Journal.ecrire("info", "journal.vus", ns.Recherche.toutVu()) end,
	effacer_journal = function() ns.Journal.effacer() end,
	tout_reinitialiser = function() O.toutReinitialiser() end,
	ouvrir_antiseche = function() ns.AideFenetre.ouvrir() end,
	revoir_visite = function() ns.Visite.demarrer() end,
}

function O.faireAction(id)
	local f = O.actions[id]
	if f then ns.Journal.proteger(f) end
	O.toutRafraichir()
end

function O.demandeConfirmation(id)
	for _, x in ipairs(ui().confirmer) do if x == id then return true end end
	return false
end

-- Nom de commande de remplacement quand celui qu'on veut est déjà pris par un autre add-on.
function O.proposer(nom, liste)
	local C = ns.Commandes
	local function libre(c)
		if not C.nom_valide(c) or C.prise_par(c) then return false end
		for _, n in ipairs(liste or {}) do if string.lower(n) == c then return false end end
		return true
	end
	nom = string.lower(nom)
	for _, suffixe in ipairs(ui().suggestions_suffixes) do
		if libre(nom .. suffixe) then return nom .. suffixe end
	end
	return ui().suggestion_prefixe .. nom
end

-- Lignes d'état des commandes d'ouverture : { { texte, ok } } d'après l'enregistrement en cours.
function O.etatCommandes()
	local C = ns.Commandes
	local res = {}
	local liste = ns.Reglages.lire("commandes.liste")
	for _, n in ipairs(liste) do
		if not C.nom_valide(n) then
			res[#res + 1] = { texte = ns.T("opt.cmd.invalide", n), ok = false }
		elseif C.refusees[n] then
			res[#res + 1] = { texte = ns.T("opt.cmd.prise", n, C.refusees[n], O.proposer(n, liste)), ok = false }
		else
			res[#res + 1] = { texte = ns.T("opt.cmd.active", n), ok = true }
		end
	end
	if #liste == 0 then res[1] = { texte = ns.T("opt.cmd.vide"), ok = false } end
	return res
end

-- « maa  mesaddons,x » -> { "maa", "mesaddons", "x" }
function O.analyserCommandes(texte)
	local res, vus = {}, {}
	for mot in string.gmatch(texte or "", "[^%s,/]+") do
		mot = string.lower(mot)
		if not vus[mot] then
			vus[mot] = true
			res[#res + 1] = mot
		end
	end
	return res
end
