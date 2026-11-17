-- Liste déroulante : un bouton qui ouvre, juste dessous, une petite liste de choix (un coché = le choix actuel).
-- D.creer(parent, largeur, hauteur, fournir) ; fournir() renvoie { { id, texte, coche, action, separe }, ... }.
local _, ns = ...
local D = {}
ns.Deroulant = D

local S = ns.Style
local function cfg() return ns.donnees.reglages.interface.deroulant end

D.lignes = {}

local function construire()
	if D.cadre then return end
	local c = cfg()
	local f = S.creerCadre("Frame", nil, UIParent)
	D.cadre = f
	S.fond(f, "volet")
	f:SetFrameStrata(c.strate)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:Hide()
	-- un clic n'importe où ailleurs referme la liste
	local voile = CreateFrame("Button", nil, UIParent)
	D.voile = voile
	voile:SetAllPoints(UIParent)
	voile:SetFrameStrata(c.strate)
	voile:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	voile:SetScript("OnClick", function() D.fermer() end)
	voile:Hide()
	f:SetScript("OnHide", function() voile:Hide() D.bouton = nil end)
end

local function ligne(i)
	local c = cfg()
	local l = D.lignes[i]
	if l then return l end
	l = CreateFrame("Button", nil, D.cadre)
	l:SetHeight(c.hauteur_ligne)
	l.fond = l:CreateTexture(nil, "BACKGROUND")
	l.fond:SetAllPoints(l)
	l.coche = l:CreateTexture(nil, "ARTWORK")
	l.coche:SetSize(c.taille_coche, c.taille_coche)
	l.coche:SetPoint("LEFT", l, "LEFT", 2, 0)
	l.coche:SetTexture(ns.donnees.reglages.interface.textures.case_coche)
	l.texte = S.texte(l, "normal")
	l.texte:SetPoint("LEFT", l.coche, "RIGHT", 4, 0)
	l.texte:SetPoint("RIGHT", l, "RIGHT", -4, 0)
	l.texte:SetJustifyH("LEFT")
	l.filet = l:CreateTexture(nil, "ARTWORK")
	l.filet:SetPoint("TOPLEFT", l, "TOPLEFT", 0, 0)
	l.filet:SetPoint("TOPRIGHT", l, "TOPRIGHT", 0, 0)
	l.filet:SetHeight(1)
	l:SetScript("OnEnter", function(self) S.colorier(self.fond, "lueur") end)
	l:SetScript("OnLeave", function(self) S.colorier(self.fond, "lueur", 0) end)
	l:SetScript("OnClick", function(self) D.choisir(self.entree) end)
	D.lignes[i] = l
	return l
end

-- Choix d'une entrée : son action, puis la liste se ferme et le bouton se met à jour.
function D.choisir(entree)
	local b = D.bouton
	D.fermer()
	if entree and entree.action then ns.Journal.proteger(entree.action) end
	if b and b.apres then b.apres() end
end

function D.entrees(b) return b.fournir and b.fournir() or {} end

function D.ouvrir(b)
	construire()
	local c = cfg()
	local entrees = D.entrees(b)
	D.bouton = b
	local y, largeur = c.marge, b:GetWidth() or 0
	for i, e in ipairs(entrees) do
		local l = ligne(i)
		l.entree = e
		l:ClearAllPoints()
		if e.separe then y = y + c.ecart_separe end
		l:SetPoint("TOPLEFT", D.cadre, "TOPLEFT", c.marge, -y)
		l:SetPoint("TOPRIGHT", D.cadre, "TOPRIGHT", -c.marge, -y)
		l.texte:SetText(e.texte)
		S.couleurTexte(l.texte, e.coche and "dore_clair" or "texte")
		if e.coche then l.coche:Show() else l.coche:Hide() end
		S.colorier(l.fond, "lueur", 0)
		S.colorier(l.filet, "dore_sombre", e.separe and 1 or 0)
		l:Show()
		local w = (tonumber(l.texte:GetStringWidth()) or 0) + c.taille_coche + 2 * c.marge + 12
		if w > largeur then largeur = w end
		y = y + c.hauteur_ligne
	end
	for i = #entrees + 1, #D.lignes do D.lignes[i]:Hide() end
	D.cadre:ClearAllPoints()
	D.cadre:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
	D.cadre:SetSize(largeur, y + c.marge)
	D.voile:Show()
	D.cadre:Show()
	D.cadre:Raise()
end

function D.fermer()
	if D.cadre then D.cadre:Hide() end
end

function D.ouvert() return D.cadre ~= nil and D.cadre:IsShown() end

-- Bouton de liste déroulante : un clic ouvre (ou referme) la liste ; une petite flèche à droite le signale.
function D.creer(parent, largeur, hauteur, fournir, apres)
	local c = cfg()
	local b = S.bouton(parent, largeur, hauteur)
	b.fournir, b.apres = fournir, apres
	b.fleche = b:CreateTexture(nil, "OVERLAY")
	b.fleche:SetSize(c.taille_fleche, c.taille_fleche)
	b.fleche:SetPoint("RIGHT", b, "RIGHT", -4, 0)
	b.fleche:SetTexture(c.fleche)
	b.etiquette:ClearAllPoints()
	b.etiquette:SetPoint("LEFT", b, "LEFT", 6, 0)
	b.etiquette:SetPoint("RIGHT", b.fleche, "LEFT", -2, 0)
	b:SetScript("OnClick", function(self)
		if D.ouvert() and D.bouton == self then D.fermer() else D.ouvrir(self) end
	end)
	return b
end
