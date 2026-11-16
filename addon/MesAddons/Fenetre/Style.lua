-- Style de la fenêtre : thèmes (Horde, Alliance, Neutre), couleurs, fonds, emblème, polices, boutons et cases.
-- Tout ce qui est réglable (couleurs, chemins d'images, tailles) vient de ns.donnees.reglages.interface.
local _, ns = ...
local S = {}
ns.Style = S

local peintres = {} -- fonctions rappelées quand le thème ou la police change
local polices_notees = {}

local function ui() return ns.donnees.reglages.interface end
S.ui = ui

-- "#rrggbb" ou "#rrggbbaa" -> r, g, b, a (0 à 1)
function S.hex(texte)
	local h = string.gsub(texte or "", "^#", "")
	local function part(i) return (tonumber(string.sub(h, i, i + 1), 16) or 255) / 255 end
	local a = 1
	if string.len(h) >= 8 then a = part(7) end
	return part(1), part(3), part(5), a
end

-- Thème choisi dans les réglages ("auto", "horde", "alliance", "neutre").
function S.themeChoisi() return ns.Reglages.lire("fenetre.theme") end

-- Thème selon la faction du personnage connecté.
function S.themeAuto()
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	return (faction and ui().factions[faction]) or ui().theme_repli
end

-- Thème réellement affiché ("horde", "alliance" ou "neutre").
function S.theme()
	local choix = S.themeChoisi()
	if choix == "auto" or not ui().themes[choix] then return S.themeAuto() end
	return choix
end

function S.palette() return ui().themes[S.theme()] end
function S.couleur(cle) return S.hex(S.palette()[cle]) end

-- Enregistre une fonction de peinture, l'exécute tout de suite, et la rappelle à chaque changement de thème.
function S.peindre(f)
	peintres[#peintres + 1] = f
	f()
	return f
end

function S.repeindre()
	for _, f in ipairs(peintres) do f() end
end

-- Les cadres à fond/bord utilisent le gabarit « BackdropTemplate » quand le jeu le connaît.
function S.creerCadre(type_, nom, parent)
	local ok, cadre = pcall(CreateFrame, type_, nom, parent, "BackdropTemplate")
	if ok and cadre then return cadre end
	return CreateFrame(type_, nom, parent)
end

-- Fond et bord d'un cadre d'après le style (clé de interface.fonds), repeints avec le thème.
function S.fond(cadre, style)
	local d = ui().fonds[style]
	if type(cadre.SetBackdrop) ~= "function" then return end
	cadre.styleFond = style
	S.peindre(function()
		-- Opacité réglable (fenêtre, panneaux) : à 100 le fond est plein ; en dessous, la texture du jeu est teintée.
		local pct = d.opacite and tonumber(ns.Reglages.lire("fenetre.opacite")) or 100
		local plein = d.plein and pct >= 100
		-- fond plein au choix (parchemin : « jeu » = texture, « uni » = aplat clair)
		if d.reglage_plein then plein = d.plein and ns.Reglages.lire(d.reglage_plein) == d.valeur_plein end
		cadre:SetBackdrop({
			bgFile = plein and d.plein or d.fond, edgeFile = d.bord, tile = d.tuile and not plein,
			tileSize = d.taille_tuile, edgeSize = d.taille_bord,
			insets = { left = d.retrait, right = d.retrait, top = d.retrait, bottom = d.retrait },
		})
		-- texture du jeu : teinte à part (blanc = ses vraies couleurs), sinon la couleur du fond
		local r, g, b = S.couleur((not plein and d.couleur_texture) or d.couleur_fond)
		local alpha = d.alpha_fond
		if d.opacite and pct < 100 then alpha = alpha * pct / 100 end
		cadre:SetBackdropColor(r, g, b, plein and 1 or alpha)
		cadre:SetBackdropBorderColor(S.couleur(d.couleur_bord))
	end)
end

-- Couleur pleine sur une texture ; `alpha` remplace l'opacité de la couleur si donné.
function S.colorier(texture, cle, alpha)
	local r, g, b, a = S.couleur(cle)
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, alpha or a)
	else
		texture:SetTexture(ui().textures.blanc)
		texture:SetVertexColor(r, g, b, alpha or a)
	end
end

function S.aplat(texture, cle, alpha)
	S.peindre(function() S.colorier(texture, cle, alpha) end)
end

function S.couleurTexte(texte, cle)
	texte:SetTextColor(S.couleur(cle))
end

-- Police : chemin selon le réglage ; si la police est introuvable, retour à la police du jeu (noté une fois au journal).
function S.cheminPolice(choix)
	local polices = ui().polices
	choix = choix or ns.Reglages.lire("fenetre.police")
	return (polices[choix] or polices[ui().police_repli]).chemin
end

-- Taille d'un rôle de texte, multipliée par le réglage « Taille du texte ».
function S.taille(role)
	local e = ui().echelles_texte[ns.Reglages.lire("fenetre.taille_texte")] or 1
	return math.floor((ui().tailles_texte[role] or ui().tailles_texte.normal) * e + 0.5)
end

function S.appliquerPolice(texte, role)
	local taille = S.taille(role)
	local chemin = S.cheminPolice()
	if not texte:SetFont(chemin, taille, ui().contour_texte) then
		if not polices_notees[chemin] then
			polices_notees[chemin] = true
			ns.Journal.ecrire("avertissement", "journal.police_absente", chemin)
		end
		texte:SetFont(S.cheminPolice(ui().police_repli), taille, ui().contour_texte)
	end
end

-- Texte (FontString) avec police suivie ; la police est posée tout de suite (le jeu l'exige avant tout texte).
function S.texte(parent, role, calque)
	local t = parent:CreateFontString(nil, calque or "OVERLAY")
	S.peindre(function() S.appliquerPolice(t, role) end)
	return t
end

-- Emblème de la faction : fichier d'image du jeu d'abord, puis atlas, puis icône de secours.
function S.embleme(texture)
	S.peindre(function()
		local e = ui().emblemes[S.theme()]
		texture:SetTexCoord(0, 1, 0, 1)
		for _, fichier in ipairs(e.fichiers) do
			texture:SetTexture(fichier)
			if texture:GetTexture() then return end
		end
		for _, atlas in ipairs(e.atlas) do
			if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
				texture:SetAtlas(atlas, false)
				return
			end
		end
		texture:SetTexture(ui().textures.icone_defaut)
	end)
end

-- Bouton du style de la fenêtre. b.etiquette = texte ; b:Activer(vrai/faux) ; b.glow = halo (texture).
function S.bouton(parent, largeur, hauteur)
	local b = S.creerCadre("Button", nil, parent)
	b:SetSize(largeur, hauteur)
	S.fond(b, "bouton")
	b.etiquette = S.texte(b, "normal")
	b.etiquette:SetPoint("CENTER", b, "CENTER", 0, 0)
	b.halo = b:CreateTexture(nil, "OVERLAY")
	b.halo:SetAllPoints(b)
	S.aplat(b.halo, "dore_clair", 0.35)
	b.halo:Hide()
	b.actif = true
	local function peindreEtiquette()
		b.etiquette:SetTextColor(S.couleur(b.actif and "dore_clair" or "texte_eteint"))
	end
	S.peindre(peindreEtiquette)
	function b:Activer(oui)
		self.actif = oui and true or false
		if oui then self:Enable() else self:Disable() end
		peindreEtiquette()
	end
	function b:Texte(t) self.etiquette:SetText(t) end
	b:SetScript("OnEnter", function(self)
		if self.actif and self.SetBackdropBorderColor then self:SetBackdropBorderColor(S.couleur("dore_clair")) end
	end)
	b:SetScript("OnLeave", function(self)
		if self.SetBackdropBorderColor then self:SetBackdropBorderColor(S.couleur(ui().fonds.bouton.couleur_bord)) end
	end)
	return b
end

-- Case à cocher aux images du jeu.
function S.case(parent)
	local t = ui().textures
	local c = CreateFrame("CheckButton", nil, parent)
	c:SetSize(ui().taille_case, ui().taille_case)
	c:SetNormalTexture(t.case_vide)
	c:SetPushedTexture(t.case_appui)
	c:SetHighlightTexture(t.case_survol, "ADD")
	c:SetCheckedTexture(t.case_coche)
	c:SetDisabledCheckedTexture(t.case_coche)
	return c
end
