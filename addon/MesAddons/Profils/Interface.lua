-- Fenêtre des profils : liste à gauche, détail et actions à droite, copier/coller en bas.
local _, ns = ...
local U = {}
ns.ProfilsUI = U

local S, P = ns.Style, ns.Profils
local function ui() return ns.donnees.reglages.interface.profils end
local function dui() return ns.donnees.reglages.interface end

U.selection = nil   -- identifiant du profil choisi dans la liste
U.partenaire = nil  -- profil comparé avec le profil choisi
U.attente = nil     -- demande à confirmer : { type = "appliquer" | "fusion" | "supprimer", id }
U.decalage = 0      -- premier profil montré dans la liste
U.message = ""
U.lignes = {}
U.boutons = {}

function U.portee()
	return U.portee_choisie or ns.Reglages.lire("profils.portee")
end

------------------------------------------------------------------ petits outils
local function champ(parent)
	local d = dui()
	local box = S.creerCadre("EditBox", nil, parent)
	S.fond(box, "champ")
	box:SetAutoFocus(false)
	box:SetHeight(ui().hauteur_champ)
	box:SetTextInsets(6, 6, 0, 0)
	S.peindre(function()
		box:SetFont(S.cheminPolice(d.police_repli), ns.Style.taille("normal"), d.contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), ns.Style.taille("normal"), d.contour_texte)
		box:SetTextColor(S.couleur("texte"))
	end)
	return box
end

local function etiquette(parent, role, couleur)
	local t = S.texte(parent, role or "normal")
	t:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(t, couleur or "texte") end)
	return t
end

local function liste(noms)
	local max = ui().noms_max
	local res = {}
	for i, n in ipairs(noms) do
		if i > max then
			res[#res + 1] = ui().suite
			break
		end
		res[#res + 1] = n
	end
	return table.concat(res, ui().separateur)
end

local function selectionne()
	return U.selection and P.obtenir(U.selection) or nil
end

local function actualiser()
	U.rafraichir()
	if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
end

------------------------------------------------------------------ texte du détail
local function texteDetail(p)
	local lignes = {}
	local function ajouter(t) lignes[#lignes + 1] = t end
	local note = p.virtuel and p.note or P.note(p)
	if note and note ~= "" then ajouter(note) ajouter("") end
	local c = P.contenu(p)
	ajouter(ns.T("profil.contenu", #c.ordre, p.virtuel and 0 or #(p.addons or {})))
	local a = P.apercu(p)
	ajouter(ns.T("profil.difference", #a.plus, #a.moins))
	if #a.gardes > 0 then ajouter(ns.T("profil.gardes", #a.gardes, liste(a.gardes))) end
	if #c.absents > 0 then ajouter(ns.T("profil.absents", #c.absents, liste(c.absents))) end
	if #c.deps > 0 then ajouter(ns.T("profil.deps", #c.deps, liste(c.deps))) end
	if #c.deps_absentes > 0 then
		local noms = {}
		for _, d in ipairs(c.deps_absentes) do noms[#noms + 1] = d.dep .. ui().fleche .. d.addon end
		ajouter(ns.T("profil.deps_absentes", #c.deps_absentes, liste(noms)))
	end
	local autres = #P.autresPersonnages()
	if U.portee() == "tous" then ajouter(ns.T("profil.portee_tous_info", autres)) end
	if U.partenaire and U.partenaire ~= p.id then
		local q = P.obtenir(U.partenaire)
		if q then
			local d = P.comparer(p, q)
			ajouter("")
			ajouter(ns.T("profil.compare_titre", P.nom(p), P.nom(q)))
			ajouter(ns.T("profil.compare_a", #d.seulA, liste(d.seulA)))
			ajouter(ns.T("profil.compare_b", #d.seulB, liste(d.seulB)))
			ajouter(ns.T("profil.compare_commun", #d.commun))
		end
	end
	return table.concat(lignes, "\n")
end

local function texteConfirmation(att)
	local p = P.obtenir(att.id)
	if not p then return "" end
	if att.type == "supprimer" then return ns.T("profil.confirme_supprimer", P.nom(p)) end
	local mode = att.type == "fusion" and "fusion" or nil
	local a = P.apercu(p, mode)
	local texte = ns.T(mode and "profil.confirme_fusion" or "profil.confirme_appliquer", P.nom(p), #a.plus, #a.moins)
	if #a.gardes > 0 then texte = texte .. " " .. ns.T("profil.confirme_gardes", #a.gardes) end
	if #a.deps > 0 then texte = texte .. " " .. ns.T("profil.confirme_deps", #a.deps) end
	if U.portee() == "tous" then texte = texte .. " " .. ns.T("profil.confirme_tous", #P.autresPersonnages()) end
	return texte
end

------------------------------------------------------------------ actions
function U.dire(texte)
	U.message = texte or ""
end

function U.demander(type_)
	local p = selectionne()
	if not p then return end
	if type_ == "supprimer" and p.virtuel then return end
	if type_ ~= "supprimer" and not ns.Reglages.lire("profils.confirmer") then
		return U.executer({ type = type_, id = p.id })
	end
	U.attente = { type = type_, id = p.id }
	actualiser()
end

function U.executer(att)
	local p = P.obtenir(att.id)
	U.attente = nil
	if not p then return actualiser() end
	if att.type == "supprimer" then
		P.supprimer(p)
		U.selection = nil
		U.dire(ns.T("profil.supprime", P.nom(p)))
	else
		local a, touches = P.appliquer(p, U.portee(), att.type == "fusion" and "fusion" or nil)
		U.dire(ns.T(att.type == "fusion" and "profil.fusionne" or "profil.applique", P.nom(p), #a.plus, #a.moins, touches))
	end
	actualiser()
end

function U.confirmer()
	if U.attente then U.executer(U.attente) end
end

function U.annulerDemande()
	U.attente = nil
	actualiser()
end

function U.choisir(id)
	U.selection = id
	U.attente = nil
	U.message = ""
	if U.partenaire == id then U.partenaire = nil end
	actualiser()
end

function U.nouveau()
	local texte = U.champNom:GetText()
	local p, err = P.creer(texte)
	if not p then
		U.dire(ns.T(err))
	else
		U.selection = p.id
		U.dire(ns.T("profil.cree", P.nom(p)))
	end
	actualiser()
end

function U.renommer()
	local p = selectionne()
	if not p or p.virtuel then return end
	P.renommer(p, U.champNom:GetText())
	U.dire(ns.T("profil.renomme", P.nom(p)))
	actualiser()
end

function U.changerPortee()
	local nv = U.portee() == "tous" and "perso" or "tous"
	U.portee_choisie = nv
	U.attente = nil
	actualiser()
end

function U.comparerAvec()
	local p = selectionne()
	if not p then return end
	local tous = P.tous()
	local i = 0
	for k, q in ipairs(tous) do if q.id == U.partenaire then i = k end end
	for pas = 1, #tous do
		local q = tous[(i + pas - 1) % #tous + 1]
		if q.id ~= p.id then
			U.partenaire = q.id
			break
		end
	end
	actualiser()
end

function U.enregistrerActuel()
	local p = selectionne()
	if p and P.enregistrerActuel(p) then U.dire(ns.T("profil.enregistre", P.nom(p), #p.addons)) end
	actualiser()
end

function U.retirerAbsents()
	local p = selectionne()
	if not p then return end
	U.dire(ns.T("profil.retire_absents", P.retirerAbsents(p), P.nom(p)))
	actualiser()
end

function U.exporter(tout)
	local p = selectionne()
	local texte = tout and P.exporterTout() or (p and not p.virtuel and P.exporter(p))
	if not texte then return end
	U.champTexte:SetText(texte)
	U.champTexte:SetFocus()
	U.champTexte:HighlightText()
	U.dire(ns.T(tout and "profil.exporte_tout" or "profil.exporte", p and P.nom(p) or ""))
	U.rafraichirMessage()
end

function U.importer()
	local res, err = P.importer(U.champTexte:GetText())
	if not res then
		U.dire(ns.T(err))
	else
		if res.dernier then U.selection = res.dernier.id end
		U.dire(ns.T("profil.importe", res.profils, res.notes, res.etiquettes + res.favoris + res.verrous))
		U.champTexte:SetText("")
	end
	actualiser()
end

function U.rechargerJeu()
	ns.Liste.recharger()
end

------------------------------------------------------------------ construction
local function bouton(parent, id, action)
	local u = ui()
	local b = S.bouton(parent, u.largeur_bouton, dui().hauteur_bouton)
	b:SetScript("OnClick", action)
	U.boutons[id] = b
	return b
end

function U.construire()
	if U.cadre then return U.cadre end
	local u, d = ui(), dui()
	local f = S.creerCadre("Frame", u.nom_cadre, UIParent)
	U.cadre = f
	f:SetFrameStrata(u.strate)
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetSize(u.largeur, u.hauteur)
	f:SetPoint("CENTER", UIParent, "CENTER", u.decalage_x, u.decalage_y)
	S.fond(f, "fenetre")
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function() f:StartMoving() end)
	f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
	table.insert(UISpecialFrames, u.nom_cadre)

	U.titre = etiquette(f, "titre", "dore_clair")
	U.titre:SetPoint("TOPLEFT", f, "TOPLEFT", d.marge + 4, -(d.marge + 4))
	U.croix = S.bouton(f, d.taille_croix, d.taille_croix)
	U.croix:SetPoint("TOPRIGHT", f, "TOPRIGHT", -d.marge, -d.marge)
	U.croix:Texte("x")
	U.croix:SetScript("OnClick", function() U.fermer() end)

	-- liste des profils
	local haut = d.marge + u.hauteur_titre
	local gauche = S.creerCadre("Frame", nil, f)
	U.panneauListe = gauche
	S.fond(gauche, "panneau")
	gauche:SetPoint("TOPLEFT", f, "TOPLEFT", d.marge, -haut)
	gauche:SetSize(u.largeur_liste, u.lignes_visibles * u.hauteur_ligne + 2 * d.ecart)
	gauche:EnableMouseWheel(true)
	gauche:SetScript("OnMouseWheel", function(_, delta)
		local n = #P.tous() - u.lignes_visibles
		U.decalage = math.max(0, math.min(math.max(0, n), U.decalage - delta))
		U.rafraichir()
	end)
	for i = 1, u.lignes_visibles do
		local l = CreateFrame("Button", nil, gauche)
		l:SetHeight(u.hauteur_ligne)
		l:SetPoint("TOPLEFT", gauche, "TOPLEFT", d.ecart, -(d.ecart + (i - 1) * u.hauteur_ligne))
		l:SetPoint("TOPRIGHT", gauche, "TOPRIGHT", -d.ecart, -(d.ecart + (i - 1) * u.hauteur_ligne))
		l.fond = l:CreateTexture(nil, "BACKGROUND")
		l.fond:SetAllPoints(l)
		S.aplat(l.fond, "accent", u.alpha_selection)
		l.fond:Hide()
		l.icone = l:CreateTexture(nil, "ARTWORK")
		l.icone:SetSize(u.taille_icone, u.taille_icone)
		l.icone:SetPoint("LEFT", l, "LEFT", 4, 0)
		l.nombre = etiquette(l, "petit", "texte_doux")
		l.nombre:SetPoint("RIGHT", l, "RIGHT", -4, 0)
		l.nombre:SetJustifyH("RIGHT")
		l.nom = etiquette(l, "normal")
		l.nom:SetPoint("LEFT", l.icone, "RIGHT", 6, 0)
		l.nom:SetPoint("RIGHT", l.nombre, "LEFT", -4, 0)
		l:SetScript("OnClick", function(self) if self.profil then U.choisir(self.profil) end end)
		U.lignes[i] = l
	end

	-- détail à droite
	local x = d.marge + u.largeur_liste + d.ecart * 2
	local largeur = u.largeur - x - d.marge
	U.largeurDetail = largeur
	U.icone = CreateFrame("Button", nil, f)
	U.icone:SetSize(u.taille_icone_grand, u.taille_icone_grand)
	U.icone:SetPoint("TOPLEFT", f, "TOPLEFT", x, -haut)
	U.icone.tex = U.icone:CreateTexture(nil, "ARTWORK")
	U.icone.tex:SetAllPoints(U.icone)
	U.icone:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	U.icone:SetScript("OnClick", function(_, b)
		local p = selectionne()
		if p and P.changerIcone(p, b == "RightButton" and -1 or 1) then actualiser() end
	end)
	U.couleurBouton = S.bouton(f, u.largeur_couleur, d.hauteur_bouton)
	U.couleurBouton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -d.marge, -haut)
	U.couleurBouton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	U.couleurBouton:SetScript("OnClick", function(_, b)
		local p = selectionne()
		if p and P.changerCouleur(p, b == "RightButton" and -1 or 1) then actualiser() end
	end)
	U.champNom = champ(f)
	U.champNom:SetPoint("LEFT", U.icone, "RIGHT", 8, 0)
	U.champNom:SetPoint("RIGHT", U.couleurBouton, "LEFT", -8, 0)
	U.champNom:SetScript("OnEnterPressed", function(self) self:ClearFocus() U.renommer() end)
	U.champNom:SetScript("OnEscapePressed", function(self) self:ClearFocus() U.rafraichir() end)

	U.detail = etiquette(f, "normal")
	U.detail:SetPoint("TOPLEFT", U.icone, "BOTTOMLEFT", 0, -d.ecart * 2)
	U.detail:SetWidth(largeur)
	U.detail:SetHeight(u.hauteur_detail)
	U.detail:SetJustifyV("TOP")

	-- boutons d'action (deux colonnes)
	local ligneY = haut + u.taille_icone_grand + u.hauteur_detail + d.ecart * 4
	U.zoneBoutons = { x = x, y = ligneY }
	local specs = {
		{ "appliquer", function() U.demander("appliquer") end },
		{ "portee", function() U.changerPortee() end },
		{ "fusionner", function() U.demander("fusion") end },
		{ "comparer", function() U.comparerAvec() end },
		{ "enregistrer", function() U.enregistrerActuel() end },
		{ "nettoyer", function() U.retirerAbsents() end },
		{ "supprimer", function() U.demander("supprimer") end },
		{ "nouveau", function() U.nouveau() end },
	}
	local colonnes = u.colonnes_boutons
	local lb = (largeur - (colonnes - 1) * d.ecart) / colonnes
	for i, s in ipairs(specs) do
		local b = bouton(f, s[1], s[2])
		b:SetWidth(lb)
		local col, rang = (i - 1) % colonnes, math.floor((i - 1) / colonnes)
		b:SetPoint("TOPLEFT", f, "TOPLEFT", x + col * (lb + d.ecart), -(ligneY + rang * (d.hauteur_bouton + d.ecart)))
	end
	local rangs = math.ceil(#specs / colonnes)
	local yConfirm = ligneY + rangs * (d.hauteur_bouton + d.ecart) + d.ecart

	-- bandeau de confirmation (+x / −y)
	U.confirmation = CreateFrame("Frame", nil, f)
	U.confirmation:SetPoint("TOPLEFT", f, "TOPLEFT", x, -yConfirm)
	U.confirmation:SetSize(largeur, u.hauteur_confirmation)
	U.confirmation.fond = U.confirmation:CreateTexture(nil, "BACKGROUND")
	U.confirmation.fond:SetAllPoints(U.confirmation)
	S.aplat(U.confirmation.fond, "accent_sombre", 0.9)
	U.confirmation.texte = etiquette(U.confirmation, "normal", "dore_clair")
	U.confirmation.texte:SetPoint("TOPLEFT", U.confirmation, "TOPLEFT", 6, -4)
	U.confirmation.texte:SetWidth(largeur - 12)
	U.confirmation.texte:SetJustifyV("TOP")
	U.confirmation.oui = S.bouton(U.confirmation, u.largeur_bouton_court, d.hauteur_bouton)
	U.confirmation.oui:SetPoint("BOTTOMRIGHT", U.confirmation, "BOTTOMRIGHT", -6, 4)
	U.confirmation.oui:SetScript("OnClick", function() U.confirmer() end)
	U.confirmation.non = S.bouton(U.confirmation, u.largeur_bouton_court, d.hauteur_bouton)
	U.confirmation.non:SetPoint("RIGHT", U.confirmation.oui, "LEFT", -6, 0)
	U.confirmation.non:SetScript("OnClick", function() U.annulerDemande() end)
	U.confirmation:Hide()

	-- message, rechargement
	U.messageTexte = etiquette(f, "normal", "dore_clair")
	U.messageTexte:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", d.marge + 4, d.marge + u.hauteur_champ * 2 + d.ecart * 4 + 4)
	U.messageTexte:SetWidth(u.largeur - 2 * d.marge - u.largeur_bouton - 16)
	U.boutonRecharger = S.bouton(f, u.largeur_bouton, d.hauteur_bouton)
	U.boutonRecharger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge, d.marge + u.hauteur_champ * 2 + d.ecart * 4)
	U.boutonRecharger:SetScript("OnClick", function() U.rechargerJeu() end)
	U.boutonRecharger.halo:Show()

	-- copier / coller
	U.champTexte = champ(f)
	U.champTexte:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", d.marge, d.marge + u.hauteur_champ + d.ecart * 2)
	U.champTexte:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -d.marge, d.marge + u.hauteur_champ + d.ecart * 2)
	U.champTexte:SetMaxLetters(0)
	U.champTexte:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	local pied = {
		{ "copier", function() U.exporter(false) end },
		{ "sauvegarde", function() U.exporter(true) end },
		{ "coller", function() U.importer() end },
	}
	local lp = (u.largeur - 2 * d.marge - (#pied - 1) * d.ecart) / #pied
	for i, s in ipairs(pied) do
		local b = bouton(f, s[1], s[2])
		b:SetWidth(lp)
		b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", d.marge + (i - 1) * (lp + d.ecart), d.marge)
	end

	f:SetScript("OnShow", function() U.rafraichir() end)
	S.peindre(function() if f:IsShown() then U.rafraichir() end end)
	f:Hide()
	return f
end

------------------------------------------------------------------ mise à jour
function U.rafraichirMessage()
	if not U.cadre then return end
	local en_attente = ns.Liste.enAttente()
	U.messageTexte:SetText(U.message ~= "" and U.message or ns.T("profils.aide"))
	U.boutonRecharger:Texte(ns.T("bouton.recharger_n", en_attente))
	if en_attente > 0 then U.boutonRecharger:Show() else U.boutonRecharger:Hide() end
end

function U.rafraichir()
	if not U.cadre then return end
	local u = ui()
	local tous = P.tous()
	if U.selection and not P.obtenir(U.selection) then U.selection = nil end
	if not U.selection then
		local actuel = P.actuel()
		U.selection = actuel and actuel.id or tous[1].id
	end
	U.titre:SetText(ns.T("profils.titre"))
	local actuel = P.actuel()
	local max = math.max(0, #tous - u.lignes_visibles)
	if U.decalage > max then U.decalage = max end
	for i, l in ipairs(U.lignes) do
		local p = tous[i + U.decalage]
		l.profil = p and p.id or nil
		if p then
			l:Show()
			l.icone:SetTexture(P.icone(p))
			local r, g, b = S.hex(P.couleur(p))
			l.nom:SetTextColor(r, g, b)
			local marque = ""
			if actuel and actuel.id == p.id then marque = ns.T(P.actuelModifie() and "profil.marque_modifie" or "profil.marque_actuel") .. " " end
			if P.incomplet(p) then marque = marque .. ns.T("profil.marque_incomplet") .. " " end
			l.nom:SetText(marque .. P.nom(p))
			l.nombre:SetText(p.virtuel and "" or tostring(#(p.addons or {})))
			if p.id == U.selection then l.fond:Show() else l.fond:Hide() end
		else
			l:Hide()
		end
	end
	local p = selectionne()
	if p then
		U.icone.tex:SetTexture(P.icone(p))
		local r, g, b = S.hex(P.couleur(p))
		U.icone.tex:SetVertexColor(1, 1, 1)
		U.champNom:SetText(P.nom(p))
		U.couleurBouton:Texte(P.couleur(p))
		U.couleurBouton.etiquette:SetTextColor(r, g, b)
		U.detail:SetText(texteDetail(p))
		local fixe = p.virtuel
		for _, id in ipairs(u.boutons_profil) do U.boutons[id]:Activer(not fixe) end
		U.boutons.supprimer:Activer(not fixe)
		U.boutons.copier:Activer(not fixe)
		U.boutons.nettoyer:Activer(not fixe and P.incomplet(p))
		U.champNom:SetEnabled(not fixe)
	end
	U.boutons.appliquer:Texte(ns.T("profil.bouton_appliquer"))
	U.boutons.portee:Texte(ns.T(string.format("profil.portee_%s", U.portee())))
	U.boutons.fusionner:Texte(ns.T("profil.bouton_fusionner"))
	local q = U.partenaire and P.obtenir(U.partenaire)
	U.boutons.comparer:Texte(q and ns.T("profil.bouton_comparer_avec", P.nom(q)) or ns.T("profil.bouton_comparer"))
	U.boutons.enregistrer:Texte(ns.T("profil.bouton_enregistrer"))
	U.boutons.nettoyer:Texte(ns.T("profil.bouton_nettoyer"))
	U.boutons.supprimer:Texte(ns.T("profil.bouton_supprimer"))
	U.boutons.nouveau:Texte(ns.T("profil.bouton_nouveau"))
	U.boutons.copier:Texte(ns.T("profil.bouton_copier"))
	U.boutons.sauvegarde:Texte(ns.T("profil.bouton_sauvegarde"))
	U.boutons.coller:Texte(ns.T("profil.bouton_coller"))
	if U.attente then
		U.confirmation.texte:SetText(texteConfirmation(U.attente))
		U.confirmation.oui:Texte(ns.T("profil.oui"))
		U.confirmation.non:Texte(ns.T("profil.non"))
		U.confirmation:Show()
	else
		U.confirmation:Hide()
	end
	U.rafraichirMessage()
	if U.bouton then U.maj() end
end

function U.ouvrir()
	U.construire()
	U.cadre:Show()
end

function U.fermer()
	if U.cadre then U.cadre:Hide() end
end

function U.estOuvert() return U.cadre ~= nil and U.cadre:IsShown() end

function U.basculer()
	if U.estOuvert() then U.fermer() else U.ouvrir() end
end

------------------------------------------------------------------ bouton dans l'en-tête de la fenêtre principale
function U.brancher(entete, ancre)
	local d = dui()
	U.bouton = S.bouton(entete, ui().largeur_bouton_entete, d.hauteur_bouton)
	U.bouton:SetPoint("RIGHT", ancre, "LEFT", -8, 0)
	U.bouton:SetScript("OnClick", function() U.basculer() end)
	U.maj()
end

function U.maj()
	if not U.bouton then return end
	local p = P.actuel()
	if p then
		U.bouton:Texte(ns.T("profils.bouton_actuel", string.sub(P.nom(p), 1, ui().nom_bouton_max)))
	else
		U.bouton:Texte(ns.T("profils.bouton"))
	end
end

-- Appelé par la fenêtre principale quand quelque chose change (case cochée, rechargement…).
function U.surChangement()
	if U.estOuvert() then U.rafraichir() else U.maj() end
end
