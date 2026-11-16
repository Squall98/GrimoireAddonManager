-- Fenêtre des erreurs, à nous et en français (ou anglais) : liste à gauche, détail complet à droite,
-- boutons « Copier » (l'erreur choisie), « Copier tout » et « Effacer ». Mémoire totale en bas.
-- Tailles et couleurs : ns.donnees.reglages.interface.erreurs ; textes : ns.T("erreurs.*").
local _, ns = ...
local W = {}
ns.ErreursFenetre = W

local S = ns.Style
local E = ns.Erreurs
local function ui() return ns.donnees.reglages.interface end
local function cfg() return ui().erreurs end
local function lire(chemin) return ns.Reglages.lire("erreurs." .. chemin) end

W.filtre = nil    -- add-on affiché seul (clé de E.cle) ; nil = tous
W.page = 1
W.selection = nil -- id de l'erreur choisie
W.lignes = {}     -- boutons de la liste

local function teinte(cle) return "|cff" .. cfg()[cle] .. "%s|r" end

------------------------------------------------------------------ contenu
local function visibles() return E.liste(W.filtre) end

local function nombrePages(total)
	return math.max(1, math.ceil(total / lire("lignes_liste")))
end

function W.rafraichir()
	local f = W.cadre
	if not f or not f:IsShown() then return end
	local liste = visibles()
	local par = lire("lignes_liste")
	W.page = math.max(1, math.min(W.page, nombrePages(#liste)))
	-- résumé
	if W.filtre then
		W.resume:SetText(ns.T("erreurs.resume_filtre", #liste, E.nombre(W.filtre), E.nomAffiche(W.filtre ~= cfg().inconnu and W.filtre or nil)))
		W.boutonFiltre:Texte(ns.T("erreurs.filtre_un", E.nomAffiche(W.filtre ~= cfg().inconnu and W.filtre or nil)))
	else
		W.resume:SetText(#liste == 0 and ns.T("erreurs.aucune")
			or ns.T("erreurs.resume", #liste, E.nombre(), #E.addons()))
		W.boutonFiltre:Texte(ns.T("erreurs.filtre_tous"))
	end
	-- l'erreur choisie existe-t-elle encore ? sinon la première de la liste
	local choisie = W.selection and E.parId(W.selection)
	if choisie and W.filtre and E.cle(choisie.addon) ~= W.filtre then choisie = nil end
	if not choisie then
		choisie = liste[1]
		W.selection = choisie and choisie.id or nil
	end
	-- lignes de la page
	for i = 1, math.max(par, #W.lignes) do
		local b = W.lignes[i]
		if not b and i <= par then b = W.creerLigne(i) end
		if b then
			local e = i <= par and liste[(W.page - 1) * par + i] or nil
			b.erreur = e
			if e then
				local texte = ns.T("erreurs.ligne", E.nomAffiche(e.addon), e.n or 1, E.court(e.message))
				if e == choisie then texte = string.format(teinte("couleur_nombre"), texte) end
				b.texte:SetText(texte)
				b:Show()
			else
				b.texte:SetText("")
				b:Hide()
			end
			if b.fondSelection then
				if e and e == choisie then b.fondSelection:Show() else b.fondSelection:Hide() end
			end
		end
	end
	W.pageTexte:SetText(ns.T("erreurs.page", W.page, nombrePages(#liste)))
	W.boutonPrecedent:Activer(W.page > 1)
	W.boutonSuivant:Activer(W.page < nombrePages(#liste))
	W.boutonCopier:Activer(choisie ~= nil)
	W.boutonCopierTout:Activer(#liste > 0)
	W.boutonEffacer:Activer(#liste > 0)
	-- détail
	W.montrerDetail(choisie and E.texte(choisie) or ns.T("erreurs.choisir"))
	W.aide:SetText("")
end

function W.montrerDetail(texte)
	W.texteDetail = texte
	W.detail:SetText(texte)
	local m = 4
	W.mesure:SetWidth(math.max((tonumber(W.defile:GetWidth()) or 0) - 2 * m, 1))
	W.mesure:SetText(texte .. " ")
	local h = tonumber(W.mesure:GetStringHeight()) or 0
	W.detail:SetHeight(math.max(tonumber(W.defile:GetHeight()) or 0, h + 2 * m))
	W.barre.hauteur(W.detail:GetHeight())
	W.barre.haut()
end

function W.memoire()
	local _, total = ns.Sante.memoire()
	W.memoireTexte:SetText(ns.T("erreurs.memoire_ligne", ns.Sante.formaterKo(total)))
end

------------------------------------------------------------------ actions
function W.choisir(id)
	W.selection = id
	W.rafraichir()
end

function W.filtreSuivant()
	local liste = E.addons()
	if #liste == 0 then W.filtre = nil return W.rafraichir() end
	if not W.filtre then
		W.filtre = liste[1].addon
	else
		local suivant
		for i, a in ipairs(liste) do if a.addon == W.filtre then suivant = liste[i + 1] end end
		W.filtre = suivant and suivant.addon or nil
	end
	W.page = 1
	W.selection = nil
	W.rafraichir()
end

function W.definirFiltre(addon)
	W.filtre = addon
	W.page = 1
	W.selection = nil
	W.rafraichir()
end

-- Met le texte à copier dans le champ de détail, sélectionné : il ne reste qu'à faire Ctrl+C.
function W.copier(tout)
	local texte
	if tout then
		texte = E.texteTout(W.filtre)
	else
		local e = W.selection and E.parId(W.selection)
		texte = e and E.texte(e)
	end
	if not texte or texte == "" then return end
	W.montrerDetail(texte)
	W.detail:SetFocus()
	W.detail:HighlightText()
	W.aide:SetText(ns.T("erreurs.copie_aide"))
	W.dernierCopie = texte
end

function W.effacer()
	local n = E.effacer(W.filtre)
	if W.filtre then
		ns.dire(ns.T("erreurs.efface_addon", E.nomAffiche(W.filtre ~= cfg().inconnu and W.filtre or nil), n))
	else
		ns.dire(ns.T("erreurs.efface", n))
	end
	ns.ErreursFenetre.filtre = nil
	W.selection = nil
	W.rafraichir()
end

------------------------------------------------------------------ construction
function W.creerLigne(i)
	local d = cfg()
	local b = CreateFrame("Button", nil, W.panneauListe)
	b:SetHeight(d.hauteur_ligne)
	b:SetPoint("TOPLEFT", W.panneauListe, "TOPLEFT", 4, -4 - (i - 1) * d.hauteur_ligne)
	b:SetPoint("TOPRIGHT", W.panneauListe, "TOPRIGHT", -4, -4 - (i - 1) * d.hauteur_ligne)
	b.fondSelection = b:CreateTexture(nil, "BACKGROUND")
	b.fondSelection:SetAllPoints(b)
	S.aplat(b.fondSelection, "accent", 0.6)
	b.fondSelection:Hide()
	local survol = b:CreateTexture(nil, "HIGHLIGHT")
	survol:SetAllPoints(b)
	S.aplat(survol, "lueur", 0.25)
	b.texte = S.texte(b, "normal")
	b.texte:SetPoint("LEFT", b, "LEFT", 4, 0)
	b.texte:SetPoint("RIGHT", b, "RIGHT", -4, 0)
	b.texte:SetJustifyH("LEFT")
	b.texte:SetWordWrap(false)
	S.peindre(function() b.texte:SetTextColor(S.couleur("texte")) end)
	b:SetScript("OnClick", function(self) if self.erreur then W.choisir(self.erreur.id) end end)
	W.lignes[i] = b
	return b
end

local function bouton(parent, cle, action)
	local d = cfg()
	local b = S.bouton(parent, d.largeur_bouton, d.hauteur_bouton)
	b:Texte(ns.T(cle))
	b:SetScript("OnClick", action)
	return b
end

function W.construire()
	if W.cadre then return W.cadre end
	local d = cfg()
	local f = S.creerCadre("Frame", d.nom_cadre, UIParent)
	W.cadre = f
	f:SetSize(d.largeur, d.hauteur)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata(ui().strate)
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	S.fond(f, "fenetre")
	table.insert(UISpecialFrames, d.nom_cadre)

	local m, ecart = d.marge, d.ecart
	W.titre = S.texte(f, "titre")
	W.titre:SetPoint("TOPLEFT", f, "TOPLEFT", m + 6, -m - 4)
	W.titre:SetText(ns.T("erreurs.titre"))
	S.peindre(function() W.titre:SetTextColor(S.couleur("dore_clair")) end)

	local fermer = S.bouton(f, d.hauteur_bouton, d.hauteur_bouton)
	fermer:Texte(ns.T("erreurs.bouton.fermer"))
	fermer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -m, -m)
	fermer:SetScript("OnClick", function() W.fermer() end)

	W.resume = S.texte(f, "sous_titre")
	W.resume:SetPoint("TOPLEFT", f, "TOPLEFT", m + 6, -m - d.hauteur_titre - 2)
	W.resume:SetJustifyH("LEFT")
	S.peindre(function() W.resume:SetTextColor(S.couleur("texte_doux")) end)

	local haut = m + d.hauteur_titre + d.hauteur_bandeau + ecart

	-- colonne de gauche : filtre, liste, pages
	W.boutonFiltre = S.bouton(f, d.largeur_liste, d.hauteur_bouton)
	W.boutonFiltre:SetPoint("TOPLEFT", f, "TOPLEFT", m, -haut)
	W.boutonFiltre:SetScript("OnClick", function() W.filtreSuivant() end)

	W.panneauListe = S.creerCadre("Frame", nil, f)
	W.panneauListe:SetPoint("TOPLEFT", W.boutonFiltre, "BOTTOMLEFT", 0, -ecart)
	W.panneauListe:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", m + d.largeur_liste, m + d.hauteur_bouton + d.hauteur_bandeau + ecart * 3)
	S.fond(W.panneauListe, "panneau")

	W.boutonPrecedent = S.bouton(f, d.largeur_bouton, d.hauteur_bouton)
	W.boutonPrecedent:Texte(ns.T("erreurs.bouton.precedent"))
	W.boutonPrecedent:SetPoint("TOPLEFT", W.panneauListe, "BOTTOMLEFT", 0, -ecart)
	W.boutonPrecedent:SetScript("OnClick", function() W.page = W.page - 1 W.rafraichir() end)
	W.boutonSuivant = S.bouton(f, d.largeur_bouton, d.hauteur_bouton)
	W.boutonSuivant:Texte(ns.T("erreurs.bouton.suivant"))
	W.boutonSuivant:SetPoint("TOPRIGHT", W.panneauListe, "BOTTOMRIGHT", 0, -ecart)
	W.boutonSuivant:SetScript("OnClick", function() W.page = W.page + 1 W.rafraichir() end)
	W.pageTexte = S.texte(f, "normal")
	W.pageTexte:SetPoint("LEFT", W.boutonPrecedent, "RIGHT", ecart, 0)
	W.pageTexte:SetPoint("RIGHT", W.boutonSuivant, "LEFT", -ecart, 0)
	W.pageTexte:SetJustifyH("CENTER")
	S.peindre(function() W.pageTexte:SetTextColor(S.couleur("texte")) end)

	W.memoireTexte = S.texte(f, "petit")
	W.memoireTexte:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", m + 6, m)
	W.memoireTexte:SetJustifyH("LEFT")
	S.peindre(function() W.memoireTexte:SetTextColor(S.couleur("texte_doux")) end)

	-- colonne de droite : détail qui défile, boutons
	local panneau = S.creerCadre("Frame", nil, f)
	panneau:SetPoint("TOPLEFT", W.boutonFiltre, "TOPRIGHT", ecart, 0)
	panneau:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -m, m + d.hauteur_bouton + d.hauteur_bandeau + ecart * 2)
	S.fond(panneau, "parchemin")
	W.panneauDetail = panneau

	W.defile = CreateFrame("ScrollFrame", nil, panneau)
	W.defile:SetPoint("TOPLEFT", panneau, "TOPLEFT", 6, -6)
	W.defile:SetPoint("BOTTOMRIGHT", panneau, "BOTTOMRIGHT", -6 - d.largeur_barre, 6)
	local contenu = CreateFrame("Frame", nil, W.defile)
	contenu:SetSize(10, 10)
	W.defile:SetScrollChild(contenu)
	local barre = CreateFrame("Slider", nil, panneau)
	barre:SetOrientation("VERTICAL")
	barre:SetWidth(d.largeur_barre)
	barre:SetPoint("TOPRIGHT", panneau, "TOPRIGHT", -4, -6)
	barre:SetPoint("BOTTOMRIGHT", panneau, "BOTTOMRIGHT", -4, 6)
	barre:SetThumbTexture(ui().textures.ascenseur)
	barre:SetMinMaxValues(0, 0)
	barre:SetValueStep(1)
	barre:SetValue(0)
	barre:SetScript("OnValueChanged", function(_, v) W.defile:SetVerticalScroll(v) end)
	W.defile:EnableMouseWheel(true)
	W.defile:SetScript("OnMouseWheel", function(_, delta)
		local mini, maxi = barre:GetMinMaxValues()
		barre:SetValue(math.max(mini, math.min(maxi, barre:GetValue() - delta * d.pas_molette)))
	end)
	W.defile:SetScript("OnSizeChanged", function(_, largeur) contenu:SetWidth(largeur) if W.detail then W.detail:SetWidth(largeur) end end)
	W.barre = { hauteur = function(total)
		contenu:SetHeight(math.max(total, 1))
		local portee = math.max(0, total - (tonumber(W.defile:GetHeight()) or 0))
		barre:SetMinMaxValues(0, portee)
		if barre:GetValue() > portee then barre:SetValue(portee) end
		if portee > 0 then barre:Show() else barre:Hide() end
	end, haut = function() barre:SetValue(0) end }

	local detail = S.creerCadre("EditBox", nil, contenu)
	W.detail = detail
	detail:SetMultiLine(true)
	detail:SetAutoFocus(false)
	detail:SetPoint("TOPLEFT", contenu, "TOPLEFT", 0, 0)
	detail:SetWidth(d.largeur_liste)
	detail:SetTextInsets(4, 4, 4, 4)
	S.peindre(function()
		local taille = ns.Style.taille("normal")
		detail:SetFont(S.cheminPolice(ui().police_repli), taille, ui().contour_texte)
		pcall(detail.SetFont, detail, S.cheminPolice(), taille, ui().contour_texte)
		detail:SetTextColor(S.couleur("parchemin_texte"))
	end)
	-- lecture seule : si on tape, on remet le texte (on peut sélectionner et copier)
	detail:SetScript("OnTextChanged", function(self, saisie)
		if saisie and W.texteDetail and self:GetText() ~= W.texteDetail then self:SetText(W.texteDetail) end
	end)
	detail:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	W.mesure = S.texte(panneau, "normal")
	W.mesure:SetAlpha(0)
	W.mesure:SetPoint("TOPLEFT", panneau, "TOPLEFT", 0, 0)
	W.mesure:SetWordWrap(true)

	W.aide = S.texte(f, "petit")
	W.aide:SetPoint("BOTTOMLEFT", panneau, "BOTTOMLEFT", 6, -d.hauteur_bandeau - 2)
	S.peindre(function() W.aide:SetTextColor(S.couleur("dore_clair")) end)

	W.boutonEffacer = bouton(f, "erreurs.bouton.effacer", function() W.effacer() end)
	W.boutonEffacer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -m, m)
	W.boutonCopierTout = bouton(f, "erreurs.bouton.copier_tout", function() W.copier(true) end)
	W.boutonCopierTout:SetPoint("RIGHT", W.boutonEffacer, "LEFT", -ecart, 0)
	W.boutonCopier = bouton(f, "erreurs.bouton.copier", function() W.copier(false) end)
	W.boutonCopier:SetPoint("RIGHT", W.boutonCopierTout, "LEFT", -ecart, 0)

	f:SetScript("OnShow", function()
		W.memoire()
		W.rafraichir()
	end)
	f:Hide()
	return f
end

function W.estOuverte() return W.cadre ~= nil and W.cadre:IsShown() end

-- Ouvre la fenêtre (sur une erreur donnée si on en passe une).
function W.ouvrir(erreur)
	W.construire()
	if erreur and erreur.id then
		if W.filtre and E.cle(erreur.addon) ~= W.filtre then W.filtre = nil end
		W.selection = erreur.id
	end
	if W.cadre:IsShown() then
		W.rafraichir()
	else
		W.cadre:Show()
	end
end

function W.fermer()
	if W.cadre then W.cadre:Hide() end
end

function W.basculer()
	if W.estOuverte() then W.fermer() else W.ouvrir() end
end

-- La liste se met à jour toute seule quand une erreur arrive ou quand on efface (au plus un rafraîchissement par
-- « delai_rafraichir » secondes, pour qu'une erreur qui se répète cent fois par seconde ne ralentisse pas le jeu).
E.ecouteurs[#E.ecouteurs + 1] = function()
	if W.planifie or not W.estOuverte() then return end
	W.planifie = true
	C_Timer.After(cfg().delai_rafraichir, function()
		W.planifie = false
		W.rafraichir()
	end)
end
