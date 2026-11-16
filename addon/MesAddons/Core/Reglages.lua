-- Réglages : valeurs de départ (Donnees\Reglages.lua) + choix sauvegardés (compte et personnage).
local _, ns = ...
local R = {}
ns.Reglages = R

local function copie(v)
	if type(v) ~= "table" then return v end
	local c = {}
	for k, x in pairs(v) do c[k] = copie(x) end
	return c
end
R.copie = copie

-- Ajoute à `dest` ce qui manque (sans toucher aux choix déjà faits).
local function completer(dest, modele)
	for k, v in pairs(modele) do
		if dest[k] == nil then
			dest[k] = copie(v)
		elseif type(v) == "table" and type(dest[k]) == "table" and not v[1] then
			completer(dest[k], v)
		end
	end
end

function R.technique() return ns.donnees.reglages.technique end
function R.defauts() return ns.donnees.reglages.defauts end

-- Appelé au chargement de l'add-on, quand le jeu a rempli les variables sauvegardées.
function R.init()
	local t = R.technique()
	_G[t.variable_compte] = _G[t.variable_compte] or {}
	_G[t.variable_perso] = _G[t.variable_perso] or {}
	R.compte = _G[t.variable_compte]
	R.perso = _G[t.variable_perso]
	R.compte.reglages = R.compte.reglages or {}
	completer(R.compte.reglages, R.defauts())
	R.compte.schema = t.schema
	R.migrer()
end

-- Changements de valeur de départ à reporter UNE fois sur les choix sauvegardés (technique.migrations) :
-- seulement si la valeur gardée est encore l'ancienne valeur de départ (« de »).
function R.migrer()
	R.compte.migrations = R.compte.migrations or {}
	for _, m in ipairs(R.technique().migrations or {}) do
		if not R.compte.migrations[m.id] then
			R.compte.migrations[m.id] = true
			if R.lire(m.chemin) == m.de then R.ecrire(m.chemin, m.vers) end
		end
	end
end

local function parcourir(racine, chemin)
	local noeud = racine
	for cle in string.gmatch(chemin, "[^%.]+") do
		if type(noeud) ~= "table" then return nil end
		noeud = noeud[cle]
	end
	return noeud
end

function R.lire(chemin)
	local base = R.compte and R.compte.reglages or R.defauts()
	local v = parcourir(base, chemin)
	if v == nil then v = parcourir(R.defauts(), chemin) end
	return v
end

-- Renvoie true, ou false + le type attendu si la valeur n'a pas le type du réglage de départ.
function R.ecrire(chemin, valeur)
	local modele = parcourir(R.defauts(), chemin)
	if modele == nil or type(modele) ~= type(valeur) then
		return false, type(modele)
	end
	local morceaux = {}
	for cle in string.gmatch(chemin, "[^%.]+") do morceaux[#morceaux + 1] = cle end
	local parent = R.compte.reglages
	for i = 1, #morceaux - 1 do parent = parent[morceaux[i]] end
	parent[morceaux[#morceaux]] = copie(valeur)
	return true
end

function R.reinitialiser(chemin)
	local modele = parcourir(R.defauts(), chemin)
	if modele == nil then return false end
	return R.ecrire(chemin, copie(modele))
end
