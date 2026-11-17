-- Journal de débogage interne : lignes (clé de texte + arguments) gardées dans la sauvegarde du compte.
local _, ns = ...
local J = {}
ns.Journal = J

local attente = {} -- lignes écrites avant que la sauvegarde soit prête

local function niveaux() return ns.donnees.reglages.journal_niveaux end

local function ranger(ligne)
	local compte = ns.Reglages.compte
	if not compte then attente[#attente + 1] = ligne return end
	local j = compte.journal
	if not j then j = {} compte.journal = j end
	local dernier = j[#j]
	if ns.Reglages.lire("journal.dedoublonner") and dernier and dernier.n == ligne.n and dernier.k == ligne.k
		and dernier.a1 == ligne.a1 and dernier.a2 == ligne.a2 and dernier.a3 == ligne.a3 then
		dernier.x = (dernier.x or 1) + 1
		dernier.t = ligne.t
		return
	end
	j[#j + 1] = ligne
	local max = ns.Reglages.lire("journal.taille_max")
	while #j > max do table.remove(j, 1) end
end

function J.vider_attente()
	local l = attente
	attente = {}
	for _, ligne in ipairs(l) do ranger(ligne) end
end

-- niveau : "debug" | "info" | "avertissement" | "erreur" ; cle : clé de texte ; jusqu'à 3 arguments
function J.ecrire(niveau, cle, a1, a2, a3)
	if not ns.Reglages.lire("journal.actif") then return end
	local n = niveaux()
	if (n[niveau] or 0) < (n[ns.Reglages.lire("journal.niveau_min")] or 0) then return end
	ranger({
		t = time(), n = niveau, k = cle,
		a1 = a1 ~= nil and tostring(a1) or nil,
		a2 = a2 ~= nil and tostring(a2) or nil,
		a3 = a3 ~= nil and tostring(a3) or nil,
	})
end

function J.lignes()
	return ns.Reglages.compte and ns.Reglages.compte.journal or {}
end

function J.formater(ligne)
	local texte = ns.T(ligne.k, ligne.a1, ligne.a2, ligne.a3)
	if ligne.x and ligne.x > 1 then texte = texte .. " (x" .. ligne.x .. ")" end
	return ns.T("journal.ligne", date("%d/%m %H:%M:%S", ligne.t), ns.T("niveau." .. ligne.n), texte)
end

function J.effacer()
	if ns.Reglages.compte then ns.Reglages.compte.journal = {} end
end

-- Exécute fn sans jamais casser l'add-on : l'erreur va au journal.
function J.proteger(fn, ...)
	local args = { ... }
	local ok, err = xpcall(function() return fn(unpack(args)) end, function(m) return m end)
	if not ok then
		J.ecrire("erreur", "journal.erreur", err)
		-- une erreur de Mes Add-ons ne reste jamais silencieuse : elle est dite dans le chat
		if ns.dire then pcall(ns.dire, ns.T("journal.erreur", tostring(err))) end
	end
	return ok, err
end

local function est_de_nous(message)
	message = tostring(message)
	return string.find(message, "AddOns/" .. ns.nom .. "/", 1, true) or string.find(message, "AddOns\\" .. ns.nom .. "\\", 1, true)
end

-- Se place devant le gestionnaire d'erreurs du jeu, sans le remplacer : il reçoit toujours l'erreur ensuite.
function J.surveiller_erreurs()
	if J.surveille or not ns.Reglages.lire("journal.capturer_erreurs") then return end
	J.surveille = true
	local ancien = geterrorhandler()
	seterrorhandler(function(message, ...)
		if est_de_nous(message) then
			J.ecrire("erreur", "journal.erreur", message)
		end
		if ancien then return ancien(message, ...) end
	end)
end
