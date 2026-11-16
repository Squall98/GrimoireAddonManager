-- Mémorise les personnages qui se connectent (le jeu ne donne pas leur liste) : utile pour les profils par personnage.
local _, ns = ...
local P = {}
ns.Personnages = P

function P.memoriser()
	if not ns.Reglages.lire("personnages.memoriser") then return end
	local guid = UnitGUID("player")
	if not guid then return end
	local compte = ns.Reglages.compte
	compte.personnages = compte.personnages or {}
	local _, classe = UnitClass("player")
	local nom = UnitName("player")
	compte.personnages[guid] = {
		nom = nom,
		royaume = GetRealmName(),
		faction = UnitFactionGroup("player"),
		classe = classe,
		vu = time(),
	}
	ns.guid = guid
	ns.Journal.ecrire("info", "journal.perso", nom, guid)
end

function P.liste()
	return ns.Reglages.compte and ns.Reglages.compte.personnages or {}
end
