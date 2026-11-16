-- Capture des erreurs Lua : se place devant le gestionnaire d'erreurs du jeu (sans jamais le remplacer), range chaque
-- erreur sous son add-on, compte les répétitions et garde le détail dans le fichier de sauvegarde du compte.
-- Aucun texte, motif ni seuil ici : tout vient de ns.donnees.reglages (erreurs.* et interface.erreurs).
local nom, ns = ...
local E = {}
ns.Erreurs = E

local function cfg() return ns.donnees.reglages.interface.erreurs end
local function lire(chemin) return ns.Reglages.lire("erreurs." .. chemin) end

E.attente = {}     -- erreurs arrivées avant que la sauvegarde soit prête
E.index = {}       -- signature -> entrée
E.session = {}     -- add-on -> nombre d'occurrences depuis la connexion
E.nouvelles = 0    -- erreurs (toutes occurrences) depuis la connexion
E.dernierAvis = nil
E.ecouteurs = {}   -- fonctions rappelées à chaque erreur : f(entrée, nouvelle)

------------------------------------------------------------------ sauvegarde
local function base()
	local compte = ns.Reglages.compte
	if not compte then return nil end
	local b = compte.erreurs_journal
	if not b then
		b = { liste = {}, suivant = 1, sessions = 0 }
		compte.erreurs_journal = b
	end
	return b
end

local function signature(e)
	return table.concat({ tostring(e.addon or ""), tostring(e.fichier or ""), tostring(e.ligne or ""), tostring(e.message) }, "\1")
end

function E.reindexer()
	E.index = {}
	local b = base()
	if not b then return end
	for _, e in ipairs(b.liste) do E.index[signature(e)] = e end
end

-- Nom sous lequel on compte un add-on (les erreurs sans add-on identifié vont sous le signe « inconnu »).
function E.cle(addon) return addon or cfg().inconnu end

function E.nomAffiche(addon)
	if addon then return addon end
	return ns.T("erreurs.inconnu")
end

------------------------------------------------------------------ lecture
-- Les erreurs gardées, de la plus récente à la plus ancienne ; `addon` limite à un add-on (E.cle()).
function E.liste(addon)
	local b = base()
	local res = {}
	if not b then return res end
	for _, e in ipairs(b.liste) do
		if addon == nil or E.cle(e.addon) == addon then res[#res + 1] = e end
	end
	table.sort(res, function(a, c)
		if a.derniere ~= c.derniere then return a.derniere > c.derniere end
		return a.id > c.id
	end)
	return res
end

-- Total des occurrences gardées pour un add-on (ou pour tous si nil).
function E.nombre(addon)
	local b, total = base(), 0
	if not b then return 0 end
	for _, e in ipairs(b.liste) do
		if addon == nil or E.cle(e.addon) == addon then total = total + (e.n or 1) end
	end
	return total
end

function E.nombreDifferentes(addon)
	local b, total = base(), 0
	if not b then return 0 end
	for _, e in ipairs(b.liste) do
		if addon == nil or E.cle(e.addon) == addon then total = total + 1 end
	end
	return total
end

-- Occurrences vues depuis la connexion pour un add-on (ou pour tous).
function E.dansLaSession(addon)
	if addon == nil then return E.nouvelles end
	return E.session[addon] or 0
end

-- Liste triée (plus d'occurrences d'abord) des add-ons qui ont des erreurs : { { addon = clé, n = occurrences, differentes = n } }.
function E.addons()
	local b, par = base(), {}
	local res = {}
	if not b then return res end
	for _, e in ipairs(b.liste) do
		local cle = E.cle(e.addon)
		local a = par[cle]
		if not a then
			a = { addon = cle, n = 0, differentes = 0 }
			par[cle] = a
			res[#res + 1] = a
		end
		a.n = a.n + (e.n or 1)
		a.differentes = a.differentes + 1
	end
	table.sort(res, function(a, c)
		if a.n ~= c.n then return a.n > c.n end
		return a.addon < c.addon
	end)
	return res
end

function E.parId(id)
	local b = base()
	if not b then return nil end
	for _, e in ipairs(b.liste) do if e.id == id then return e end end
end

------------------------------------------------------------------ copie : texte complet d'une erreur
local function ouiNon(v) return ns.T(v and "erreurs.oui" or "erreurs.non") end

local function ligne(champ, valeur)
	return ns.T("erreurs.champ.ligne_texte", ns.T("erreurs.champ." .. champ), tostring(valeur))
end

local function dateComplete(t) return date(ns.T("erreurs.format_date"), t) end

function E.texte(e)
	local lignes = {
		ligne("addon", E.nomAffiche(e.addon)),
	}
	if e.version then lignes[#lignes + 1] = ligne("version", e.version) end
	lignes[#lignes + 1] = ligne("message", e.message)
	if e.fichier then lignes[#lignes + 1] = ligne("fichier", e.fichier) end
	if e.ligne then lignes[#lignes + 1] = ligne("ligne", e.ligne) end
	lignes[#lignes + 1] = ligne("fois", e.n or 1)
	lignes[#lignes + 1] = ligne("premiere", dateComplete(e.premiere))
	lignes[#lignes + 1] = ligne("derniere", dateComplete(e.derniere))
	lignes[#lignes + 1] = ligne("combat", ouiNon(e.combat))
	lignes[#lignes + 1] = ligne("jeu", ns.T("erreurs.jeu_valeur", e.client or "?", e.gestionnaire or "?"))
	lignes[#lignes + 1] = ligne("langue", e.langue or "?")
	if e.pile and e.pile ~= "" then
		lignes[#lignes + 1] = ns.T("erreurs.champ.ligne_texte", ns.T("erreurs.champ.pile"), "")
		lignes[#lignes + 1] = e.pile
	end
	return table.concat(lignes, "\n")
end

function E.texteTout(addon)
	local morceaux = {}
	for _, e in ipairs(E.liste(addon)) do morceaux[#morceaux + 1] = E.texte(e) end
	return table.concat(morceaux, "\n\n")
end

------------------------------------------------------------------ capture
function E.analyser(message)
	local c = cfg()
	local addon = string.match(message, c.motif_addon)
	local fichier, ligneNum = string.match(message, c.motif_fichier)
	return addon, fichier, tonumber(ligneNum)
end

-- Premier add-on cité dans la pile d'appels, en sautant le nôtre (qui apparaît parce que la capture est dans la pile).
local function addonDeLaPile(pile)
	for trouve in string.gmatch(pile, cfg().motif_addon) do
		if trouve ~= nom then return trouve end
	end
end

local function pileActuelle()
	if not debugstack then return "" end
	local ok, pile = pcall(debugstack)
	return ok and type(pile) == "string" and pile or ""
end

local function metadonnee(addon, champ)
	if not addon or not C_AddOns or not C_AddOns.GetAddOnMetadata then return nil end
	local ok, v = pcall(C_AddOns.GetAddOnMetadata, addon, champ)
	return ok and v or nil
end

local function enCombat()
	return InCombatLockdown and InCombatLockdown() and true or false
end

local function rangerNouvelle(e)
	local b = base()
	E.index[signature(e)] = e
	if not b then
		E.attente[#E.attente + 1] = e
		return
	end
	e.id = b.suivant
	b.suivant = b.suivant + 1
	b.liste[#b.liste + 1] = e
	local max = lire("max")
	while #b.liste > max do
		local plus, place = nil, nil
		for i, x in ipairs(b.liste) do
			if x ~= e and (not plus or x.derniere < plus.derniere) then plus, place = x, i end
		end
		if not place then break end
		table.remove(b.liste, place)
		E.index[signature(plus)] = nil
	end
end

-- Range une erreur reçue du jeu. Renvoie l'entrée et vrai si elle est nouvelle (pas encore vue).
function E.noter(message)
	if not lire("actif") then return nil end
	local texte = string.sub(tostring(message), 1, lire("taille_message"))
	local addon, fichier, ligneNum = E.analyser(texte)
	local pile
	if not addon then -- le message ne dit pas d'où ça vient : la pile d'appels le dit souvent
		pile = pileActuelle()
		addon = addonDeLaPile(pile)
	end
	local maintenant = time()
	local sig = table.concat({ tostring(addon or ""), tostring(fichier or ""), tostring(ligneNum or ""), texte }, "")
	local cle = E.cle(addon)
	E.nouvelles = E.nouvelles + 1
	E.session[cle] = (E.session[cle] or 0) + 1
	local e = E.index[sig]
	local nouvelle = not e
	if e then
		e.n = (e.n or 1) + 1
		e.derniere = maintenant
	else
		e = {
			addon = addon, version = metadonnee(addon, "Version"), fichier = fichier, ligne = ligneNum, message = texte,
			pile = string.sub(pile or pileActuelle(), 1, lire("taille_pile")), n = 1, premiere = maintenant,
			derniere = maintenant, combat = enCombat(), session = (base() or {}).sessions,
			client = select(4, GetBuildInfo()), langue = GetLocale(), gestionnaire = metadonnee(nom, "Version"),
		}
		rangerNouvelle(e)
	end
	for _, f in ipairs(E.ecouteurs) do pcall(f, e, nouvelle) end
	if nouvelle then E.annoncer(e) end
	return e, nouvelle
end

------------------------------------------------------------------ annonce (chat, fenêtre, son)
local function court(texte)
	local max = cfg().message_court
	texte = string.gsub(string.gsub(texte, "[\r\n]+", " "), "|", "||")
	if string.len(texte) > max then texte = string.sub(texte, 1, max) .. "..." end
	return texte
end
E.court = court

function E.annoncer(e)
	local mode = lire("annonce")
	local maintenant = GetTime()
	if E.dernierAvis and maintenant - E.dernierAvis < lire("annonce_delai") then return end
	if mode == "rien" then return end
	E.dernierAvis = maintenant
	if lire("son") and PlaySound then
		local s = cfg().son
		pcall(PlaySound, (SOUNDKIT and SOUNDKIT[s.kit]) or s.id)
	end
	if mode == "fenetre" and ns.ErreursFenetre and not enCombat() then
		ns.ErreursFenetre.ouvrir(e)
		return
	end
	local principale = ns.Commandes.principale() or ns.Reglages.technique().cle_commande
	ns.dire(ns.T("erreurs.annonce", E.nomAffiche(e.addon), court(e.message), principale))
end

------------------------------------------------------------------ effacer
-- Efface toutes les erreurs (ou celles d'un add-on, clé de E.cle). Renvoie le nombre d'erreurs différentes retirées.
function E.effacer(addon)
	local b = base()
	if not b then return 0 end
	local gardees, retirees = {}, 0
	for _, e in ipairs(b.liste) do
		if addon == nil or E.cle(e.addon) == addon then retirees = retirees + 1 else gardees[#gardees + 1] = e end
	end
	b.liste = gardees
	E.reindexer()
	if addon == nil then E.session, E.nouvelles = {}, 0 else E.nouvelles = E.nouvelles - (E.session[addon] or 0) E.session[addon] = nil end
	for _, f in ipairs(E.ecouteurs) do pcall(f, nil, false) end
	return retirees
end

------------------------------------------------------------------ gestionnaire d'erreurs du jeu
function E.gestionnaire(message, ...)
	if not E.dedans then
		E.dedans = true
		pcall(E.noter, message)
		E.dedans = false
	end
	local suivant = E.ancien
	if suivant then return suivant(message, ...) end
end

function E.installer()
	if not geterrorhandler or not seterrorhandler then return false end
	local courant = geterrorhandler()
	if courant == E.gestionnaire then return false end
	E.ancien = courant
	seterrorhandler(E.gestionnaire)
	return true
end

-- Fenêtre d'erreur du jeu : cachée (réglage scriptErrors du jeu) tant que l'option est active, rendue à l'arrêt.
function E.reglerFenetreJeu()
	local c, b = cfg(), base()
	if not b or not GetCVar or not SetCVar then return end
	local actuel = GetCVar(c.cvar_erreurs)
	if lire("masquer_fenetre_jeu") then
		if actuel == c.oui then
			b.cvar_avant = actuel
			SetCVar(c.cvar_erreurs, c.non)
		end
	elseif b.cvar_avant then
		SetCVar(c.cvar_erreurs, b.cvar_avant)
		b.cvar_avant = nil
	end
end

-- Appelé à la connexion : sauvegarde prête, erreurs en attente rangées, réglage de la fenêtre du jeu.
function E.demarrer()
	local b = base()
	if not b then return end
	b.sessions = (b.sessions or 0) + 1
	E.reindexer()
	local attente = E.attente
	E.attente = {}
	for _, e in ipairs(attente) do
		e.session = b.sessions
		local connue = E.index[signature(e)]
		if connue then
			connue.n = (connue.n or 1) + (e.n or 1)
			connue.derniere = math.max(connue.derniere, e.derniere)
		else
			rangerNouvelle(e)
		end
	end
	E.reglerFenetreJeu()
end

E.installer()

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function()
	ns.Journal.proteger(E.demarrer)
	if ns.Options and ns.Options.definir and not E.optionsBranchees then
		E.optionsBranchees = true
		local definir = ns.Options.definir
		ns.Options.definir = function(chemin, ...)
			local ok = definir(chemin, ...)
			if chemin == "erreurs.masquer_fenetre_jeu" then ns.Journal.proteger(E.reglerFenetreJeu) end
			return ok
		end
	end
end)
