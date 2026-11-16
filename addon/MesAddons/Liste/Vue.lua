-- Contenu de la fenêtre : colonne des catégories, liste des add-ons (cases, sous-modules repliés) et fiche courte.
local _, ns = ...
local V = {}
ns.Vue = V

local S, M = ns.Style, ns.Liste
local function ui() return ns.donnees.reglages.interface end

V.deplie = {}      -- nom d'un add-on principal -> modules dépliés (vrai/faux)
V.selection = nil  -- nom de l'add-on dont la fiche est affichée
V.lignes = {}      -- lignes de la liste (réserve réutilisée)
V.lignesCat = {}   -- lignes de la colonne des catégories
V.entetes = {}     -- en-têtes de catégorie dans « Tous les add-ons » (réserve réutilisée)
V.replie = {}      -- id d'une catégorie -> repliée dans « Tous les add-ons » (vrai/faux)

function V.categorieActive()
	local id = ns.Fenetre.memoire().categorie
	if not id or not M.entreesCategorie(id)[1] then id = ui().categorie_tous end
	return id
end

function V.estDeplie(nom)
	local v = V.deplie[nom]
	if v == nil then return not ns.Reglages.lire("fenetre.modules_replies") end
	return v
end

-- Une catégorie est-elle repliée dans « Tous les add-ons » ? (sinon : réglage de départ)
function V.estReplie(id)
	local v = V.replie[id]
	if v == nil then return ns.Reglages.lire("liste.groupes_replies") end
	return v
end

------------------------------------------------------------------ zone qui défile
local function defilement(parent)
	local d = ui()
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local contenu = CreateFrame("Frame", nil, sf)
	contenu:SetSize(10, 10)
	sf:SetScrollChild(contenu)
	local barre = CreateFrame("Slider", nil, parent)
	barre:SetOrientation("VERTICAL")
	barre:SetWidth(d.largeur_barre)
	barre:SetThumbTexture(d.textures.ascenseur)
	barre:GetThumbTexture():SetSize(d.largeur_barre, d.hauteur_pouce)
	barre:SetMinMaxValues(0, 0)
	barre:SetValueStep(1)
	barre:SetValue(0)
	barre:SetScript("OnValueChanged", function(_, valeur) sf:SetVerticalScroll(valeur) end)
	sf:EnableMouseWheel(true)
	sf:SetScript("OnMouseWheel", function(_, delta)
		local mini, maxi = barre:GetMinMaxValues()
		barre:SetValue(math.max(mini, math.min(maxi, barre:GetValue() - delta * d.pas_molette)))
	end)
	sf:SetScript("OnSizeChanged", function(_, largeur) contenu:SetWidth(largeur) end)
	local z = { sf = sf, contenu = contenu, barre = barre }
	-- hauteur totale du contenu : règle la portée de la barre
	function z.hauteur(total)
		contenu:SetHeight(math.max(total, 1))
		local portee = math.max(0, total - sf:GetHeight())
		barre:SetMinMaxValues(0, portee)
		if barre:GetValue() > portee then barre:SetValue(portee) end
		if portee > 0 then barre:Show() else barre:Hide() end
	end
	function z.haut() barre:SetValue(0) end
	return z
end
V.defilement = defilement

------------------------------------------------------------------ construction
function V.construire()
	local d = ui()
	local F = ns.Fenetre

	-- colonne des catégories
	local pc = F.panneauCats
	V.cats = defilement(pc)
	V.cats.sf:SetPoint("TOPLEFT", pc, "TOPLEFT", 4, -4)
	V.cats.sf:SetPoint("BOTTOMRIGHT", pc, "BOTTOMRIGHT", -(d.largeur_barre + 4), 4)
	V.cats.barre:SetPoint("TOPRIGHT", pc, "TOPRIGHT", -3, -4)
	V.cats.barre:SetPoint("BOTTOMRIGHT", pc, "BOTTOMRIGHT", -3, 4)

	-- liste : bandeau (case de la catégorie, nom, compteur) puis zone qui défile
	local pl = F.panneauListe
	V.barre = ns.Barre.construire(pl)
	V.bandeau = CreateFrame("Frame", nil, pl)
	V.bandeau:SetHeight(d.hauteur_bandeau)
	V.bandeau:SetPoint("TOPLEFT", V.barre, "BOTTOMLEFT", 0, -d.liste.ecart)
	V.bandeau:SetPoint("TOPRIGHT", V.barre, "BOTTOMRIGHT", 0, -d.liste.ecart)
	-- boutons pour replier la colonne des catégories (à gauche) et celle de la fiche (à droite)
	local function repli(cote, chemin, ouvrir, fermer)
		-- flèches des pages du grimoire du jeu (repli : texte « » si l'image manque)
		local b = CreateFrame("Button", nil, V.bandeau)
		b:SetSize(d.replier.taille, d.replier.taille)
		b:SetPoint(cote, V.bandeau, cote, 0, 0)
		b:SetHighlightTexture(d.replier.survol, "ADD")
		b.repli = S.texte(b, "entete")
		b.repli:SetPoint("CENTER", b, "CENTER", 0, 0)
		function b:Fleche(vers)
			local R = ui().replier
			self:SetNormalTexture(R["fleche_" .. vers])
			self:SetPushedTexture(R["fleche_" .. vers .. "_appui"])
			local ok = self:GetNormalTexture() and self:GetNormalTexture():GetTexture()
			self.repli:SetText(ok and "" or R[vers])
			S.couleurTexte(self.repli, "dore_clair")
		end
		b:SetScript("OnClick", function()
			ns.Options.definir(chemin, not ns.Reglages.lire(chemin), "disposer")
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(ns.T(ns.Reglages.lire(chemin) and ouvrir or fermer))
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		return b
	end
	V.replierCats = repli("LEFT", "fenetre.cats_repliee", "fenetre.deplier_cats", "fenetre.replier_cats")
	V.replierFiche = repli("RIGHT", "fenetre.fiche_repliee", "fenetre.deplier_fiche", "fenetre.replier_fiche")
	V.caseCategorie = S.case(V.bandeau)
	V.caseCategorie:SetPoint("LEFT", V.replierCats, "RIGHT", 2, 0)
	V.caseCategorie:SetScript("OnClick", function()
		M.basculerCategorie(V.categorieActive())
		F.rafraichir()
	end)
	V.nomCategorie = S.texte(V.bandeau, "titre")
	V.nomCategorie:SetPoint("LEFT", V.caseCategorie, "RIGHT", 6, 0)
	V.compteur = S.texte(V.bandeau, "normal")
	V.compteur:SetPoint("RIGHT", V.replierFiche, "LEFT", -6, 0)
	local filet = V.bandeau:CreateTexture(nil, "ARTWORK")
	filet:SetPoint("BOTTOMLEFT", V.bandeau, "BOTTOMLEFT", 0, 0)
	filet:SetPoint("BOTTOMRIGHT", V.bandeau, "BOTTOMRIGHT", 0, 0)
	filet:SetHeight(1)
	S.aplat(filet, "dore_sombre")
	V.liste = defilement(pl)
	V.liste.sf:SetPoint("TOPLEFT", V.bandeau, "BOTTOMLEFT", 0, -2)
	V.liste.sf:SetPoint("BOTTOMRIGHT", pl, "BOTTOMRIGHT", -(d.largeur_barre + 4), 4)
	V.liste.barre:SetPoint("TOPRIGHT", V.bandeau, "BOTTOMRIGHT", 0, -2)
	V.liste.barre:SetPoint("BOTTOMRIGHT", pl, "BOTTOMRIGHT", -3, 4)
	V.vide = S.texte(V.liste.sf, "normal")
	V.vide:SetPoint("TOP", V.liste.sf, "TOP", 0, -20)

	V.construireFiche(F.panneauFiche)
	V.pret = true
end

-- La fiche (parchemin) est construite par Fiche\Parchemin.lua.
function V.construireFiche(panneau)
	ns.Parchemin.construire(panneau)
end

------------------------------------------------------------------ colonne des catégories
local function creerLigneCategorie(i)
	local d = ui()
	local l = CreateFrame("Button", nil, V.cats.contenu)
	l:SetHeight(d.hauteur_ligne_categorie)
	l:SetPoint("TOPLEFT", V.cats.contenu, "TOPLEFT", 0, -(i - 1) * d.hauteur_ligne_categorie)
	l:SetPoint("TOPRIGHT", V.cats.contenu, "TOPRIGHT", 0, -(i - 1) * d.hauteur_ligne_categorie)
	l.fond = l:CreateTexture(nil, "BACKGROUND")
	l.fond:SetAllPoints(l)
	l.barre = l:CreateTexture(nil, "ARTWORK")
	l.barre:SetPoint("TOPLEFT", l, "TOPLEFT", 0, 0)
	l.barre:SetPoint("BOTTOMLEFT", l, "BOTTOMLEFT", 0, 0)
	l.barre:SetWidth(3)
	l.nom = S.texte(l, "normal")
	l.nom:SetPoint("LEFT", l, "LEFT", 10, 0)
	l.nom:SetPoint("RIGHT", l, "RIGHT", -34, 0)
	l.nom:SetJustifyH("LEFT")
	l.nombre = S.texte(l, "petit")
	l.nombre:SetPoint("RIGHT", l, "RIGHT", -8, 0)
	l:SetScript("OnClick", function(self)
		V.choisirCategorie(self.id)
	end)
	l:SetScript("OnEnter", function(self) self.survol = true V.coloriserCategorie(self) end)
	l:SetScript("OnLeave", function(self) self.survol = false V.coloriserCategorie(self) end)
	return l
end

function V.coloriserCategorie(l)
	if not l.id then return end
	local choisie = (l.id == V.categorieActive())
	local r, g, b, a = S.couleur("lueur")
	if choisie then
		S.colorier(l.fond, "lueur", math.min(1, a * 2.5))
		S.colorier(l.barre, "dore")
	else
		S.colorier(l.fond, "lueur", l.survol and a or 0)
		S.colorier(l.barre, "lueur", 0)
	end
	l.nom:SetTextColor(S.couleur(choisie and "dore_clair" or "texte_doux"))
	l.nombre:SetTextColor(S.couleur("texte_eteint"))
end

function V.choisirCategorie(id)
	ns.Fenetre.memoire().categorie = id
	V.liste.haut()
	ns.Fenetre.rafraichir()
end

function V.rafraichirCategories()
	local d = ui()
	local cats = M.categories()
	for i, c in ipairs(cats) do
		local l = V.lignesCat[i]
		if not l then
			l = creerLigneCategorie(i)
			V.lignesCat[i] = l
		end
		l.id = c.id
		l.nom:SetText(c.nom)
		l.nombre:SetText(tostring(c.n))
		l:Show()
		V.coloriserCategorie(l)
	end
	for i = #cats + 1, #V.lignesCat do
		V.lignesCat[i].id = nil
		V.lignesCat[i]:Hide()
	end
	V.cats.hauteur(#cats * d.hauteur_ligne_categorie)
end

------------------------------------------------------------------ liste des add-ons
local function poserIcone(texture, e)
	local ic = C_AddOns.GetAddOnMetadata(e.nom, "IconTexture") or (e.fiche and e.fiche.icone)
	if ic and ic ~= "" then
		texture:SetTexture(tonumber(ic) or ic)
		if texture:GetTexture() then return end
	end
	texture:SetTexture(ui().textures.icone_defaut)
end

local function creerLigne(i)
	local d = ui()
	local l = CreateFrame("Button", nil, V.liste.contenu)
	l:SetHeight(d.hauteur_ligne)
	l.fond = l:CreateTexture(nil, "BACKGROUND")
	l.fond:SetAllPoints(l)

	l.fleche = CreateFrame("Button", nil, l)
	l.fleche:SetSize(d.largeur_fleche, d.largeur_fleche)
	l.fleche:SetScript("OnClick", function(self)
		local e = self:GetParent().entree
		V.deplie[e.nom] = not V.estDeplie(e.nom)
		V.rafraichirListe()
	end)

	l.etoile = CreateFrame("Button", nil, l)
	l.etoile:SetSize(d.liste.etoile.taille, d.liste.etoile.taille)
	l.etoile.image = l.etoile:CreateTexture(nil, "ARTWORK")
	l.etoile.image:SetAllPoints(l.etoile)
	l.etoile.image:SetTexture(d.liste.etoile.image)
	l.etoile:SetScript("OnClick", function(self)
		local e = self:GetParent().entree
		if not e then return end
		ns.Recherche.basculerFavori(e.nom)
		ns.Fenetre.rafraichir()
	end)

	l.case = S.case(l)
	l.case:SetScript("OnClick", function(self)
		local e = self:GetParent().entree
		local coche = self:GetChecked() and true or false
		if coche and ns.Actions and ns.Actions.majClic() then
			ns.Actions.activerComplet(e.nom)
		else
			M.basculer(e.nom, coche)
		end
		ns.Fenetre.rafraichir()
	end)

	l.icone = l:CreateTexture(nil, "ARTWORK")
	l.icone:SetSize(d.taille_icone, d.taille_icone)
	l.icone:SetPoint("LEFT", l.case, "RIGHT", 4, 0)

	l.point = l:CreateTexture(nil, "OVERLAY")
	l.point:SetSize(8, 8)
	l.point:SetPoint("RIGHT", l, "RIGHT", -8, 0)

	l.marque = S.texte(l, "petit")
	l.marque:SetPoint("RIGHT", l.point, "LEFT", -6, 0)
	l.marque:SetJustifyH("RIGHT")

	l.badges = S.texte(l, "petit")
	l.badges:SetPoint("RIGHT", l.marque, "LEFT", -6, 0)
	l.badges:SetJustifyH("RIGHT")

	l.nom = S.texte(l, "normal")
	l.nom:SetPoint("LEFT", l.icone, "RIGHT", 6, 0)
	l.nom:SetPoint("RIGHT", l.badges, "LEFT", -6, 0)
	l.nom:SetJustifyH("LEFT")

	l:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	l:SetScript("OnClick", function(self, bouton)
		if bouton == "RightButton" then return ns.Menu.ouvrir(self) end
		V.selection = self.entree.nom
		ns.Recherche.reconnaitre(self.entree.nom)
		V.rafraichirFiche()
		V.rafraichirListe()
		ns.Barre.rafraichir()
	end)
	l:SetScript("OnEnter", function(self)
		self.survol = true
		V.coloriserLigne(self)
		ns.Infobulle.montrer(self, self.entree)
		V.completerInfobulle(self, self.entree)
	end)
	l:SetScript("OnLeave", function(self)
		self.survol = false
		V.coloriserLigne(self)
		ns.Infobulle.cacher(self)
	end)
	l:SetScript("OnHide", function(self) ns.Infobulle.cacher(self) end)
	return l
end

function V.coloriserLigne(l)
	local e = l.entree
	if not e then return end
	local actif = M.actif(e.nom)
	local _, _, _, a = S.couleur("lueur")
	if V.selection == e.nom then
		S.colorier(l.fond, "lueur", math.min(1, a * 2.5))
	else
		S.colorier(l.fond, "lueur", l.survol and a or 0)
	end
	local gris = e.inutile or not actif
	l.nom:SetTextColor(S.couleur(gris and "texte_eteint" or "dore_clair"))
	l.marque:SetTextColor(S.couleur(e.inutile and "texte_eteint" or "texte_doux"))
	l.icone:SetAlpha(gris and 0.45 or 1)
	if M.modifie(e.nom) then
		S.colorier(l.point, "dore_clair", 1)
		l.point:Show()
	else
		l.point:Hide()
	end
end

-- Texte de la marque à droite d'une ligne : ce gestionnaire, non prévu pour Forever, nombre de modules,
-- sinon la raison en clair (seulement si elle est utile, sauf si `liste.colonnes.etat_charge`) et la mémoire.
local function texteMarque(e, niveau, ctx)
	if e.moi then return ns.T("liste.moi") end
	if e.inutile then return ns.T("liste.inutile") end
	if niveau == 0 and #e.modules > 0 and not V.estDeplie(e.nom) and not (ctx and ctx.actif) then
		return ns.T("liste.modules", #e.modules)
	end
	local morceaux = {}
	if ns.Reglages.lire("liste.colonnes.raison") then
		local r = ns.Recherche.raison(e)
		if not ns.Recherche.ordinaire(r.id) or ns.Reglages.lire("liste.colonnes.etat_charge") then
			morceaux[#morceaux + 1] = r.texte
		end
	end
	if ns.Reglages.lire("liste.colonnes.memoire") and C_AddOns.IsAddOnLoaded(e.nom) then
		morceaux[#morceaux + 1] = ns.FicheModele.memoire(e.nom)
	end
	return table.concat(morceaux, ui().separateur_info)
end

-- Badges d'une ligne, en couleur (au plus `liste.badges_max`).
local function texteBadges(e)
	if not ns.Reglages.lire("liste.colonnes.badges") then return "" end
	local L, max = ui().liste, ns.Reglages.lire("liste.badges_max")
	local morceaux = {}
	for _, id in ipairs(ns.Recherche.badges(e)) do
		if #morceaux < max and not (id == "inutile" and e.inutile) then
			local r, g, b = S.hex(L.badge_couleurs[id])
			morceaux[#morceaux + 1] = string.format("|cff%02x%02x%02x%s|r",
				math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), ns.T("badge.court." .. id))
		end
	end
	return table.concat(morceaux, L.separateur_badges)
end
V.texteBadges = texteBadges

local function remplirLigne(l, item, ctx)
	local d = ui()
	local e, niveau = item.e, item.niveau
	l.entree = e
	l.niveau = niveau
	local x = d.marge_ligne + niveau * d.retrait_module
	l.fleche:ClearAllPoints()
	l.fleche:SetPoint("LEFT", l, "LEFT", x, 0)
	if niveau == 0 and #e.modules > 0 then
		local deplie = V.estDeplie(e.nom)
		l.fleche:SetNormalTexture(deplie and d.textures.moins or d.textures.plus)
		l.fleche:Show()
	else
		l.fleche:Hide()
	end
	l.case:ClearAllPoints()
	l.case:SetPoint("LEFT", l, "LEFT", x + d.largeur_fleche + 2, 0)
	l.case:SetChecked(M.actif(e.nom))
	if e.moi then l.case:Disable() else l.case:Enable() end
	-- étoile des favoris et icône : chacune peut être coupée dans les options
	local suite = l.case
	l.etoile:ClearAllPoints()
	if ns.Reglages.lire("liste.colonnes.etoile") then
		l.etoile:SetPoint("LEFT", l.case, "RIGHT", 2, 0)
		l.etoile.image:SetAlpha(ns.Recherche.favori(e.nom) and 1 or d.liste.etoile.alpha_vide)
		l.etoile:Show()
		suite = l.etoile
	else
		l.etoile:Hide()
	end
	l.icone:ClearAllPoints()
	l.icone:SetPoint("LEFT", suite, "RIGHT", 4, 0)
	l.nom:ClearAllPoints()
	if ns.Reglages.lire("liste.colonnes.icone") then
		poserIcone(l.icone, e)
		l.icone:Show()
		l.nom:SetPoint("LEFT", l.icone, "RIGHT", 6, 0)
	else
		l.icone:Hide()
		l.nom:SetPoint("LEFT", suite, "RIGHT", 6, 0)
	end
	l.nom:SetPoint("RIGHT", l.badges, "LEFT", -6, 0)
	l.nom:SetText(e.titre)
	l.badges:SetText(texteBadges(e))
	l.marque:SetText(texteMarque(e, niveau, ctx))
	l:Show()
	V.coloriserLigne(l)
end

-- Lignes à montrer : recherche et filtre rapide d'abord (dans toutes les catégories si le réglage le veut),
-- ordre choisi (favoris et nouveaux en haut), et sous chaque principal ses modules (tous si dépliés, sinon ceux qui correspondent).
function V.aplatir(ctx)
	local R = ns.Recherche
	ctx = ctx or R.contexte()
	local id = V.categorieActive()
	local partout = ctx.cherche and ns.Reglages.lire("liste.recherche.toutes_categories")
	local trouves = {}
	for _, e in ipairs(M.lesRacines()) do
		if partout or id == ui().categorie_tous or e.categorie == id then
			local propre = R.evaluer(ctx, e)
			local mods, meilleur = {}, propre or 0
			for _, m in ipairs(e.modules) do
				local sm = R.evaluer(ctx, m)
				if sm then
					mods[#mods + 1] = m
					if sm > meilleur then meilleur = sm end
				end
			end
			if propre or #mods > 0 then trouves[#trouves + 1] = { e = e, score = meilleur, mods = mods } end
		end
	end
	R.ordonner(trouves, ctx)
	local lignes = {}
	local function ajouter(it)
		lignes[#lignes + 1] = { e = it.e, niveau = 0 }
		if #it.e.modules > 0 then
			if ctx.actif then
				for _, m in ipairs(it.mods) do lignes[#lignes + 1] = { e = m, niveau = 1 } end
			elseif V.estDeplie(it.e.nom) then
				for _, m in ipairs(it.e.modules) do lignes[#lignes + 1] = { e = m, niveau = 1 } end
			end
		end
	end
	if V.groupe(ctx) then
		-- « Tous les add-ons » rangé par catégories : un en-tête repliable par catégorie, dans l'ordre de la colonne
		local paquets = {}
		for _, it in ipairs(trouves) do
			local c = it.e.categorie
			paquets[c] = paquets[c] or {}
			table.insert(paquets[c], it)
		end
		for _, c in ipairs(M.categories()) do
			local p = paquets[c.id]
			if c.id ~= ui().categorie_tous and p then
				lignes[#lignes + 1] = { entete = c.id, nom = c.nom }
				if not V.estReplie(c.id) then
					for _, it in ipairs(p) do ajouter(it) end
				end
			end
		end
	else
		for _, it in ipairs(trouves) do ajouter(it) end
	end
	return lignes, ctx
end

-- Regroupe-t-on la liste par catégories ? Seulement dans « Tous les add-ons », hors recherche, si le réglage le veut.
function V.groupe(ctx)
	return ns.Reglages.lire("liste.grouper_tous") and V.categorieActive() == ui().categorie_tous and not ctx.cherche
end

------------------------------------------------------------------ en-têtes de catégorie
local function creerEntete()
	local d, E = ui(), ui().liste.entete
	local h = CreateFrame("Button", nil, V.liste.contenu)
	h:SetHeight(E.hauteur)
	h.fond = h:CreateTexture(nil, "BACKGROUND")
	h.fond:SetAllPoints(h)
	h.filet = h:CreateTexture(nil, "ARTWORK")
	h.filet:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 0, 0)
	h.filet:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", 0, 0)
	h.filet:SetHeight(1)
	h.fleche = h:CreateTexture(nil, "ARTWORK")
	h.fleche:SetSize(E.taille_fleche, E.taille_fleche)
	h.fleche:SetPoint("LEFT", h, "LEFT", E.marge, 0)
	h.case = S.case(h)
	h.case:SetPoint("LEFT", h.fleche, "RIGHT", 4, 0)
	h.case:SetScript("OnClick", function(self)
		M.basculerCategorie(self:GetParent().id)
		ns.Fenetre.rafraichir()
	end)
	h.nom = S.texte(h, "entete")
	h.nom:SetPoint("LEFT", h.case, "RIGHT", 6, 0)
	h.compteur = S.texte(h, "petit")
	h.compteur:SetPoint("RIGHT", h, "RIGHT", -8, 0)
	h:SetScript("OnClick", function(self)
		V.replie[self.id] = not V.estReplie(self.id)
		V.rafraichirListe()
	end)
	h:SetScript("OnEnter", function(self)
		self.survol = true
		V.coloriserEntete(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(ns.T("liste.entete_aide"))
		GameTooltip:Show()
	end)
	h:SetScript("OnLeave", function(self)
		self.survol = false
		V.coloriserEntete(self)
		GameTooltip:Hide()
	end)
	return h
end

function V.coloriserEntete(h)
	if not h.id then return end
	local _, _, _, a = S.couleur("lueur")
	S.colorier(h.fond, "lueur", h.survol and math.min(1, a * 2) or ui().liste.entete.alpha_fond)
	S.colorier(h.filet, "dore_sombre")
	h.nom:SetTextColor(S.couleur("dore_clair"))
	h.compteur:SetTextColor(S.couleur("texte_doux"))
end

local function remplirEntete(h, item)
	local d = ui()
	h.id = item.entete
	h.fleche:SetTexture(V.estReplie(item.entete) and d.textures.plus or d.textures.moins)
	h.case:SetChecked(M.categorieToutActive(item.entete))
	h.nom:SetText(item.nom)
	h.compteur:SetText(ns.T("liste.actifs", M.etatCategorie(item.entete)))
	h:Show()
	V.coloriserEntete(h)
end

-- Complète l'infobulle d'une ligne : raison en clair, badges, étiquettes (seulement si l'infobulle est affichée).
function V.completerInfobulle(ligne, e)
	if not e or not ns.Infobulle.proprietaire or ns.Infobulle.proprietaire ~= ligne then return end
	local R = ns.Recherche
	local function ajouter(texte, couleur)
		local r, g, b = S.couleur(couleur)
		GameTooltip:AddLine(texte, r, g, b, true)
	end
	ajouter(ns.T("infobulle.raison", R.raison(e).texte), "texte_doux")
	local ids = R.badges(e)
	if #ids > 0 then
		local noms = {}
		for _, id in ipairs(ids) do noms[#noms + 1] = ns.T("badge.court." .. id) end
		ajouter(ns.T("infobulle.badges", table.concat(noms, ui().liste.separateur_liste)), "dore_clair")
	end
	local etiquettes = R.etiquettes(e.nom)
	if #etiquettes > 0 then
		ajouter(ns.T("infobulle.etiquettes", table.concat(etiquettes, ui().liste.separateur_liste)), "dore")
	end
	GameTooltip:Show()
end

function V.rafraichirListe()
	local d = ui()
	local id = V.categorieActive()
	local lignes, ctx = V.aplatir()
	local E = d.liste.entete
	local y, nl, ne = 0, 0, 0
	local function poser(cadre)
		cadre:ClearAllPoints()
		cadre:SetPoint("TOPLEFT", V.liste.contenu, "TOPLEFT", 0, -y)
		cadre:SetPoint("TOPRIGHT", V.liste.contenu, "TOPRIGHT", 0, -y)
	end
	local nAddons = 0
	for _, item in ipairs(lignes) do
		if item.entete then
			ne = ne + 1
			local h = V.entetes[ne]
			if not h then
				h = creerEntete()
				V.entetes[ne] = h
			end
			if ne > 1 then y = y + E.ecart_haut end
			poser(h)
			remplirEntete(h, item)
			y = y + E.hauteur
		else
			nl = nl + 1
			nAddons = nAddons + 1
			local l = V.lignes[nl]
			if not l then
				l = creerLigne(nl)
				V.lignes[nl] = l
			end
			poser(l)
			remplirLigne(l, item, ctx)
			y = y + d.hauteur_ligne
		end
	end
	for i = nl + 1, #V.lignes do
		V.lignes[i].entree = nil
		V.lignes[i]:Hide()
	end
	for i = ne + 1, #V.entetes do
		V.entetes[i].id = nil
		V.entetes[i]:Hide()
	end
	V.liste.hauteur(y)
	if #lignes == 0 then
		V.vide:SetText(ns.T(ctx.actif and "liste.aucun_resultat" or "liste.vide"))
		V.vide:Show()
	else
		V.vide:Hide()
	end
	-- bandeau : nom de la catégorie, case (pas pour « Tous »), compteur
	local resultats = ctx.cherche and ns.Reglages.lire("liste.recherche.toutes_categories")
	local actifs, total = M.etatCategorie(id)
	if resultats then
		V.nomCategorie:SetText(ns.T("liste.resultats", #lignes))
		V.compteur:SetText("")
	else
		V.nomCategorie:SetText(M.nomCategorie(id))
		V.compteur:SetText(ns.T("liste.actifs", actifs, total))
	end
	if ns.Diag and ns.Diag.tracer then
		-- mesure tout de suite, puis une image plus tard (le jeu place les cadres entre deux images)
		ns.Diag.tracer("liste")
		if C_Timer and ns.Reglages.compte and ns.Reglages.compte.trace_actif then
			C_Timer.After(0, function() ns.Diag.tracer("liste+1") end)
		end
	end
	if id == d.categorie_tous or resultats then
		V.caseCategorie:Hide()
		V.nomCategorie:ClearAllPoints()
		V.nomCategorie:SetPoint("LEFT", V.replierCats, "RIGHT", 6, 0)
	else
		V.caseCategorie:Show()
		V.caseCategorie:SetChecked(M.categorieToutActive(id))
		V.nomCategorie:ClearAllPoints()
		V.nomCategorie:SetPoint("LEFT", V.caseCategorie, "RIGHT", 6, 0)
	end
end

------------------------------------------------------------------ fiche
function V.rafraichirFiche()
	ns.Parchemin.rafraichir(V.selection)
end

-- Couleurs qui dépendent de l'état : repeintes à chaque changement de thème.
function V.coloriser()
	for _, l in ipairs(V.lignesCat) do V.coloriserCategorie(l) end
	for _, l in ipairs(V.lignes) do V.coloriserLigne(l) end
	for _, h in ipairs(V.entetes) do V.coloriserEntete(h) end
	S.couleurTexte(V.nomCategorie, "dore_clair")
	S.couleurTexte(V.compteur, "texte_doux")
	S.couleurTexte(V.vide, "texte_eteint")
	V.rafraichirFiche()
end

-- Flèches des boutons de repli (« replie, » déplie à gauche ; l'inverse à droite) ; cachés en version mini.
function V.majReplis()
	local mini = ns.Fenetre.mode() == "mini"
	local c, f = ns.Reglages.lire("fenetre.cats_repliee"), ns.Reglages.lire("fenetre.fiche_repliee")
	V.replierCats:Fleche(c and "droite" or "gauche")
	V.replierFiche:Fleche(f and "gauche" or "droite")
	V.replierCats:SetShown(not mini)
	V.replierFiche:SetShown(not mini)
end

function V.rafraichir()
	if not V.pret then return end
	V.majReplis()
	V.rafraichirCategories()
	ns.Barre.rafraichir()
	V.rafraichirListe()
	V.coloriser()
end
