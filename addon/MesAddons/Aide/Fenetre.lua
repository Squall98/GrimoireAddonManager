-- Fenêtre de l'antisèche : à gauche une colonne d'onglets (les thèmes de ce gestionnaire, puis les autres add-ons par
-- catégorie ou un par add-on), à droite la page choisie, en cartes qui défilent ; la recherche porte sur toutes les pages
-- (onglet « Résultats »). Déplaçable, redimensionnable par la poignée, place et taille gardées (sauvegardes du compte),
-- Échap la ferme. Clic sur une commande = écrite dans le chat ; Maj + clic = lancée (réglage aide.executer_maj).
-- Tailles et réglages : ns.donnees.reglages.interface.aide et ns.donnees.reglages.aide ; textes : ns.T("aide.*").
local _, ns = ...
local W = {}
ns.AideFenetre = W

local S, A = ns.Style, ns.Aide
local function ui() return ns.donnees.reglages.interface end
local function cfg() return ui().aide end
local function regl() return ns.donnees.reglages.aide end

W.recherche = ""
W.portee = nil        -- nil = celle des réglages
W.onglet = nil        -- id de la page choisie (nil = celle gardée, sinon la première)
W.enResultats = false -- vrai : on montre les résultats de la recherche, toutes pages confondues
W.pages = {}          -- pages de A.pages
W.resultats = nil     -- page « Résultats » (toutes les cartes trouvées)
W.page = nil          -- page montrée
W.donnees = {}        -- toutes les lignes à plat (groupe, commande, note), pages confondues
W.onglets = {}        -- boutons d'onglet (réserve réutilisée)
W.sections = {}       -- titres de section de la colonne (réserve)
W.cartes = {}         -- cartes de la page (réserve ; chaque carte garde ses lignes)

function W.porteeActuelle() return W.portee or ns.Reglages.lire("aide.portee") end

------------------------------------------------------------------ mémoire : taille, place, onglet
local function memoire()
	local c = ns.Reglages.compte
	local cle = cfg().cle_memoire
	c[cle] = c[cle] or {}
	return c[cle]
end
W.memoire = memoire

-- Taille ramenée entre la mini et la maxi (et jamais plus grande que l'écran).
local function limiter(l, h)
	local d, u = cfg(), ui()
	local maxl, maxh = d.taille_max.l, d.taille_max.h
	local ecranl, ecranh = UIParent:GetWidth() - u.marge_ecran, UIParent:GetHeight() - u.marge_ecran
	if ecranl > 0 then maxl = math.min(maxl, ecranl) end
	if ecranh > 0 then maxh = math.min(maxh, ecranh) end
	return math.max(math.min(l, maxl), d.taille_min.l), math.max(math.min(h, maxh), d.taille_min.h)
end
W.limiter = limiter

function W.tailleDepart()
	local d = cfg()
	local t = memoire().taille or { l = d.largeur, h = d.hauteur }
	return limiter(t.l, t.h)
end

function W.appliquerTaille()
	local l, h = W.tailleDepart()
	W.cadre:SetSize(l, h)
end

function W.appliquerPosition()
	local p = memoire().position
	W.cadre:ClearAllPoints()
	if p then
		W.cadre:SetPoint(p.point, UIParent, p.relatif, p.x, p.y)
	else
		local pd = cfg().position_defaut
		W.cadre:SetPoint(pd.point, UIParent, pd.point, pd.x, pd.y)
	end
end

-- Oublie la taille et la place gardées.
function W.reinitialiserTaille()
	local m = memoire()
	m.taille, m.position = nil, nil
	if W.cadre then
		W.appliquerTaille()
		W.appliquerPosition()
	end
end

local function memoriserPosition()
	local point, _, relatif, x, y = W.cadre:GetPoint(1)
	if point then memoire().position = { point = point, relatif = relatif, x = x, y = y } end
end

local function memoriserTaille()
	memoire().taille = { l = W.cadre:GetWidth(), h = W.cadre:GetHeight() }
end

------------------------------------------------------------------ contenu
-- Page à montrer : les résultats pendant une recherche (sauf si on a choisi un onglet), sinon l'onglet choisi.
local function pageChoisie()
	if W.enResultats and W.recherche ~= "" then return W.resultats end
	local voulu = W.onglet or memoire().onglet
	for _, p in ipairs(W.pages) do
		if p.id == voulu then return p end
	end
	return W.pages[1]
end

function W.rafraichir()
	local f = W.cadre
	if not f or not f:IsShown() then return end
	local pages, total = A.pages(W.porteeActuelle(), W.recherche)
	W.pages = pages
	local res = { id = regl().id_resultats, titre = ns.T("aide.onglet_resultats"), cartes = {}, total = total }
	local plat = {}
	for _, p in ipairs(pages) do
		for _, c in ipairs(p.cartes) do
			res.cartes[#res.cartes + 1] = c
			plat[#plat + 1] = { type = "groupe", texte = c.titre, eteint = c.eteint }
			for _, l in ipairs(c.lignes) do plat[#plat + 1] = l end
		end
	end
	W.resultats, W.donnees = res, plat
	W.page = pageChoisie()
	if W.recherche ~= "" then
		W.resume:SetText(ns.T("aide.resume_filtre", total, W.recherche))
	else
		W.resume:SetText(ns.T("aide.resume", total, #pages))
	end
	W.boutonPortee:Texte(ns.T("aide.portee", ns.T("aideportee." .. W.porteeActuelle())))
	W.astuce:SetText(ns.T(ns.Reglages.lire("aide.executer_maj") and "aide.astuce_maj" or "aide.astuce"))
	W.effacer:Activer(W.recherche ~= "")
	W.dessinerOnglets()
	W.disposer()
end

-- Choisit un onglet (id d'une page, ou celui des résultats) ; l'onglet d'une page est gardé pour la prochaine fois.
function W.choisir(id)
	if id == regl().id_resultats then
		W.enResultats = true
	else
		W.enResultats = false
		W.onglet = id
		memoire().onglet = id
	end
	if not W.cadre then return end
	W.page = pageChoisie()
	W.dessinerOnglets()
	W.disposer()
	W.zoneCartes.haut()
end

function W.chercher(texte)
	W.recherche = texte or ""
	W.enResultats = W.recherche ~= ""
	W.rafraichir()
	if W.zoneCartes then W.zoneCartes.haut() end
end

function W.changerPortee()
	local liste = regl().portees
	local actuelle, suivante = W.porteeActuelle(), 1
	for i, id in ipairs(liste) do if id == actuelle then suivante = i % #liste + 1 end end
	W.portee = liste[suivante]
	W.rafraichir()
	W.zoneCartes.haut()
end

-- Clic sur une ligne (Maj + clic : lancer).
function W.cliquer(ligne, executer)
	if not ligne or ligne.type ~= "cmd" then return end
	W.message:SetText(A.agir(ligne, executer))
end

-- « 1 commande », « 3 commandes ».
function W.compte(n)
	return n == 1 and ns.T("aide.compte_un", n) or ns.T("aide.compte_carte", n)
end

-- Lignes montrées dans la page (boutons), dans l'ordre.
function W.lignesVisibles()
	local res = {}
	for _, c in ipairs(W.cartes) do
		if c:IsShown() then
			for _, r in ipairs(c.lignes) do if r:IsShown() then res[#res + 1] = r end end
		end
	end
	return res
end

------------------------------------------------------------------ colonne des onglets
function W.creerOnglet(n)
	local d = cfg()
	local b = S.bouton(W.zoneOnglets.contenu, d.largeur_onglet, d.hauteur_onglet)
	b.nombre = S.texte(b, "petit")
	b.nombre:SetPoint("RIGHT", b, "RIGHT", -d.retrait_onglet, 0)
	b.nombre:SetWidth(d.largeur_nombre)
	b.nombre:SetJustifyH("RIGHT")
	S.peindre(function() S.couleurTexte(b.nombre, "texte_doux") end)
	b.etiquette:ClearAllPoints()
	b.etiquette:SetPoint("LEFT", b, "LEFT", d.retrait_onglet, 0)
	b.etiquette:SetPoint("RIGHT", b.nombre, "LEFT", -4, 0)
	b.etiquette:SetJustifyH("LEFT")
	b.etiquette:SetWordWrap(false)
	b:SetScript("OnClick", function(self) if self.page then W.choisir(self.page.id) end end)
	b:HookScript("OnEnter", function(self)
		if not self.page then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(self.page.titre, S.couleur("dore_clair"))
		GameTooltip:AddLine(W.compte(self.page.total), S.couleur("texte"))
		GameTooltip:Show()
	end)
	b:HookScript("OnLeave", function() GameTooltip:Hide() end)
	W.onglets[n] = b
	return b
end

function W.creerSection(n)
	local t = S.texte(W.zoneOnglets.contenu, "petit")
	t:SetJustifyH("LEFT")
	t:SetJustifyV("MIDDLE")
	S.peindre(function() S.couleurTexte(t, "texte_doux") end)
	W.sections[n] = t
	return t
end

function W.dessinerOnglets()
	local d = cfg()
	local contenu = W.zoneOnglets.contenu
	local y, n, s = 0, 0, 0
	local function onglet(p)
		n = n + 1
		local b = W.onglets[n] or W.creerOnglet(n)
		b.page = p
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", contenu, "TOPLEFT", 0, -y)
		b:SetPoint("TOPRIGHT", contenu, "TOPRIGHT", 0, -y)
		b:Texte(p.titre)
		b.nombre:SetText(tostring(p.total))
		b.etiquette:SetAlpha(p.eteint and d.alpha_eteint or 1)
		if p == W.page then b.halo:Show() else b.halo:Hide() end
		b:Show()
		y = y + d.hauteur_onglet + d.ecart_onglet
	end
	local function section(id)
		s = s + 1
		local t = W.sections[s] or W.creerSection(s)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", contenu, "TOPLEFT", d.retrait_onglet, -y)
		t:SetPoint("TOPRIGHT", contenu, "TOPRIGHT", 0, -y)
		t:SetHeight(d.hauteur_section)
		t:SetText(ns.T("aideportee." .. id))
		t:Show()
		y = y + d.hauteur_section
	end
	if W.recherche ~= "" then onglet(W.resultats) end
	local derniere
	for _, p in ipairs(W.pages) do
		if p.section ~= derniere then
			section(p.section)
			derniere = p.section
		end
		onglet(p)
	end
	for i = n + 1, #W.onglets do
		W.onglets[i].page = nil
		W.onglets[i]:Hide()
	end
	for i = s + 1, #W.sections do W.sections[i]:Hide() end
	W.zoneOnglets.hauteur(y)
end

------------------------------------------------------------------ cartes et lignes de la page
local function survolLigne(self)
	local l = self.ligne
	if not l or l.type ~= "cmd" then return end
	S.colorier(self.fond, "lueur")
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(l.cmd, S.couleur("dore_clair"))
	if l.desc and l.desc ~= "" then
		local r, g, b = S.couleur("texte")
		GameTooltip:AddLine(l.desc, r, g, b, true)
	end
	local r, g, b = S.couleur("texte_doux")
	GameTooltip:AddLine(ns.T(ns.Reglages.lire("aide.executer_maj") and "aide.astuce_maj" or "aide.astuce"), r, g, b, true)
	GameTooltip:Show()
end

local function finSurvolLigne(self)
	S.colorier(self.fond, "lueur", self.zebre and cfg().alpha_zebre or 0)
	GameTooltip:Hide()
end

function W.creerLigne(carte, j)
	local r = CreateFrame("Button", nil, carte)
	r.fond = r:CreateTexture(nil, "BACKGROUND", nil, 1)
	r.fond:SetAllPoints(r)
	r.cmd = S.texte(r, "normal")
	r.cmd:SetJustifyH("LEFT")
	r.cmd:SetWordWrap(false)
	r.desc = S.texte(r, "petit")
	r.desc:SetJustifyH("LEFT")
	r.desc:SetWordWrap(false)
	S.peindre(function()
		S.couleurTexte(r.cmd, "dore_clair")
		S.couleurTexte(r.desc, "texte_doux")
	end)
	r:SetScript("OnClick", function(self) W.cliquer(self.ligne, IsShiftKeyDown()) end)
	r:SetScript("OnEnter", survolLigne)
	r:SetScript("OnLeave", finSurvolLigne)
	carte.lignes[j] = r
	return r
end

-- Remplit une ligne : commande en doré, sa description dessous en plus petit ; une note : texte seul, pas cliquable.
function W.remplirLigne(r, l, j)
	local d = cfg()
	r.ligne = l
	r.zebre = (j % 2 == 0)
	S.colorier(r.fond, "lueur", r.zebre and d.alpha_zebre or 0)
	r.cmd:ClearAllPoints()
	r.desc:ClearAllPoints()
	if l.type == "cmd" then
		local desc = l.desc or ""
		r.cmd:SetText(l.cmd)
		r.cmd:Show()
		r.desc:SetText(desc)
		if desc ~= "" then
			r:SetHeight(d.hauteur_cmd)
			r.cmd:SetPoint("TOPLEFT", r, "TOPLEFT", d.retrait_ligne, -d.haut_cmd)
			r.cmd:SetPoint("TOPRIGHT", r, "TOPRIGHT", -d.retrait_ligne, -d.haut_cmd)
			r.desc:SetPoint("TOPLEFT", r.cmd, "BOTTOMLEFT", 0, -d.ecart_desc)
			r.desc:SetPoint("TOPRIGHT", r.cmd, "BOTTOMRIGHT", 0, -d.ecart_desc)
			r.desc:Show()
		else
			r:SetHeight(d.hauteur_cmd_seule)
			r.cmd:SetPoint("LEFT", r, "LEFT", d.retrait_ligne, 0)
			r.cmd:SetPoint("RIGHT", r, "RIGHT", -d.retrait_ligne, 0)
			r.desc:Hide()
		end
	else
		r:SetHeight(d.hauteur_note)
		r.cmd:SetText("")
		r.cmd:Hide()
		r.desc:SetText(l.texte)
		r.desc:SetPoint("LEFT", r, "LEFT", d.retrait_ligne, 0)
		r.desc:SetPoint("RIGHT", r, "RIGHT", -d.retrait_ligne, 0)
		r.desc:Show()
	end
	local alpha = l.eteint and d.alpha_eteint or 1
	r.cmd:SetAlpha(alpha)
	r.desc:SetAlpha(alpha)
end

function W.creerCarte(i)
	local d = cfg()
	local carte = S.creerCadre("Frame", nil, W.zoneCartes.contenu)
	S.fond(carte, "panneau")
	carte.lignes = {}
	carte.nombre = S.texte(carte, "petit")
	carte.nombre:SetPoint("TOPRIGHT", carte, "TOPRIGHT", -(d.marge_carte + 2), -(d.marge_carte + 2))
	carte.nombre:SetJustifyH("RIGHT")
	carte.titre = S.texte(carte, "entete")
	carte.titre:SetPoint("TOPLEFT", carte, "TOPLEFT", d.marge_carte + 2, -d.marge_carte)
	carte.titre:SetPoint("RIGHT", carte.nombre, "LEFT", -6, 0)
	carte.titre:SetJustifyH("LEFT")
	carte.titre:SetWordWrap(false)
	S.peindre(function()
		S.couleurTexte(carte.titre, "dore_clair")
		S.couleurTexte(carte.nombre, "texte_doux")
	end)
	W.cartes[i] = carte
	return carte
end

-- Place les cartes de la page montrée (hauteurs d'après le nombre de lignes) et règle la portée du défilement.
function W.disposer()
	if not W.cadre then return end
	local d = cfg()
	local contenu = W.zoneCartes.contenu
	local cartes = W.page and W.page.cartes or {}
	local y = 0
	for i, c in ipairs(cartes) do
		local carte = W.cartes[i] or W.creerCarte(i)
		carte.donnee = c
		carte.titre:SetText(c.titre .. (c.eteint and ns.T("aide.eteint") or ""))
		carte.titre:SetAlpha(c.eteint and d.alpha_eteint or 1)
		carte.nombre:SetText(c.total > 0 and W.compte(c.total) or "")
		local h = d.hauteur_titre_carte
		for j, l in ipairs(c.lignes) do
			local r = carte.lignes[j] or W.creerLigne(carte, j)
			W.remplirLigne(r, l, j)
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", carte, "TOPLEFT", d.marge_carte, -h)
			r:SetPoint("TOPRIGHT", carte, "TOPRIGHT", -d.marge_carte, -h)
			r:Show()
			h = h + r:GetHeight()
		end
		for j = #c.lignes + 1, #carte.lignes do
			carte.lignes[j].ligne = nil
			carte.lignes[j]:Hide()
		end
		carte:ClearAllPoints()
		carte:SetPoint("TOPLEFT", contenu, "TOPLEFT", 0, -y)
		carte:SetPoint("TOPRIGHT", contenu, "TOPRIGHT", 0, -y)
		carte:SetHeight(h + d.marge_carte)
		carte:Show()
		y = y + h + d.marge_carte + d.ecart_carte
	end
	for i = #cartes + 1, #W.cartes do W.cartes[i]:Hide() end
	W.vide:SetText(ns.T("aide.vide"))
	if #cartes == 0 then W.vide:Show() else W.vide:Hide() end
	W.zoneCartes.hauteur(y)
end

-- Après un changement de taille : on refait la mise en page au tour suivant (jamais pendant le redimensionnement).
function W.planifier()
	if W.prevu then return end
	W.prevu = true
	C_Timer.After(0, function()
		W.prevu = false
		if W.cadre and W.cadre:IsShown() then
			W.dessinerOnglets()
			W.disposer()
		end
	end)
end

------------------------------------------------------------------ construction
local function bouton(parent, cle, action)
	local d = cfg()
	local b = S.bouton(parent, d.largeur_bouton, d.hauteur_bouton)
	b:Texte(ns.T(cle))
	b:SetScript("OnClick", action)
	return b
end

local function infobulle(cadre, cle)
	cadre:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(ns.T(cle), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	cadre:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function construirePoignee(f)
	local d, u = cfg(), ui()
	local t = u.textures
	local g = CreateFrame("Button", nil, f)
	W.poignee = g
	g:SetSize(u.taille_poignee, u.taille_poignee)
	g:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge / 2, d.marge / 2)
	g:SetNormalTexture(t.poignee)
	g:SetPushedTexture(t.poignee_appui)
	g:SetHighlightTexture(t.poignee)
	g:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	g:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		memoriserTaille()
		memoriserPosition()
		W.planifier()
	end)
	g:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(ns.T("aide.redimensionner"), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	g:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function W.construire()
	if W.cadre then return W.cadre end
	local d, u = cfg(), ui()
	local f = S.creerCadre("Frame", d.nom_cadre, UIParent)
	W.cadre = f
	f:SetFrameStrata(d.strate)
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	f:EnableMouse(true)
	if f.SetResizeBounds then
		f:SetResizeBounds(d.taille_min.l, d.taille_min.h, d.taille_max.l, d.taille_max.h)
	else
		if f.SetMinResize then f:SetMinResize(d.taille_min.l, d.taille_min.h) end
		if f.SetMaxResize then f:SetMaxResize(d.taille_max.l, d.taille_max.h) end
	end
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		memoriserPosition()
	end)
	S.fond(f, "fenetre")
	table.insert(UISpecialFrames, d.nom_cadre)

	local m, ecart = d.marge, d.ecart
	W.titre = S.texte(f, "titre")
	W.titre:SetPoint("TOPLEFT", f, "TOPLEFT", m + 6, -m - 4)
	S.peindre(function() S.couleurTexte(W.titre, "dore_clair") end)

	W.croix = S.bouton(f, d.hauteur_bouton, d.hauteur_bouton)
	W.croix:SetPoint("TOPRIGHT", f, "TOPRIGHT", -m, -m)
	W.croix:SetScript("OnClick", function() W.fermer() end)

	W.resume = S.texte(f, "sous_titre")
	W.resume:SetPoint("TOPLEFT", f, "TOPLEFT", m + 6, -m - d.hauteur_titre - 2)
	W.resume:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(W.resume, "texte_doux") end)

	-- ligne de recherche : étiquette, champ (prend la place libre), effacer, choix du contenu
	local haut = m + d.hauteur_titre + d.hauteur_bandeau + ecart
	W.boutonPortee = S.bouton(f, d.largeur_bouton_portee, d.hauteur_bouton)
	W.boutonPortee:SetPoint("TOPRIGHT", f, "TOPRIGHT", -m, -haut)
	W.boutonPortee:SetScript("OnClick", function() W.changerPortee() end)
	W.etiquetteRecherche = S.texte(f, "normal")
	W.etiquetteRecherche:SetPoint("TOPLEFT", f, "TOPLEFT", m + 6, -haut - 5)
	S.peindre(function() S.couleurTexte(W.etiquetteRecherche, "texte") end)
	W.effacer = S.bouton(f, d.largeur_effacer, d.hauteur_champ)
	W.effacer:SetPoint("RIGHT", W.boutonPortee, "LEFT", -ecart * 2, 0)
	W.effacer:SetScript("OnClick", function()
		W.champ:SetText("")
		W.champ:ClearFocus()
	end)
	infobulle(W.effacer, "aide.effacer_info")
	local champ = S.creerCadre("EditBox", nil, f)
	W.champ = champ
	S.fond(champ, "champ")
	champ:SetAutoFocus(false)
	champ:SetHeight(d.hauteur_champ)
	champ:SetPoint("LEFT", W.etiquetteRecherche, "RIGHT", ecart, 0)
	champ:SetPoint("RIGHT", W.effacer, "LEFT", -ecart, 0)
	champ:SetTextInsets(6, 6, 0, 0)
	S.peindre(function()
		local taille = S.taille("normal")
		champ:SetFont(S.cheminPolice(u.police_repli), taille, u.contour_texte)
		pcall(champ.SetFont, champ, S.cheminPolice(), taille, u.contour_texte)
		champ:SetTextColor(S.couleur("texte"))
	end)
	champ:SetScript("OnTextChanged", function(self) W.chercher(self:GetText()) end)
	champ:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	champ:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

	-- corps : colonne des onglets à gauche, page en cartes à droite (les deux défilent)
	local corpsHaut = haut + d.hauteur_champ + ecart * 2
	local corpsBas = m + d.hauteur_bouton + ecart
	local colonne = S.creerCadre("Frame", nil, f)
	W.colonne = colonne
	S.fond(colonne, "panneau")
	colonne:SetPoint("TOPLEFT", f, "TOPLEFT", m, -corpsHaut)
	colonne:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", m, corpsBas)
	colonne:SetWidth(d.largeur_onglet)
	W.zoneOnglets = ns.Vue.defilement(colonne)
	W.zoneOnglets.sf:SetPoint("TOPLEFT", colonne, "TOPLEFT", 4, -4)
	W.zoneOnglets.sf:SetPoint("BOTTOMRIGHT", colonne, "BOTTOMRIGHT", -(u.largeur_barre + 4), 4)
	W.zoneOnglets.barre:SetPoint("TOPRIGHT", colonne, "TOPRIGHT", -3, -4)
	W.zoneOnglets.barre:SetPoint("BOTTOMRIGHT", colonne, "BOTTOMRIGHT", -3, 4)

	W.zoneCartes = ns.Vue.defilement(f)
	W.zoneCartes.sf:SetPoint("TOPLEFT", colonne, "TOPRIGHT", ecart * 2, 0)
	W.zoneCartes.sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(m + u.largeur_barre + 4), corpsBas)
	W.zoneCartes.barre:SetPoint("TOPRIGHT", f, "TOPRIGHT", -m, -corpsHaut)
	W.zoneCartes.barre:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -m, corpsBas)
	W.vide = S.texte(f, "normal")
	W.vide:SetPoint("TOP", W.zoneCartes.sf, "TOP", 0, -d.hauteur_titre_carte)
	S.peindre(function() S.couleurTexte(W.vide, "texte_doux") end)
	W.vide:Hide()

	-- pied : conseil et message à gauche, boutons à droite (la poignée dans le coin)
	W.boutonFermer = bouton(f, "aide.bouton.fermer", function() W.fermer() end)
	W.boutonFermer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(m + u.taille_poignee), m)
	W.boutonVisite = bouton(f, "aide.bouton.visite", function()
		W.fermer()
		if ns.Visite then ns.Visite.demarrer() end
	end)
	W.boutonVisite:SetPoint("RIGHT", W.boutonFermer, "LEFT", -ecart, 0)
	W.message = S.texte(f, "petit")
	W.message:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", m + 6, m + 2)
	W.message:SetPoint("RIGHT", W.boutonVisite, "LEFT", -ecart, 0)
	W.message:SetJustifyH("LEFT")
	W.message:SetWordWrap(false)
	S.peindre(function() S.couleurTexte(W.message, "dore_clair") end)
	W.astuce = S.texte(f, "petit")
	W.astuce:SetPoint("BOTTOMLEFT", W.message, "TOPLEFT", 0, 2)
	W.astuce:SetPoint("RIGHT", W.boutonVisite, "LEFT", -ecart, 0)
	W.astuce:SetJustifyH("LEFT")
	W.astuce:SetWordWrap(false)
	S.peindre(function() S.couleurTexte(W.astuce, "texte_doux") end)

	construirePoignee(f)

	f:SetScript("OnShow", function()
		W.rafraichir()
		W.planifier()
	end)
	f:SetScript("OnSizeChanged", function() W.planifier() end)
	-- langue ou thème changés : tout est repeint et retraduit
	local function textes()
		W.titre:SetText(ns.T("aide.titre_fenetre"))
		W.etiquetteRecherche:SetText(ns.T("aide.chercher"))
		W.croix:Texte(ns.T("aide.bouton.croix"))
		W.effacer:Texte(ns.T("aide.bouton.croix"))
		W.boutonVisite:Texte(ns.T("aide.bouton.visite"))
		W.boutonFermer:Texte(ns.T("aide.bouton.fermer"))
	end
	textes()
	S.peindre(function()
		if not W.cadre then return end
		textes()
		if W.cadre:IsShown() then W.rafraichir() end
	end)
	W.appliquerTaille()
	W.appliquerPosition()
	f:Hide()
	return f
end

function W.estOuverte() return W.cadre ~= nil and W.cadre:IsShown() end

-- Ouvre la fenêtre ; `recherche` (texte) la remplit dans le champ, sinon on garde la précédente.
function W.ouvrir(recherche)
	W.construire()
	if recherche ~= nil then
		W.champ:SetText(recherche)
		W.recherche = recherche
		W.enResultats = recherche ~= ""
	end
	W.message:SetText("")
	if W.cadre:IsShown() then W.rafraichir() else W.cadre:Show() end
end

function W.fermer()
	if W.cadre then W.cadre:Hide() end
end

function W.basculer()
	if W.estOuverte() then W.fermer() else W.ouvrir() end
end
