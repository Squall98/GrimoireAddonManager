-- Profil associé à une situation : en entrant en donjon, raid ou champ de bataille, propose le profil (jamais automatique).
local _, ns = ...
local Sit = {}
ns.Situation = Sit

local S, P = ns.Style, ns.Profils
local function ui() return ns.donnees.reglages.interface.profils.situation end
local function dui() return ns.donnees.reglages.interface end

Sit.deja = {} -- instances pour lesquelles on a déjà proposé (ou refusé) pendant cette session

local function construire()
	if Sit.cadre then return end
	local u, d = ui(), dui()
	local f = S.creerCadre("Frame", u.nom, UIParent)
	Sit.cadre = f
	f:SetFrameStrata(u.strate)
	f:SetClampedToScreen(true)
	f:SetSize(u.largeur, u.hauteur)
	f:SetPoint("TOP", UIParent, "TOP", 0, -u.decalage_haut)
	f:EnableMouse(true)
	S.fond(f, "fenetre")
	Sit.texte = S.texte(f, "normal")
	Sit.texte:SetPoint("TOPLEFT", f, "TOPLEFT", d.marge, -d.marge)
	Sit.texte:SetWidth(u.largeur - 2 * d.marge)
	Sit.texte:SetJustifyH("LEFT")
	Sit.texte:SetJustifyV("TOP")
	S.peindre(function() S.couleurTexte(Sit.texte, "texte") end)
	Sit.oui = S.bouton(f, u.largeur_bouton, d.hauteur_bouton)
	Sit.oui:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge, d.marge)
	Sit.oui:SetScript("OnClick", function() Sit.accepter() end)
	Sit.non = S.bouton(f, u.largeur_bouton, d.hauteur_bouton)
	Sit.non:SetPoint("RIGHT", Sit.oui, "LEFT", -d.ecart, 0)
	Sit.non:SetScript("OnClick", function() Sit.refuser() end)
	f:Hide()
end

function Sit.ouverte() return Sit.cadre ~= nil and Sit.cadre:IsShown() end

-- Montre la proposition pour le profil `p` (situation : groupe, raid, champ).
function Sit.proposer(p, situation)
	construire()
	Sit.profil = p.id
	local a = P.apercu(p)
	Sit.texte:SetText(ns.T("situation.texte", ns.T("situation." .. situation), P.nom(p), #a.plus, #a.moins))
	Sit.oui:Texte(ns.T("situation.oui"))
	Sit.non:Texte(ns.T("situation.non"))
	Sit.cadre:Show()
	ns.Journal.ecrire("info", "journal.situation_proposee", situation, P.nom(p))
end

function Sit.refuser()
	if Sit.cadre then Sit.cadre:Hide() end
end

-- Applique le profil proposé (au personnage qui joue) puis recharge.
function Sit.accepter()
	local p = Sit.profil and P.obtenir(Sit.profil)
	Sit.refuser()
	if not p then return end
	P.appliquer(p, "perso")
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
	ns.Liste.recharger()
end

-- Clé qui désigne « cette instance » (type + identifiant de l'instance).
local function cleInstance(type_)
	local id = select(8, GetInstanceInfo())
	return tostring(type_) .. ":" .. tostring(id or "")
end

-- À appeler à l'entrée dans le monde : vérifie si une proposition est utile.
function Sit.verifier()
	if not ns.Reglages.lire("profils.proposer") then return end
	local dedans, type_ = IsInInstance()
	if not dedans then return end
	local situation = P.situationDe(type_)
	if not situation then return end
	local p = P.profilDeSituation(situation)
	if not p then return end
	local cle = cleInstance(type_)
	if Sit.deja[cle] then return end
	if InCombatLockdown and InCombatLockdown() then
		Sit.enAttente = true
		return
	end
	Sit.deja[cle] = true
	if P.changements(P.apercu(p)) == 0 then return end
	Sit.proposer(p, situation)
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_ENTERING_WORLD")
cadre:RegisterEvent("PLAYER_REGEN_ENABLED")
cadre:SetScript("OnEvent", function(_, evenement)
	if evenement == "PLAYER_REGEN_ENABLED" and not Sit.enAttente then return end
	Sit.enAttente = false
	C_Timer.After(ns.Reglages.lire("profils.delai_proposition"), function()
		ns.Journal.proteger(Sit.verifier)
	end)
end)
