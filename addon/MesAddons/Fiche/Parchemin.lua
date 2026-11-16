-- Fiche complète sur le parchemin (colonne de droite) : à quoi il sert, commandes, à savoir, note perso, technique,
-- dépendances, doublons actifs ; boutons « Ses réglages », « Lien CurseForge », « Modifier la fiche » (éditeur et lien en volets).
local _, ns = ...
local P = {}
ns.Parchemin = P

local S = ns.Style
local FM = ns.FicheModele
local function ui() return ns.donnees.reglages.interface end
local function cfg() return ui().fiche end

P.f = {}          -- champs visibles (ns.Vue.fiche) : titre, sous, badges, resume, commandes, remarques, note, technique...
P.ordre = {}      -- éléments empilés dans la zone qui défile
P.selection = nil -- add-on affiché

local function teinte(texte, cle, alpha)
	local r, g, b, a = S.hex(S.palette()[cle])
	texte:SetTextColor(r, g, b, alpha or a)
end

------------------------------------------------------------------ éléments
local function texte(parent, role, couleur, apres)
	local t = S.texte(parent, role)
	t:SetJustifyH("LEFT")
	t:SetWordWrap(true)
	return { w = t, couleur = couleur, apres = apres, texte = true }
end

-- Champ de saisie sur plusieurs lignes, qui grandit avec son texte (la zone qui défile fait le reste).
local function champ(parent, mini, couleur)
	local d = cfg()
	local box = S.creerCadre("EditBox", nil, parent)
	S.fond(box, "champ_parchemin")
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetTextInsets(d.marge_champ, d.marge_champ, d.marge_champ, d.marge_champ)
	box:SetHeight(mini)
	S.peindre(function()
		local taille = ns.Style.taille("fiche")
		box:SetFont(S.cheminPolice(ui().police_repli), taille, ui().contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), taille, ui().contour_texte)
	end)
	box.mesure = S.texte(parent, "fiche")
	box.mesure:SetAlpha(0)
	box.mesure:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	box.mesure:SetWordWrap(true)
	box.mini = mini
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	-- les flèches déplacent le curseur dans le texte (et pas le personnage)
	if box.SetAltArrowKeyMode then box:SetAltArrowKeyMode(false) end
	-- curseur bien visible sur le parchemin (celui du jeu est clair, donc invisible ici) + bord éclairé pendant la saisie
	local c = d.curseur
	box.curseur = box:CreateTexture(nil, "OVERLAY")
	box.curseur:SetWidth(c.largeur)
	box.curseur:Hide()
	box:SetScript("OnCursorChanged", function(self, x, y, _, h)
		self.curseur:ClearAllPoints()
		self.curseur:SetPoint("TOPLEFT", self, "TOPLEFT", (tonumber(x) or 0) + d.marge_champ + c.decalage_x,
			(tonumber(y) or 0) - d.marge_champ + c.decalage_y)
		self.curseur:SetHeight(math.max(tonumber(h) or 0, ns.Style.taille("fiche")))
		self.temps = 0
		if self:HasFocus() then self.curseur:Show() end
	end)
	box:SetScript("OnEditFocusGained", function(self)
		self.avant = self:GetText() or ""
		S.colorier(self.curseur, c.couleur)
		self.curseur:Show()
		self.temps = 0
		self:SetBackdropBorderColor(S.couleur(c.bord_actif))
	end)
	box:SetScript("OnEditFocusLost", function(self)
		self.curseur:Hide()
		self:SetBackdropBorderColor(S.couleur(ui().fonds.champ_parchemin.couleur_bord))
	end)
	box:SetScript("OnUpdate", function(self, ecoule)
		if not self:HasFocus() then return end
		self.temps = (self.temps or 0) + (ecoule or 0)
		if self.temps >= c.clignote then
			self.temps = 0
			if self.curseur:IsShown() then self.curseur:Hide() else self.curseur:Show() end
		end
	end)
	function box:Ajuster(largeur)
		local m = cfg().marge_champ
		self.mesure:SetWidth(math.max(largeur - 2 * m, 1))
		self.mesure:SetText((self:GetText() or "") .. " ")
		local h = tonumber(self.mesure:GetStringHeight()) or 0
		self:SetHeight(math.max(self.mini, h + 2 * m))
	end
	return { w = box, couleur = couleur, champ = true, apres = d.ecart_bloc }
end

-- Largeur disponible pour le texte dans une zone qui défile.
local function largeurUtile(zone)
	local d = cfg()
	local l = zone.contenu:GetWidth()
	if not l or l <= 1 then l = ui().largeur_fiche - ui().largeur_barre - 10 end
	return l - 2 * d.marge
end

-- Empile les éléments visibles (el.vu) l'un sous l'autre ; règle la hauteur de la zone.
local function empiler(zone, elements)
	local d = cfg()
	local largeur = largeurUtile(zone)
	local y = d.marge
	for _, el in ipairs(elements) do
		local w = el.w
		if el.vu then
			if el.champ then w:Ajuster(largeur) end
			if not (el.champ and w:HasFocus()) then w:ClearAllPoints() end
			w:SetPoint("TOPLEFT", zone.contenu, "TOPLEFT", d.marge, -y)
			w:SetPoint("TOPRIGHT", zone.contenu, "TOPRIGHT", -d.marge, -y)
			w:Show()
			local h = el.hauteur or (el.champ and w:GetHeight()) or tonumber(w.GetStringHeight and w:GetStringHeight()) or 0
			if h <= 0 then h = ns.Style.taille("fiche") end
			y = y + h + (el.apres or d.ecart_bloc)
		else
			w:Hide()
		end
	end
	zone.hauteur(y + d.marge)
end

-- Deux rangées de boutons au bas d'un cadre : { gauche, droite } puis { pleine largeur }.
local function pied(parent, rangee1, rangee2)
	local d = cfg()
	local cadre = CreateFrame("Frame", nil, parent)
	cadre:SetHeight(d.hauteur_pied)
	cadre:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
	cadre:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	local b = {}
	local function bouton(id, ligne, gauche, droite)
		local x = S.bouton(cadre, 10, d.hauteur_boutons)
		x:SetHeight(d.hauteur_boutons)
		local y = -2 - (ligne - 1) * (d.hauteur_boutons + d.ecart_boutons)
		x:ClearAllPoints()
		if gauche and droite then
			x:SetPoint("TOPLEFT", cadre, "TOPLEFT", d.marge, y)
			x:SetPoint("TOPRIGHT", cadre, "TOPRIGHT", -d.marge, y)
		elseif gauche then
			x:SetPoint("TOPLEFT", cadre, "TOPLEFT", d.marge, y)
			x:SetPoint("TOPRIGHT", cadre, "TOP", -d.ecart_boutons / 2, y)
		else
			x:SetPoint("TOPLEFT", cadre, "TOP", d.ecart_boutons / 2, y)
			x:SetPoint("TOPRIGHT", cadre, "TOPRIGHT", -d.marge, y)
		end
		b[id] = x
	end
	if rangee1 then
		bouton(rangee1[1], 1, true, false)
		bouton(rangee1[2], 1, false, true)
	end
	if rangee2 then bouton(rangee2[1], rangee1 and 2 or 1, true, true) end
	return cadre, b
end

------------------------------------------------------------------ construction
function P.construire(panneau)
	local d = cfg()
	local V = ns.Vue
	P.panneau = panneau
	P.zone = V.defilement(panneau)
	local z = P.zone
	z.sf:SetPoint("TOPLEFT", panneau, "TOPLEFT", 4, -4)
	z.sf:SetPoint("BOTTOMRIGHT", panneau, "BOTTOMRIGHT", -(ui().largeur_barre + 4), d.hauteur_pied)
	z.barre:SetPoint("TOPRIGHT", panneau, "TOPRIGHT", -3, -4)
	z.barre:SetPoint("BOTTOMRIGHT", panneau, "BOTTOMRIGHT", -3, d.hauteur_pied)

	local f = P.f
	local contenu = z.contenu
	local function ajouter(id, el)
		f[id] = el.w
		el.id = id
		P.ordre[#P.ordre + 1] = el
		return el
	end
	ajouter("titre", texte(contenu, "fiche_titre", "parchemin_titre", d.ecart_titre))
	ajouter("sous", texte(contenu, "fiche_petit", "parchemin_texte", d.ecart_titre))
	ajouter("badges", texte(contenu, "fiche_petit", "accent"))
	ajouter("etSert", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("resume", texte(contenu, "fiche", "parchemin_texte"))
	ajouter("etCommandes", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("commandes", texte(contenu, "fiche", "parchemin_texte"))
	ajouter("etRemarques", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("remarques", texte(contenu, "fiche", "parchemin_texte"))
	ajouter("etNote", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	local note = ajouter("note", champ(contenu, d.hauteur_note_min, "parchemin_texte"))
	ajouter("etTechnique", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("technique", texte(contenu, "fiche_petit", "parchemin_texte"))
	ajouter("etDependances", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("dependances", texte(contenu, "fiche", "parchemin_texte"))
	ajouter("etDoublons", texte(contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
	ajouter("doublons", texte(contenu, "fiche", "parchemin_texte"))

	-- sous la note : « Tout effacer » et « Annuler » (revient au texte d'avant la saisie)
	local outils = CreateFrame("Frame", nil, contenu)
	outils:SetHeight(d.hauteur_outils_note)
	local effacer = S.bouton(outils, d.largeur_outil_note, d.hauteur_outils_note)
	effacer:SetPoint("LEFT", outils, "LEFT", 0, 0)
	local annuler = S.bouton(outils, d.largeur_outil_note, d.hauteur_outils_note)
	annuler:SetPoint("LEFT", effacer, "RIGHT", d.ecart_boutons, 0)
	P.boutonsNote = { effacer = effacer, annuler = annuler }
	effacer:SetScript("OnClick", function()
		local n = P.f.note
		if not n.nom then return end
		n.avant = n.avant or n:GetText() or ""
		n:SetText("")
		FM.definirNote(n.nom, "")
		P.majBadges()
		empiler(P.zone, P.ordre)
	end)
	annuler:SetScript("OnClick", function()
		local n = P.f.note
		if not (n.nom and n.avant) then return end
		n:SetText(n.avant)
		FM.definirNote(n.nom, n.avant)
		P.majBadges()
		empiler(P.zone, P.ordre)
	end)
	local elOutils = { w = outils, hauteur = d.hauteur_outils_note, apres = d.ecart_bloc, id = "outilsNote" }
	for i, el in ipairs(P.ordre) do
		if el.id == "note" then table.insert(P.ordre, i + 1, elOutils) break end
	end
	note.apres = d.ecart_titre

	-- note perso : enregistrée à chaque frappe dans les sauvegardes du jeu
	local indice = S.texte(note.w, "fiche")
	indice:SetPoint("TOPLEFT", note.w, "TOPLEFT", d.marge_champ, -d.marge_champ)
	indice:SetPoint("TOPRIGHT", note.w, "TOPRIGHT", -d.marge_champ, -d.marge_champ)
	indice:SetJustifyH("LEFT")
	indice:SetText(ns.T("fiche.note_indice"))
	P.indice = indice
	note.w:SetMaxLetters(ns.Reglages.lire("fiche.note_max"))
	note.w:SetScript("OnTextChanged", function(self, saisie)
		if (self:GetText() or "") == "" then indice:Show() else indice:Hide() end
		if P.occupe then return end
		if saisie and self.nom then
			FM.definirNote(self.nom, self:GetText())
			P.majBadges()
		end
		empiler(P.zone, P.ordre)
	end)

	-- boutons du bas
	local cadre, b = pied(panneau, { "reglages", "curseforge" }, { "modifier" })
	P.pied, P.boutons = cadre, b
	b.reglages:SetScript("OnClick", P.cliquerReglages)
	b.curseforge:SetScript("OnClick", P.montrerLien)
	b.modifier:SetScript("OnClick", P.ouvrirEdition)

	P.construireEdition(panneau)
	P.construireLien(panneau)
	V.fiche = f
end

-- Volet qui recouvre toute la fiche (éditeur, lien).
local function volet(panneau)
	local v = S.creerCadre("Frame", nil, panneau)
	v:SetPoint("TOPLEFT", panneau, "TOPLEFT", 0, 0)
	v:SetPoint("BOTTOMRIGHT", panneau, "BOTTOMRIGHT", 0, 0)
	v:SetFrameLevel(panneau:GetFrameLevel() + cfg().niveau_volet)
	v:EnableMouse(true)
	S.fond(v, "parchemin")
	v:Hide()
	return v
end

function P.construireEdition(panneau)
	local d = cfg()
	local v = volet(panneau)
	P.edition = v
	local zone = ns.Vue.defilement(v)
	v.zone = zone
	zone.sf:SetPoint("TOPLEFT", v, "TOPLEFT", 4, -4)
	zone.sf:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -(ui().largeur_barre + 4), d.hauteur_pied)
	zone.barre:SetPoint("TOPRIGHT", v, "TOPRIGHT", -3, -4)
	zone.barre:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -3, d.hauteur_pied)
	local els = {}
	v.elements = els
	local function ajouter(id, el)
		el.id = id
		els[#els + 1] = el
		v[id] = el.w
		return el
	end
	ajouter("titre", texte(zone.contenu, "fiche_sous_titre", "parchemin_titre", d.ecart_titre))
	ajouter("aide", texte(zone.contenu, "fiche_petit", "parchemin_texte"))
	for _, c in ipairs(FM.champs) do
		ajouter("et_" .. c, texte(zone.contenu, "fiche_sous_titre", "parchemin_filet", d.ecart_titre))
		ajouter("champ_" .. c, champ(zone.contenu, d.hauteur_champ_min, "parchemin_texte"))
		v["champ_" .. c]:SetMaxLetters(ns.Reglages.lire("fiche.texte_max"))
		v["champ_" .. c]:SetScript("OnTextChanged", function() if not P.occupe then empiler(zone, els) end end)
	end
	local _, b = pied(v, { "enregistrer", "fermer" }, { "retablir" })
	v.boutons = b
	b.enregistrer:SetScript("OnClick", P.enregistrerEdition)
	b.fermer:SetScript("OnClick", function() v:Hide() end)
	b.retablir:SetScript("OnClick", P.retablirEdition)
end

function P.construireLien(panneau)
	local d = cfg()
	local v = volet(panneau)
	P.volet_lien = v
	local function t(role, ancre, decalage)
		local x = S.texte(v, role)
		x:SetPoint("TOPLEFT", ancre, ancre == v and "TOPLEFT" or "BOTTOMLEFT", ancre == v and d.marge or 0, decalage)
		x:SetPoint("TOPRIGHT", v, "TOPRIGHT", -d.marge, decalage)
		x:SetJustifyH("LEFT")
		x:SetWordWrap(true)
		return x
	end
	v.titre = t("fiche_sous_titre", v, -d.marge)
	v.aide = t("fiche_petit", v.titre, -d.ecart_bloc)
	local box = S.creerCadre("EditBox", nil, v)
	S.fond(box, "champ_parchemin")
	box:SetHeight(d.hauteur_lien)
	box:SetAutoFocus(true)
	box:SetTextInsets(d.marge_champ, d.marge_champ, 0, 0)
	S.peindre(function()
		box:SetFont(S.cheminPolice(ui().police_repli), ns.Style.taille("fiche"), ui().contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), ns.Style.taille("fiche"), ui().contour_texte)
	end)
	box:SetPoint("TOPLEFT", v.aide, "BOTTOMLEFT", 0, -d.ecart_bloc)
	box:SetPoint("TOPRIGHT", v, "TOPRIGHT", -d.marge, -d.ecart_bloc)
	-- on peut copier l'adresse mais pas la changer
	box:SetScript("OnTextChanged", function(self, saisie)
		if saisie and v.adresse then
			self:SetText(v.adresse)
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function() v:Hide() end)
	v.adresseBox = box
	local _, b = pied(v, nil, { "fermer" })
	b.fermer:SetScript("OnClick", function() v:Hide() end)
	v.boutons = b
	v:SetScript("OnHide", function() box:ClearFocus() end)
end

------------------------------------------------------------------ actions des boutons
function P.entree() return P.selection and ns.Liste.parNom(P.selection) end

function P.cliquerReglages()
	local e = P.entree()
	if not e then return end
	local etat, commande = FM.ouvrirReglages(e)
	if etat == "ok" then
		ns.dire(ns.T("reglages.ouvert", e.titre, commande))
	else
		ns.dire(ns.T("reglages." .. etat, e.titre))
	end
end

function P.montrerLien()
	local e = P.entree()
	if not e then return end
	local v = P.volet_lien
	local lien = FM.lien(e)
	v.titre:SetText(ns.T("lien.titre", e.titre))
	v.adresse = lien ~= "" and lien or nil
	if lien ~= "" then
		v.aide:SetText(ns.T("lien.aide"))
		v.adresseBox:SetText(lien)
		v.adresseBox:Show()
	else
		v.aide:SetText(ns.T("lien.absent"))
		v.adresseBox:Hide()
	end
	P.teinterVolet(v)
	v:Show()
	if lien ~= "" then
		v.adresseBox:SetFocus()
		v.adresseBox:HighlightText()
	end
end

function P.teinterVolet(v)
	teinte(v.titre, "parchemin_titre")
	teinte(v.aide, "parchemin_texte")
end

function P.ouvrirEdition()
	local e = P.entree()
	if not e then return end
	local v = P.edition
	P.occupe = true
	v.titre:SetText(ns.T("edition.titre", e.titre))
	v.aide:SetText(ns.T("edition.aide", ns.Langue.nom(ns.Langue.code())))
	local tailles = { resume = "fiche.sert", commandes = "fiche.commandes", remarques = "fiche.remarques" }
	for _, c in ipairs(FM.champs) do
		v["et_" .. c]:SetText(ns.T(tailles[c]))
		local texte_ = FM.champ(e.nom, c)
		v["champ_" .. c]:SetText(texte_)
		v["champ_" .. c].nom = e.nom
	end
	P.occupe = false
	for _, el in ipairs(v.elements) do
		el.vu = true
		if el.couleur then teinte(el.w, el.couleur) end
		if el.champ then el.w:SetTextColor(S.hex(S.palette().parchemin_texte)) end
	end
	v.boutons.enregistrer:Texte(ns.T("bouton.enregistrer"))
	v.boutons.fermer:Texte(ns.T("bouton.fermer"))
	v.boutons.retablir:Texte(ns.T("bouton.retablir"))
	v.boutons.retablir:Activer(FM.estModifiee(e.nom))
	v:Show()
	empiler(v.zone, v.elements)
	v.zone.haut()
end

function P.enregistrerEdition()
	local e = P.entree()
	if not e then return end
	local v = P.edition
	local valeurs = {}
	for _, c in ipairs(FM.champs) do valeurs[c] = v["champ_" .. c]:GetText() end
	FM.enregistrer(e.nom, valeurs)
	v:Hide()
	P.rafraichir(e.nom)
end

function P.retablirEdition()
	local e = P.entree()
	if not e then return end
	FM.retablir(e.nom)
	P.edition:Hide()
	P.rafraichir(e.nom)
end

------------------------------------------------------------------ affichage
function P.majBadges()
	local e = P.entree()
	local b = e and FM.partie("badges") and FM.badges(e) or {}
	local t = table.concat(b, cfg().separateur_badges)
	P.f.badges:SetText(t)
	P.el("badges").vu = t ~= ""
end

function P.el(id)
	for _, el in ipairs(P.ordre) do if el.id == id then return el end end
end

local function remplir(id, valeur)
	P.f[id]:SetText(valeur or "")
	P.el(id).vu = valeur ~= nil and valeur ~= ""
end

local function liste(lignes)
	if #lignes == 0 then return "" end
	return table.concat(lignes, "\n")
end

function P.rafraichir(nom)
	if not P.f.titre then return end
	local d = cfg()
	local change = (nom ~= P.precedent)
	P.precedent = nom
	P.selection = nom
	P.occupe = true
	if change then
		P.edition:Hide()
		P.volet_lien:Hide()
	end
	for _, el in ipairs(P.ordre) do
		if el.couleur then teinte(el.w, el.couleur) end
	end
	local e = nom and ns.Liste.parNom(nom)
	if not e then
		P.selection = nil
		for _, el in ipairs(P.ordre) do
			el.vu = false
			if el.texte then el.w:SetText("") end
		end
		remplir("resume", ns.T("fiche.invite"))
		P.f.note.nom = nil
		P.f.note:SetText("")
		for _, b in pairs(P.boutons) do b:Activer(false) end
		P.boutons.reglages:Texte(ns.T("bouton.reglages"))
		P.boutons.curseforge:Texte(ns.T("bouton.curseforge"))
		P.boutons.modifier:Texte(ns.T("bouton.modifier"))
		P.occupe = false
		empiler(P.zone, P.ordre)
		return
	end
	remplir("titre", e.titre)
	remplir("sous", ns.T(e.parent and "fiche.type_module" or "fiche.type_principal")
		.. ui().separateur_info .. ns.Liste.nomCategorie(e.categorie))
	P.majBadges()
	local resume = FM.resume(e)
	local function etiquette(id, cle, vide)
		remplir(id, vide and "" or ns.T(cle))
	end
	if FM.partie("resume") then
		remplir("resume", resume)
		etiquette("etSert", "fiche.sert", false)
	else
		remplir("resume", "")
		etiquette("etSert", "fiche.sert", true)
	end
	local cmd = FM.partie("commandes") and FM.champ(e.nom, "commandes") or ""
	etiquette("etCommandes", "fiche.commandes", cmd == "")
	remplir("commandes", cmd)
	local rem = FM.partie("remarques") and FM.champ(e.nom, "remarques") or ""
	etiquette("etRemarques", "fiche.remarques", rem == "")
	remplir("remarques", rem)
	-- note perso
	local avec_note = FM.partie("note")
	etiquette("etNote", "fiche.note", not avec_note)
	local note = P.f.note
	note.nom = e.nom
	if (note:GetText() or "") ~= FM.note(e.nom) then note:SetText(FM.note(e.nom)) end
	P.el("note").vu = avec_note
	P.el("outilsNote").vu = avec_note
	if change then note.avant = nil end
	P.boutonsNote.effacer:Texte(ns.T("fiche.note_effacer"))
	P.boutonsNote.annuler:Texte(ns.T("fiche.note_annuler"))
	P.indice:SetText(ns.T("fiche.note_indice"))
	teinte(P.indice, "parchemin_texte", 0.55)
	note:SetTextColor(S.hex(S.palette().parchemin_texte))
	-- technique, dépendances, doublons
	local avec_tech = FM.partie("technique")
	etiquette("etTechnique", "fiche.technique", not avec_tech)
	remplir("technique", avec_tech and liste(FM.technique(e)) or "")
	local deps = FM.partie("dependances") and FM.dependances(e) or {}
	local lignes = {}
	for _, x in ipairs(deps) do lignes[#lignes + 1] = d.marque_liste .. " " .. ns.T("fiche.dep." .. x.etat, x.titre) end
	etiquette("etDependances", "fiche.dependances", #lignes == 0)
	remplir("dependances", liste(lignes))
	local dbl = FM.partie("doublons") and FM.doublonsActifs(e) or {}
	lignes = {}
	for _, x in ipairs(dbl) do
		lignes[#lignes + 1] = d.marque_liste .. " " .. (x.texte and ns.T("fiche.doublon_avec", x.titre, x.texte) or x.titre)
	end
	etiquette("etDoublons", "fiche.doublons", #lignes == 0)
	remplir("doublons", liste(lignes))
	-- boutons
	local b = P.boutons
	b.reglages:Texte(ns.T("bouton.reglages"))
	b.curseforge:Texte(ns.T("bouton.curseforge"))
	b.modifier:Texte(ns.T("bouton.modifier"))
	b.reglages:Activer(true)
	b.curseforge:Activer(FM.lien(e) ~= "")
	b.modifier:Activer(true)
	P.occupe = false
	empiler(P.zone, P.ordre)
	if change then P.zone.haut() end
	-- certaines hauteurs de texte ne sont connues qu'à l'image suivante
	C_Timer.After(0, function()
		if P.selection == e.nom and not P.edition:IsShown() then empiler(P.zone, P.ordre) end
	end)
end
