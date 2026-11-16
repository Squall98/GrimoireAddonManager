-- Visite guidée : quelques bulles qui montrent chaque partie de la fenêtre (étapes dans reglages.aide.visite, textes
-- visite.<étape>.titre / .texte). Lancée toute seule au premier lancement, puis à la demande (/maa visite, options, menu).
local _, ns = ...
local V = {}
ns.Visite = V

local S = ns.Style
local function ui() return ns.donnees.reglages.interface.visite end
local function etapes() return ns.donnees.reglages.aide.visite end

V.actif = false
V.etape = 0

function V.estActive() return V.actif end
function V.nombre() return #etapes() end

------------------------------------------------------------------ construction
local function construire()
	if V.bulle then return end
	local d = ui()
	local f = S.creerCadre("Frame", d.nom_bulle, UIParent)
	V.bulle = f
	f:SetSize(d.largeur, d.hauteur)
	f:SetFrameStrata(d.strate)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	S.fond(f, "fenetre")
	f:Hide()

	V.titre = S.texte(f, "titre")
	V.titre:SetPoint("TOPLEFT", f, "TOPLEFT", d.marge, -d.marge)
	V.titre:SetPoint("TOPRIGHT", f, "TOPRIGHT", -d.marge, -d.marge)
	V.titre:SetJustifyH("LEFT")
	V.texte = S.texte(f, "normal")
	V.texte:SetPoint("TOPLEFT", V.titre, "BOTTOMLEFT", 0, -d.ecart)
	V.texte:SetPoint("TOPRIGHT", V.titre, "BOTTOMRIGHT", 0, -d.ecart)
	V.texte:SetJustifyH("LEFT")
	V.texte:SetJustifyV("TOP")
	V.texte:SetWordWrap(true)
	V.compteur = S.texte(f, "petit")
	V.compteur:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", d.marge, d.marge + 4)
	S.peindre(function()
		S.couleurTexte(V.titre, "dore_clair")
		S.couleurTexte(V.texte, "texte")
		S.couleurTexte(V.compteur, "texte_doux")
	end)

	V.boutonSuivant = S.bouton(f, d.largeur_bouton, d.hauteur_bouton)
	V.boutonSuivant:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge, d.marge)
	V.boutonSuivant:SetScript("OnClick", function() V.suivant() end)
	V.boutonPrecedent = S.bouton(f, d.largeur_bouton, d.hauteur_bouton)
	V.boutonPrecedent:SetPoint("RIGHT", V.boutonSuivant, "LEFT", -d.ecart, 0)
	V.boutonPrecedent:SetScript("OnClick", function() V.precedent() end)
	V.boutonPasser = S.bouton(f, d.largeur_bouton, d.hauteur_bouton)
	V.boutonPasser:SetPoint("RIGHT", V.boutonPrecedent, "LEFT", -d.ecart, 0)
	V.boutonPasser:SetScript("OnClick", function() V.terminer(false) end)

	-- le cadre doré autour de la partie montrée : quatre fines bandes
	local c = CreateFrame("Frame", nil, UIParent)
	V.cadre = c
	c:SetFrameStrata(d.strate)
	c:Hide()
	V.bandes = {}
	for i = 1, 4 do
		local t = c:CreateTexture(nil, "OVERLAY")
		S.aplat(t, "dore_clair", 1)
		V.bandes[i] = t
	end
end

-- Place les quatre bandes autour de `cible`.
local function entourer(cible)
	local d = ui()
	local e, m = d.epaisseur_cadre, d.marge_cadre
	V.cadre:ClearAllPoints()
	V.cadre:SetPoint("TOPLEFT", cible, "TOPLEFT", -m, m)
	V.cadre:SetPoint("BOTTOMRIGHT", cible, "BOTTOMRIGHT", m, -m)
	local b = V.bandes
	b[1]:ClearAllPoints() b[1]:SetPoint("TOPLEFT", V.cadre, "TOPLEFT", 0, 0) b[1]:SetPoint("TOPRIGHT", V.cadre, "TOPRIGHT", 0, 0) b[1]:SetHeight(e)
	b[2]:ClearAllPoints() b[2]:SetPoint("BOTTOMLEFT", V.cadre, "BOTTOMLEFT", 0, 0) b[2]:SetPoint("BOTTOMRIGHT", V.cadre, "BOTTOMRIGHT", 0, 0) b[2]:SetHeight(e)
	b[3]:ClearAllPoints() b[3]:SetPoint("TOPLEFT", V.cadre, "TOPLEFT", 0, 0) b[3]:SetPoint("BOTTOMLEFT", V.cadre, "BOTTOMLEFT", 0, 0) b[3]:SetWidth(e)
	b[4]:ClearAllPoints() b[4]:SetPoint("TOPRIGHT", V.cadre, "TOPRIGHT", 0, 0) b[4]:SetPoint("BOTTOMRIGHT", V.cadre, "BOTTOMRIGHT", 0, 0) b[4]:SetWidth(e)
end

------------------------------------------------------------------ déroulement
function V.afficher()
	construire()
	local liste = etapes()
	local e = liste[V.etape]
	if not e then return end
	local cible = ns.Fenetre[e.cible]
	local principale = ns.Aide.principale()
	V.titre:SetText(ns.T("visite." .. e.id .. ".titre"))
	V.texte:SetText(ns.T("visite." .. e.id .. ".texte", principale, ns.T("sous.antiseche.nom")))
	V.compteur:SetText(ns.T("visite.compteur", V.etape, #liste))
	V.boutonPasser:Texte(ns.T("visite.passer"))
	V.boutonPrecedent:Texte(ns.T("visite.precedent"))
	V.boutonPrecedent:Activer(V.etape > 1)
	V.boutonSuivant:Texte(ns.T(V.etape < #liste and "visite.suivant" or "visite.fin"))
	V.bulle:ClearAllPoints()
	if cible then
		entourer(cible)
		V.cadre:Show()
		V.bulle:SetPoint(e.point, cible, e.rel, e.x, e.y)
	else
		V.cadre:Hide()
		V.bulle:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	V.bulle:Show()
end

-- Lance la visite (la fenêtre s'ouvre en version complète le temps de la visite).
function V.demarrer()
	if V.actif then return end
	construire()
	if ns.AideFenetre then ns.AideFenetre.fermer() end
	local F = ns.Fenetre
	V.modeAvant = F.mode()
	if V.modeAvant == "mini" then F.definirMini(false) end
	F.ouvrir()
	if not V.accroche then
		V.accroche = true
		F.cadre:HookScript("OnHide", function() if V.actif then V.terminer(false) end end)
	end
	V.actif = true
	V.etape = 1
	ns.Reglages.ecrire("aide.visite_vue", true)
	ns.Journal.ecrire("info", "journal.visite_debut")
	V.afficher()
end

function V.suivant()
	if not V.actif then return end
	if V.etape >= #etapes() then return V.terminer(true) end
	V.etape = V.etape + 1
	V.afficher()
end

function V.precedent()
	if not V.actif or V.etape <= 1 then return end
	V.etape = V.etape - 1
	V.afficher()
end

-- Ferme la visite ; `complete` = on est allé jusqu'au bout (on dit alors comment la revoir).
function V.terminer(complete)
	if not V.actif then return end
	V.actif = false
	V.bulle:Hide()
	V.cadre:Hide()
	if V.modeAvant == "mini" and ns.Fenetre.mode() ~= "mini" then ns.Fenetre.definirMini(true) end
	V.modeAvant = nil
	ns.Journal.ecrire("info", complete and "journal.visite_fin" or "journal.visite_passee", V.etape)
	if complete then
		local principale = ns.Aide.principale()
		ns.dire(ns.T("visite.fini", principale, ns.T("sous.visite.nom"), principale, ns.T("sous.antiseche.nom")))
	end
end

------------------------------------------------------------------ premier lancement
-- Lancée seule quelques secondes après la connexion, une fois, si le réglage le permet ; jamais en plein combat.
function V.tentative()
	if V.actif or not ns.Reglages.lire("aide.visite_auto") or ns.Reglages.lire("aide.visite_vue") then return end
	if InCombatLockdown() then
		V.attendCombat = true
		V.ecoute:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	V.demarrer()
end

V.ecoute = CreateFrame("Frame")
V.ecoute:RegisterEvent("PLAYER_LOGIN")
V.ecoute:SetScript("OnEvent", function(self, evenement)
	if evenement == "PLAYER_LOGIN" then
		C_Timer.After(ns.donnees.reglages.aide.delai_visite, function() ns.Journal.proteger(V.tentative) end)
	elseif evenement == "PLAYER_REGEN_ENABLED" and V.attendCombat then
		V.attendCombat = false
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		ns.Journal.proteger(V.tentative)
	end
end)
