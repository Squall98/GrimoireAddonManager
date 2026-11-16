-- Façons d'ouvrir la fenêtre : bouton de la minicarte, bouton « AddOns » du menu Échap, commandes de réglage de la fenêtre.
local _, ns = ...
local A = {}
ns.Acces = A

local S = ns.Style
local function ui() return ns.donnees.reglages.interface end

A.boutonsMenu = {} -- boutons du menu Échap déjà accrochés

------------------------------------------------------------------ bouton de la minicarte
function A.placer()
	local b = A.bouton
	if not b then return end
	local angle = math.rad(ns.Reglages.lire("acces.angle_minicarte"))
	local rayon = Minimap:GetWidth() / 2 + ui().decalage_minicarte
	b:ClearAllPoints()
	b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * rayon, math.sin(angle) * rayon)
end

function A.majVisibilite()
	if not A.bouton then return end
	if ns.Reglages.lire("acces.bouton_minicarte") then A.bouton:Show() else A.bouton:Hide() end
end

function A.creerBouton()
	if A.bouton or not Minimap then return end
	local d = ui()
	local t = d.textures
	local b = CreateFrame("Button", d.nom_bouton, Minimap)
	A.bouton = b
	b:SetSize(d.taille_bouton_minicarte, d.taille_bouton_minicarte)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	local icone = b:CreateTexture(nil, "BACKGROUND")
	icone:SetSize(20, 20)
	icone:SetPoint("TOPLEFT", b, "TOPLEFT", 7, -6)
	icone:SetTexture(t.minicarte_icone)
	local bord = b:CreateTexture(nil, "OVERLAY")
	bord:SetSize(53, 53)
	bord:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
	bord:SetTexture(t.minicarte_bord)
	b:SetScript("OnClick", function(_, bouton)
		if bouton == "RightButton" then return ns.Rapide.clicDroit() end
		ns.Fenetre.basculer()
	end)
	b.compteur = S.texte(b, "petit", "OVERLAY")
	b.compteur:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", d.decalage_compteur[1], d.decalage_compteur[2])
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(ns.T("nom"))
		GameTooltip:AddLine(ns.T("acces.minicarte_aide"), 1, 1, 1)
		GameTooltip:AddLine(ns.T("acces.minicarte_aide_droit"), 1, 1, 1)
		local erreurs, attente = ns.Actions.compteurs()
		if erreurs > 0 then GameTooltip:AddLine(ns.T("acces.compteur_erreurs", erreurs), 1, 0.4, 0.35) end
		if attente > 0 then GameTooltip:AddLine(ns.T("acces.compteur_attente", attente), 1, 0.82, 0) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local cx, cy = Minimap:GetCenter()
			local sx, sy = GetCursorPosition()
			local echelle = Minimap:GetEffectiveScale()
			local angle = math.deg(math.atan2(sy / echelle - cy, sx / echelle - cx))
			if angle < 0 then angle = angle + 360 end
			ns.Reglages.ecrire("acces.angle_minicarte", angle)
			A.placer()
		end)
	end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	A.placer()
	A.majVisibilite()
	A.majCompteur()
	C_Timer.NewTicker(ns.donnees.reglages.actions.compteur_delai, A.majCompteur)
end

-- Compteur sur le bouton : erreurs (rouge) puis changements en attente (doré), rien quand tout est calme.
function A.majCompteur()
	local b = A.bouton
	if not b or not b.compteur then return end
	local texte = ""
	if ns.Reglages.lire("acces.compteur_minicarte") then
		local erreurs, attente = ns.Actions.compteurs()
		local morceaux = {}
		if erreurs > 0 then morceaux[#morceaux + 1] = ns.T("acces.compteur_rouge", erreurs) end
		if attente > 0 then morceaux[#morceaux + 1] = ns.T("acces.compteur_dore", attente) end
		texte = table.concat(morceaux, ui().separateur_compteur)
	end
	b.compteur:SetText(texte)
end

------------------------------------------------------------------ bouton « AddOns » du menu Échap
-- Le menu est fait de boutons sans nom : on retrouve celui dont le texte est « AddOns » et on lui ajoute notre ouverture.
function A.surClicMenu()
	if not ns.Reglages.lire("acces.bouton_menu_echap") then return end
	C_Timer.After(0, function()
		if AddonList and AddonList:IsShown() then pcall(AddonList.Hide, AddonList) end
		ns.Fenetre.ouvrir()
	end)
end

function A.chercherBoutonMenu()
	if not GameMenuFrame then return end
	for _, enfant in ipairs({ GameMenuFrame:GetChildren() }) do
		if not A.boutonsMenu[enfant] and type(enfant.GetText) == "function" then
			local ok, texte = pcall(enfant.GetText, enfant)
			if ok and texte == ADDONS then
				A.boutonsMenu[enfant] = true
				enfant:HookScript("OnClick", A.surClicMenu)
			end
		end
	end
end

function A.accrocherMenu()
	if A.menuAccroche or not GameMenuFrame then return end
	A.menuAccroche = true
	GameMenuFrame:HookScript("OnShow", A.chercherBoutonMenu)
	A.chercherBoutonMenu()
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function()
	ns.Journal.proteger(A.creerBouton)
	ns.Journal.proteger(A.accrocherMenu)
end)

------------------------------------------------------------------ commandes : thème, taille, police, mini
-- Trouve l'identifiant dont le nom (dans une langue quelconque) ou l'identifiant est le mot tapé.
local function trouver(mot, prefixe, ids)
	mot = string.lower(mot)
	for _, id in ipairs(ids) do
		if mot == string.lower(id) then return id end
		for _, code in ipairs(ns.Langue.disponibles()) do
			local t = ns.Langue.texte(code, prefixe .. "." .. id)
			if t and string.lower(t) == mot then return id end
		end
	end
end

local function noms(prefixe, ids)
	local liste = {}
	for _, id in ipairs(ids) do liste[#liste + 1] = ns.T(prefixe .. "." .. id) end
	return table.concat(liste, ", ")
end

-- Lit ou change un réglage à choix (thème, taille, police).
local function choix(chemin, prefixe, ids, reste, apres)
	local titre = ns.T("choix." .. prefixe)
	if reste == "" then
		return ns.dire(ns.T("choix.actuel", titre, ns.T(prefixe .. "." .. ns.Reglages.lire(chemin)), noms(prefixe, ids)))
	end
	local id = trouver(reste, prefixe, ids)
	if not id then return ns.dire(ns.T("choix.invalide", reste, noms(prefixe, ids))) end
	ns.Reglages.ecrire(chemin, id)
	ns.Journal.ecrire("info", "journal.fenetre_choix", chemin, id)
	ns.dire(ns.T("choix.change", titre, ns.T(prefixe .. "." .. id)))
	if apres then apres() end
end

local sous = ns.Commandes.sous

function sous.theme(reste)
	choix("fenetre.theme", "theme", ui().themes_ordre, reste, function() S.repeindre() end)
end

function sous.taille(reste)
	local ids = {}
	for id in pairs(ui().tailles) do ids[#ids + 1] = id end
	table.sort(ids, function(a, b) return ui().tailles[a].l > ui().tailles[b].l end)
	choix("fenetre.taille", "taille", ids, reste, function() ns.Fenetre.reinitialiserTaille() end)
end

function sous.police(reste)
	choix("fenetre.police", "police", ui().polices_ordre, reste, function() S.repeindre() end)
end

function sous.mini()
	local mini = ns.Fenetre.mode() ~= "mini"
	ns.Fenetre.definirMini(mini)
	ns.dire(ns.T(mini and "mini.active" or "mini.desactive"))
end
