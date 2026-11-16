-- Fenêtre principale : cadre, en-tête, pied de page, déplacement, taille, version mini, ouverture et fermeture.
local _, ns = ...
local F = {}
ns.Fenetre = F

local S = ns.Style
local function ui() return ns.donnees.reglages.interface end

-- Ce que la fenêtre retient (compte) : position, tailles par mode, catégorie choisie.
local function memoire()
	local c = ns.Reglages.compte
	c.fenetre = c.fenetre or {}
	c.fenetre.tailles = c.fenetre.tailles or {}
	return c.fenetre
end
F.memoire = memoire

function F.mode() return ns.Reglages.lire("fenetre.compact") and "mini" or "complet" end

local function limiter(l, h)
	local d = ui()
	local maxl, maxh = UIParent:GetWidth() - d.marge_ecran, UIParent:GetHeight() - d.marge_ecran
	if maxl > 0 then l = math.min(l, maxl) end
	if maxh > 0 then h = math.min(h, maxh) end
	return math.max(l, d.taille_min.l), math.max(h, d.taille_min.h)
end

-- Taille à donner : celle gardée pour ce mode, sinon la taille de départ choisie dans les réglages.
function F.tailleDepart()
	local d = ui()
	local mode = F.mode()
	local t = memoire().tailles[mode]
	if not t then
		if mode == "mini" then
			t = d.taille_mini
		else
			t = d.tailles[ns.Reglages.lire("fenetre.taille")] or d.tailles[d.taille_repli]
		end
	end
	return limiter(t.l, t.h)
end

function F.appliquerTaille()
	local l, h = F.tailleDepart()
	F.cadre:SetSize(l, h)
end

-- Oublie les tailles gardées : la taille de départ choisie s'applique de nouveau.
function F.reinitialiserTaille()
	memoire().tailles = {}
	if F.cadre then F.appliquerTaille() end
end

function F.appliquerPosition()
	local d = ui()
	local p = memoire().position
	F.cadre:ClearAllPoints()
	if p then
		F.cadre:SetPoint(p.point, UIParent, p.relatif, p.x, p.y)
	else
		local pd = d.position_defaut
		F.cadre:SetPoint(pd.point, UIParent, pd.point, pd.x, pd.y)
	end
end

local function memoriserPosition()
	local point, _, relatif, x, y = F.cadre:GetPoint(1)
	if point then memoire().position = { point = point, relatif = relatif, x = x, y = y } end
end

local function memoriserTaille()
	memoire().tailles[F.mode()] = { l = F.cadre:GetWidth(), h = F.cadre:GetHeight() }
end

-- Échap ferme la fenêtre si le réglage est actif.
function F.majEchap()
	local nom = ui().nom_cadre
	local present
	for i, n in ipairs(UISpecialFrames) do
		if n == nom then present = i end
	end
	local voulu = ns.Reglages.lire("fenetre.fermer_avec_echap")
	if voulu and not present then
		table.insert(UISpecialFrames, nom)
	elseif not voulu and present then
		table.remove(UISpecialFrames, present)
	end
end

-- Place les panneaux selon le mode (complet : catégories + liste + fiche ; mini : liste seule).
function F.disposer()
	local d = ui()
	local mini = F.mode() == "mini"
	local cats, liste, fiche, corps = F.panneauCats, F.panneauListe, F.panneauFiche, F.corps
	-- La liste reste toujours accrochée aux deux colonnes de côté ; replier une colonne ne change que sa largeur
	-- (presque nulle) et la cache : on ne ré-accroche jamais la liste (plus sûr dans le jeu).
	local sansCats = mini or ns.Reglages.lire("fenetre.cats_repliee")
	local sansFiche = mini or ns.Reglages.lire("fenetre.fiche_repliee")
	if not F.listeAccrochee then
		liste:ClearAllPoints()
		liste:SetPoint("TOPLEFT", cats, "TOPRIGHT", 0, 0)
		liste:SetPoint("BOTTOMRIGHT", fiche, "BOTTOMLEFT", 0, 0)
		F.listeAccrochee = true
	end
	cats:SetWidth(sansCats and d.largeur_repliee or d.largeur_categories)
	fiche:SetWidth(sansFiche and d.largeur_repliee or d.largeur_fiche)
	-- l'écart entre colonnes : posé sur la liste par ses décalages, refaits sans changer de point d'attache
	liste:SetPoint("TOPLEFT", cats, "TOPRIGHT", sansCats and 0 or d.ecart, 0)
	liste:SetPoint("BOTTOMRIGHT", fiche, "BOTTOMLEFT", sansFiche and 0 or -d.ecart, 0)
	if sansCats then cats:Hide() else cats:Show() end
	if sansFiche then fiche:Hide() else fiche:Show() end
	if ns.Vue.pret then ns.Vue.majReplis() end
	if ns.Diag and ns.Diag.tracer then ns.Diag.tracer("disposer") end
end

------------------------------------------------------------------ construction
local function construireEntete(f)
	local d = ui()
	local entete = CreateFrame("Frame", nil, f)
	F.entete = entete
	entete:SetHeight(d.hauteur_entete)
	entete:SetPoint("TOPLEFT", f, "TOPLEFT", d.marge, -d.marge)
	entete:SetPoint("TOPRIGHT", f, "TOPRIGHT", -d.marge, -d.marge)
	entete:EnableMouse(true)
	entete:RegisterForDrag("LeftButton")
	entete:SetScript("OnDragStart", function() f:StartMoving() end)
	entete:SetScript("OnDragStop", function() f:StopMovingOrSizing() memoriserPosition() end)

	local fond = entete:CreateTexture(nil, "BACKGROUND")
	fond:SetAllPoints(entete)
	S.aplat(fond, "accent_sombre")
	local bande = entete:CreateTexture(nil, "BORDER")
	bande:SetPoint("TOPLEFT", entete, "TOPLEFT", 0, 0)
	bande:SetPoint("TOPRIGHT", entete, "TOPRIGHT", 0, 0)
	bande:SetHeight(d.hauteur_entete / 2)
	S.aplat(bande, "accent", 0.85)
	local filet = entete:CreateTexture(nil, "ARTWORK")
	filet:SetPoint("BOTTOMLEFT", entete, "BOTTOMLEFT", 0, 0)
	filet:SetPoint("BOTTOMRIGHT", entete, "BOTTOMRIGHT", 0, 0)
	filet:SetHeight(2)
	S.aplat(filet, "dore")

	F.embleme = entete:CreateTexture(nil, "ARTWORK")
	F.embleme:SetSize(d.taille_embleme, d.taille_embleme)
	F.embleme:SetPoint("LEFT", entete, "LEFT", 8, 0)
	S.embleme(F.embleme)

	F.titre = S.texte(entete, "titre")
	F.titre:SetPoint("TOPLEFT", F.embleme, "TOPRIGHT", 10, -6)
	S.peindre(function() S.couleurTexte(F.titre, "dore_clair") end)
	F.sousTitre = S.texte(entete, "sous_titre")
	F.sousTitre:SetPoint("TOPLEFT", F.titre, "BOTTOMLEFT", 0, -4)
	S.peindre(function() S.couleurTexte(F.sousTitre, "texte_doux") end)

	F.croix = S.bouton(entete, d.taille_croix, d.taille_croix)
	F.croix:SetPoint("RIGHT", entete, "RIGHT", -8, 0)
	F.croix:Texte("x")
	F.croix:SetScript("OnClick", function() F.fermer() end)

	-- petit « ? » (antisèche des commandes), puis le bouton de mode à sa gauche
	local avant = F.croix
	if ns.AideFenetre then
		F.boutonAide = ns.AideFenetre.brancher(entete, F.croix)
		avant = F.boutonAide
	end
	F.boutonMode = S.bouton(entete, d.largeur_bouton_mode, d.hauteur_bouton)
	F.boutonMode:SetPoint("RIGHT", avant, "LEFT", -8, 0)
	F.boutonMode:SetScript("OnClick", function() F.definirMini(F.mode() ~= "mini") end)
	if ns.ProfilsUI then ns.ProfilsUI.brancher(entete, F.boutonMode) end
end

local function construirePied(f)
	local d = ui()
	local pied = CreateFrame("Frame", nil, f)
	F.pied = pied
	pied:SetHeight(d.hauteur_pied)
	pied:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", d.marge, d.marge)
	pied:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge, d.marge)
	local fond = pied:CreateTexture(nil, "BACKGROUND")
	fond:SetAllPoints(pied)
	S.aplat(fond, "fond_sombre", 0.7)
	local filet = pied:CreateTexture(nil, "ARTWORK")
	filet:SetPoint("TOPLEFT", pied, "TOPLEFT", 0, 0)
	filet:SetPoint("TOPRIGHT", pied, "TOPRIGHT", 0, 0)
	filet:SetHeight(2)
	S.aplat(filet, "dore")

	F.recharger = S.bouton(pied, d.largeur_bouton, d.hauteur_bouton)
	F.recharger:SetPoint("RIGHT", pied, "RIGHT", -(d.taille_poignee + 6), 0)
	F.recharger:SetScript("OnClick", function() ns.Liste.recharger() end)
	F.annuler = S.bouton(pied, d.largeur_bouton, d.hauteur_bouton)
	F.annuler:SetPoint("RIGHT", F.recharger, "LEFT", -8, 0)
	F.annuler:SetScript("OnClick", function()
		ns.Liste.annuler()
		F.rafraichir()
	end)

	-- tout activer / tout désactiver, à gauche du pied
	local function bulle(b, cle)
		b:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(ns.T(cle), 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		b:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	F.toutActiver = S.bouton(pied, d.largeur_bouton, d.hauteur_bouton)
	F.toutActiver:SetPoint("LEFT", pied, "LEFT", 8, 0)
	F.toutActiver:SetScript("OnClick", function() ns.Liste.tout(true) F.rafraichir() end)
	bulle(F.toutActiver, "bouton.tout_activer_aide")
	F.toutDesactiver = S.bouton(pied, d.largeur_bouton, d.hauteur_bouton)
	F.toutDesactiver:SetPoint("LEFT", F.toutActiver, "RIGHT", 8, 0)
	F.toutDesactiver:SetScript("OnClick", function() ns.Liste.tout(false) F.rafraichir() end)
	bulle(F.toutDesactiver, "bouton.tout_desactiver_aide")

	F.texteAttente = S.texte(pied, "normal")
	F.texteAttente:SetPoint("LEFT", F.toutDesactiver, "RIGHT", 12, 0)
	F.texteAttente:SetPoint("RIGHT", F.annuler, "LEFT", -8, 0)
	F.texteAttente:SetJustifyH("LEFT")

	-- le bouton Recharger pulse quand il y a des changements en attente
	F.phase = 0
	F.recharger:SetScript("OnUpdate", function(self, ecoule)
		if not self.pulse then return end
		F.phase = F.phase + (ecoule or 0) * 4
		self.halo:SetAlpha(0.55 + 0.45 * math.sin(F.phase))
	end)
end

local function construirePoignee(f)
	local d = ui()
	local t = d.textures
	local g = CreateFrame("Button", nil, f)
	F.poignee = g
	g:SetSize(d.taille_poignee, d.taille_poignee)
	g:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge / 2, d.marge / 2)
	g:SetNormalTexture(t.poignee)
	g:SetPushedTexture(t.poignee_appui)
	g:SetHighlightTexture(t.poignee)
	g:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
	g:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		memoriserTaille()
		memoriserPosition()
	end)
end

function F.construire()
	if F.cadre then return F.cadre end
	local d = ui()
	local f = S.creerCadre("Frame", d.nom_cadre, UIParent)
	F.cadre = f
	f:SetFrameStrata(d.strate)
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	f:EnableMouse(true)
	if f.SetResizeBounds then
		f:SetResizeBounds(d.taille_min.l, d.taille_min.h)
	elseif f.SetMinResize then
		f:SetMinResize(d.taille_min.l, d.taille_min.h)
	end
	S.fond(f, "fenetre")

	construireEntete(f)
	construirePied(f)

	local corps = CreateFrame("Frame", nil, f)
	F.corps = corps
	corps:SetPoint("TOPLEFT", F.entete, "BOTTOMLEFT", 0, -d.ecart)
	corps:SetPoint("BOTTOMRIGHT", F.pied, "TOPRIGHT", 0, d.ecart)

	local function panneau(style)
		local p = S.creerCadre("Frame", nil, corps)
		S.fond(p, style)
		return p
	end
	F.panneauCats = panneau("panneau")
	F.panneauCats:SetPoint("TOPLEFT", corps, "TOPLEFT", 0, 0)
	F.panneauCats:SetPoint("BOTTOMLEFT", corps, "BOTTOMLEFT", 0, 0)
	F.panneauCats:SetWidth(d.largeur_categories)
	F.panneauFiche = panneau("parchemin")
	F.panneauFiche:SetPoint("TOPRIGHT", corps, "TOPRIGHT", 0, 0)
	F.panneauFiche:SetPoint("BOTTOMRIGHT", corps, "BOTTOMRIGHT", 0, 0)
	F.panneauFiche:SetWidth(d.largeur_fiche)
	F.panneauListe = panneau("panneau")

	construirePoignee(f)
	ns.Vue.construire()

	f:SetScript("OnShow", function()
		F.majEchap()
		F.rafraichir()
		ns.Journal.ecrire("debug", "journal.fenetre_ouverte", S.theme(), F.mode())
	end)
	-- le thème, la police ou la langue peuvent avoir changé : tout est repeint à chaque changement de réglage
	S.peindre(function() if F.cadre:IsShown() and F.pret then F.rafraichir() end end)

	F.appliquerTaille()
	F.appliquerPosition()
	F.disposer()
	F.pret = true
	f:Hide()
	return f
end

------------------------------------------------------------------ mise à jour
function F.rafraichir()
	if not F.cadre then return end
	local d = ui()
	local mini = F.mode() == "mini"
	F.titre:SetText(ns.T("nom"))
	local total, actifs = #ns.Liste.entrees(), 0
	for _, e in ipairs(ns.Liste.entrees()) do
		if ns.Liste.actif(e.nom) then actifs = actifs + 1 end
	end
	F.sousTitre:SetText(ns.T("fenetre.sous_titre", total, actifs))
	F.boutonMode:Texte(ns.T(mini and "fenetre.vers_complet" or "fenetre.vers_mini"))
	F.toutActiver:Texte(ns.T("bouton.tout_activer"))
	F.toutDesactiver:Texte(ns.T("bouton.tout_desactiver"))
	local en_attente = ns.Liste.enAttente()
	if en_attente > 0 then
		F.texteAttente:SetText(ns.T("pied.attente", en_attente))
		F.recharger:Texte(ns.T("bouton.recharger_n", en_attente))
		F.recharger.halo:Show()
		F.recharger.pulse = true
	else
		F.texteAttente:SetText(ns.T("pied.aucun"))
		F.recharger:Texte(ns.T("bouton.recharger"))
		F.recharger.halo:Hide()
		F.recharger.pulse = false
	end
	S.couleurTexte(F.texteAttente, en_attente > 0 and "dore_clair" or "texte_doux")
	local annulations = ns.Liste.nombreAnnulations()
	F.annuler:Texte(annulations > 0 and ns.T("bouton.annuler_n", annulations) or ns.T("bouton.annuler"))
	F.annuler:Activer(annulations > 0)
	ns.Vue.rafraichir()
	if ns.ProfilsUI then ns.ProfilsUI.surChangement() end
end

------------------------------------------------------------------ ouverture, fermeture, mode
function F.ouvrir()
	F.construire()
	F.cadre:Show()
end

function F.fermer()
	if F.cadre then F.cadre:Hide() end
end

function F.estOuverte() return F.cadre ~= nil and F.cadre:IsShown() end

function F.basculer()
	if F.estOuverte() then F.fermer() else F.ouvrir() end
end

-- Passe en version mini (liste seule) ou complète ; chaque mode garde sa taille.
function F.definirMini(mini)
	ns.Reglages.ecrire("fenetre.compact", mini and true or false)
	if F.cadre then
		F.appliquerTaille()
		F.disposer()
		F.rafraichir()
	end
end

-- Repeint tout (thème ou police changés).
function F.peindre()
	S.repeindre()
end

ns.ouvrirFenetre = F.basculer
