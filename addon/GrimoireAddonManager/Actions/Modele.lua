-- Actions rapides : activer seul, activer avec ses modules, essai d'une session, mode dépannage et retour,
-- charger les périmés, compteur et résumé. Rien n'est dessiné ici ; tout passe par ns.Liste (historique « Annuler »).
-- Sauvegarde du compte : compte.actions = { depannage = { etats, date }, essai_deps = { [add-on] = { dépendances allumées } } }.
local _, ns = ...
local A = {}
ns.Actions = A

local M, R = ns.Liste, ns.Recherche
local function cfg() return ns.donnees.reglages.actions end

local function stock()
	local c = ns.Reglages.compte
	c.actions = c.actions or {}
	c.actions.essai_deps = c.actions.essai_deps or {}
	return c.actions
end

-- Retrouve un add-on par son dossier, par son titre, sinon par le début de son nom.
function A.trouver(mot)
	if not mot or mot == "" then return nil end
	local e = M.parNom(mot)
	if e then return e end
	local bas = M.cleTri(mot)
	local candidat
	for _, x in ipairs(M.entrees()) do
		if x.cle == bas or M.cleTri(x.nom) == bas then return x end
		if not candidat and string.sub(M.cleTri(x.nom), 1, #bas) == bas then candidat = x end
	end
	return candidat
end

-- Les noms donnés + leurs dépendances requises (récursif), sans doublon, seulement ce qui est installé.
function A.avecDependances(noms)
	local res, vus = {}, {}
	local function ajouter(nom, profondeur)
		if vus[nom] or profondeur > cfg().profondeur_max or not M.parNom(nom) then return end
		vus[nom] = true
		res[#res + 1] = nom
		for _, d in ipairs({ C_AddOns.GetAddOnDependencies(nom) }) do ajouter(d, profondeur + 1) end
	end
	for _, nom in ipairs(noms) do ajouter(nom, 1) end
	return res
end

-- Ce qui ne doit jamais être coupé : ce gestionnaire, les verrouillés, et leurs dépendances.
function A.gardes()
	local base = { ns.nom }
	if ns.Profils then for _, v in ipairs(ns.Profils.verrous()) do base[#base + 1] = v end end
	return A.avecDependances(base)
end

local function ensemble(liste)
	local s = {}
	for _, n in ipairs(liste) do s[n] = true end
	return s
end

-- Allume exactement `garde` (liste de noms) et coupe tout le reste, d'un seul geste. Renvoie allumés, coupés.
local function exclusif(garde)
	local dans = ensemble(garde)
	local on, off, plus, moins = {}, {}, 0, 0
	for _, e in ipairs(M.entrees()) do
		if dans[e.nom] then
			on[#on + 1] = e.nom
			if not M.actif(e.nom) then plus = plus + 1 end
		else
			off[#off + 1] = e.nom
			if M.actif(e.nom) and not e.moi then moins = moins + 1 end
		end
	end
	M.lot(on, off)
	return plus, moins
end

------------------------------------------------------------------ activer seul, activer avec ses modules
-- Tout couper sauf cet add-on, ses dépendances, les verrouillés et ce gestionnaire.
function A.seul(nom)
	if not M.parNom(nom) then return nil end
	local liste = A.gardes()
	for _, n in ipairs(A.avecDependances({ nom })) do liste[#liste + 1] = n end
	local plus, moins = exclusif(liste)
	ns.Journal.ecrire("info", "journal.actions_seul", nom, plus, moins)
	return plus, moins
end

-- Allume l'add-on, ses dépendances requises et tous ses modules utiles (pas les « non prévus pour Forever »).
function A.activerComplet(nom)
	local e = M.parNom(nom)
	if not e then return nil end
	local liste = { nom }
	for _, m in ipairs(e.modules) do
		if not m.inutile then liste[#liste + 1] = m.nom end
	end
	liste = A.avecDependances(liste)
	local n = M.definir(liste, true)
	ns.Journal.ecrire("info", "journal.actions_complet", nom, n)
	return n
end

-- Éteint l'add-on et ses modules (comme la case).
function A.desactiver(nom)
	if not M.parNom(nom) then return nil end
	return M.basculer(nom, false)
end

-- Maj enfoncée sur une case : on allume avec les modules et les dépendances (réglable).
function A.majClic()
	return ns.Reglages.lire("actions.maj_clic") == true and IsShiftKeyDown() == true
end

------------------------------------------------------------------ essai d'une session
-- Allume l'add-on (et ses dépendances) et le marque : à la prochaine connexion il est éteint, avec ce qu'il avait allumé.
function A.demarrerEssai(nom)
	if not M.parNom(nom) then return false end
	local nouvelles = {}
	local liste = A.avecDependances({ nom })
	for _, n in ipairs(liste) do
		if n ~= nom and not M.actif(n) then nouvelles[#nouvelles + 1] = n end
	end
	M.definir(liste, true)
	R.basculerEssai(nom, true)
	stock().essai_deps[nom] = nouvelles
	ns.Journal.ecrire("info", "journal.actions_essai", nom)
	return true
end

function A.arreterEssai(nom)
	R.basculerEssai(nom, false)
	stock().essai_deps[nom] = nil
	ns.Journal.ecrire("info", "journal.actions_essai_fin", nom)
end

function A.basculerEssai(nom)
	if R.essai(nom) then
		A.arreterEssai(nom)
		return false
	end
	return A.demarrerEssai(nom)
end

-- À la connexion : tout ce qui était en essai est éteint pour le prochain rechargement. Renvoie les noms touchés.
function A.finirEssais()
	local res = {}
	local deps = stock().essai_deps
	for _, e in ipairs(M.entrees()) do
		if R.essai(e.nom) then
			local garde = ns.Profils and ns.Profils.verrou(e.nom)
			if not garde and not e.moi then
				C_AddOns.DisableAddOn(e.nom)
				for _, d in ipairs(deps[e.nom] or {}) do
					local x = M.parNom(d)
					if x and not x.moi and not (ns.Profils and ns.Profils.verrou(d)) then C_AddOns.DisableAddOn(d) end
				end
				res[#res + 1] = e.nom
			end
			R.basculerEssai(e.nom, false)
			deps[e.nom] = nil
			ns.Journal.ecrire("info", "journal.actions_essai_termine", e.nom)
		end
	end
	return res
end

function A.nombreEssais()
	local n = 0
	for _, e in ipairs(M.entrees()) do if R.essai(e.nom) then n = n + 1 end end
	return n
end

------------------------------------------------------------------ mode dépannage
function A.depannageActif() return stock().depannage ~= nil end

-- Tout couper sauf `noms` (et leurs dépendances), les verrouillés et ce gestionnaire ; l'état d'avant est gardé pour le retour.
-- Renvoie allumés, coupés ; ou nil, "deja" si un dépannage est déjà en cours.
function A.depannage(noms)
	local s = stock()
	if s.depannage then return nil, "deja" end
	s.depannage = { etats = M.etats(), date = time() }
	local liste = A.gardes()
	for _, n in ipairs(A.avecDependances(noms or {})) do liste[#liste + 1] = n end
	local plus, moins = exclusif(liste)
	ns.Journal.ecrire("info", "journal.actions_depannage", #(noms or {}), plus, moins)
	return plus, moins
end

-- Remet tout comme avant le dépannage. Renvoie true, allumés, coupés ; ou false s'il n'y en a pas.
function A.retour()
	local s = stock()
	local d = s.depannage
	if not d then return false end
	local on, off, plus, moins = {}, {}, 0, 0
	for nom, voulu in pairs(d.etats) do
		local e = M.parNom(nom)
		if e then
			if voulu then
				on[#on + 1] = nom
				if not M.actif(nom) then plus = plus + 1 end
			else
				off[#off + 1] = nom
				if M.actif(nom) and not e.moi then moins = moins + 1 end
			end
		end
	end
	table.sort(on)
	table.sort(off)
	M.lot(on, off)
	s.depannage = nil
	ns.Journal.ecrire("info", "journal.actions_retour", plus, moins)
	return true, plus, moins
end

------------------------------------------------------------------ charger les add-ons périmés
function A.perimesActif()
	return GetCVar(cfg().cvar_perimes) == cfg().valeur_perimes_charges
end

function A.definirPerimes(oui)
	local c = cfg()
	SetCVar(c.cvar_perimes, oui and c.valeur_perimes_charges or c.valeur_perimes_verifies)
	ns.Journal.ecrire("info", oui and "journal.actions_perimes_oui" or "journal.actions_perimes_non")
	return A.perimesActif()
end

------------------------------------------------------------------ compteur, résumé, profils
function A.compteurs()
	local erreurs = ns.Erreurs and ns.Erreurs.dansLaSession() or 0
	return erreurs, (M.enAttente())
end

function A.appliquerProfil(p)
	local a, touches = ns.Profils.appliquer(p, ns.Reglages.lire("profils.portee"))
	ns.dire(ns.T("profil.applique", ns.Profils.nom(p), #a.plus, #a.moins, touches))
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
	if ns.ProfilsUI then ns.ProfilsUI.surChangement() end
	return a
end

-- Une ligne : nombre d'add-ons, profil, changements en attente, erreurs, essais, dépannage.
function A.resume()
	local total, actifs = 0, 0
	for _, e in ipairs(M.entrees()) do
		total = total + 1
		if M.actif(e.nom) then actifs = actifs + 1 end
	end
	local morceaux = { ns.T("resume.addons", total, actifs) }
	local p = ns.Profils and ns.Profils.actuel()
	if p then morceaux[#morceaux + 1] = ns.T("resume.profil", ns.Profils.nom(p)) end
	local erreurs, attente = A.compteurs()
	if attente > 0 then morceaux[#morceaux + 1] = ns.T("resume.attente", attente) end
	if erreurs > 0 then morceaux[#morceaux + 1] = ns.T("resume.erreurs", erreurs) end
	local essais = A.nombreEssais()
	if essais > 0 then morceaux[#morceaux + 1] = ns.T("resume.essais", essais) end
	if A.depannageActif() then morceaux[#morceaux + 1] = ns.T("resume.depannage") end
	return table.concat(morceaux, cfg().separateur_resume)
end

-- Ouvre la fenêtre sur la fiche de l'add-on, avec son lien prêt à copier (volet « Lien CurseForge »).
function A.montrerLien(nom)
	if not M.parNom(nom) then return end
	ns.Fenetre.ouvrir()
	ns.Vue.selection = nom
	ns.Vue.rafraichirFiche()
	ns.Parchemin.montrerLien()
end
