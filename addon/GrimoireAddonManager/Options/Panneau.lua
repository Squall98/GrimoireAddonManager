-- Panneau d'options : généré d'après le schéma (donnees/options.json), utilisé dans la fenêtre (volet) et dans la page du jeu.
local _, ns = ...
local O = ns.Options
local S = ns.Style

local function ui() return ns.donnees.reglages.interface end
local function oc() return ui().options end

local function champ(parent)
	local d = ui()
	local box = S.creerCadre("EditBox", nil, parent)
	S.fond(box, "champ")
	box:SetAutoFocus(false)
	box:SetHeight(oc().hauteur_bouton)
	box:SetTextInsets(6, 6, 0, 0)
	S.peindre(function()
		box:SetFont(S.cheminPolice(d.police_repli), ns.Style.taille("normal"), d.contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), ns.Style.taille("normal"), d.contour_texte)
		box:SetTextColor(S.couleur("texte"))
	end)
	return box
end

local function etiquette(parent, role)
	local t = S.texte(parent, role or "normal")
	t:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(t, "texte") end)
	return t
end

-- Texte affiché pour une valeur d'un réglage à choix.
local function texteChoix(el, valeur)
	return ns.T(string.format(el.texte_choix, tostring(valeur)))
end

local function suivant(el, actuel, sens)
	local n = #el.choix
	local i = 1
	for k, v in ipairs(el.choix) do if v == actuel then i = k end end
	return el.choix[(i - 1 + sens) % n + 1]
end

------------------------------------------------------------------ une ligne par type de réglage
local constructeurs = {}

function constructeurs.bool(ligne, el)
	local o = oc()
	ligne.case = S.case(ligne)
	ligne.case:SetPoint("LEFT", ligne, "LEFT", o.retrait, 0)
	ligne.texte = etiquette(ligne)
	ligne.texte:SetPoint("LEFT", ligne.case, "RIGHT", 6, 0)
	ligne.texte:SetPoint("RIGHT", ligne, "RIGHT", -o.retrait, 0)
	ligne.case:SetScript("OnClick", function(self)
		O.definir(el.chemin, self:GetChecked() and true or false, el.apres)
	end)
	function ligne.maj()
		ligne.case:SetChecked(ns.Reglages.lire(el.chemin) == true)
		ligne.texte:SetText(ns.T("opt." .. el.chemin))
	end
end

function constructeurs.choix(ligne, el)
	local o = oc()
	ligne.bouton = S.bouton(ligne, o.largeur_controle, o.hauteur_bouton)
	ligne.bouton:SetPoint("RIGHT", ligne, "RIGHT", -o.retrait, 0)
	ligne.bouton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	ligne.bouton:SetScript("OnClick", function(_, b)
		O.definir(el.chemin, suivant(el, ns.Reglages.lire(el.chemin), b == "RightButton" and -1 or 1), el.apres)
	end)
	ligne.texte = etiquette(ligne)
	ligne.texte:SetPoint("LEFT", ligne, "LEFT", o.retrait, 0)
	ligne.texte:SetPoint("RIGHT", ligne.bouton, "LEFT", -8, 0)
	function ligne.maj()
		ligne.texte:SetText(ns.T("opt." .. el.chemin))
		ligne.bouton:Texte(texteChoix(el, ns.Reglages.lire(el.chemin)))
	end
end

function constructeurs.nombre(ligne, el)
	local o = oc()
	ligne.plus = S.bouton(ligne, o.largeur_pas, o.hauteur_bouton)
	ligne.plus:SetPoint("RIGHT", ligne, "RIGHT", -o.retrait, 0)
	ligne.plus:Texte("+")
	ligne.valeur = etiquette(ligne)
	ligne.valeur:SetJustifyH("CENTER")
	ligne.valeur:SetWidth(o.largeur_valeur)
	ligne.valeur:SetPoint("RIGHT", ligne.plus, "LEFT", -4, 0)
	ligne.moins = S.bouton(ligne, o.largeur_pas, o.hauteur_bouton)
	ligne.moins:SetPoint("RIGHT", ligne.valeur, "LEFT", -4, 0)
	ligne.moins:Texte("-")
	ligne.texte = etiquette(ligne)
	ligne.texte:SetPoint("LEFT", ligne, "LEFT", o.retrait, 0)
	ligne.texte:SetPoint("RIGHT", ligne.moins, "LEFT", -8, 0)
	local function pas(sens)
		local v = ns.Reglages.lire(el.chemin) + sens * el.pas
		v = math.max(el.min, math.min(el.max, v))
		O.definir(el.chemin, v, el.apres)
	end
	ligne.plus:SetScript("OnClick", function() pas(1) end)
	ligne.moins:SetScript("OnClick", function() pas(-1) end)
	function ligne.maj()
		ligne.texte:SetText(ns.T("opt." .. el.chemin))
		ligne.valeur:SetText(tostring(ns.Reglages.lire(el.chemin)))
	end
end

function constructeurs.texte(ligne, el)
	local o = oc()
	ligne.champ = champ(ligne)
	ligne.champ:SetWidth(o.largeur_controle)
	ligne.champ:SetPoint("RIGHT", ligne, "RIGHT", -o.retrait, 0)
	ligne.texte = etiquette(ligne)
	ligne.texte:SetPoint("LEFT", ligne, "LEFT", o.retrait, 0)
	ligne.texte:SetPoint("RIGHT", ligne.champ, "LEFT", -8, 0)
	ligne.champ:SetScript("OnEnterPressed", function(self)
		local v = string.lower(self:GetText() or "")
		if el.motif == "couleur" and not string.find(v, o.motif_couleur) then
			ns.dire(ns.T("opt.couleur_invalide"))
		else
			O.definir(el.chemin, v, el.apres)
		end
		self:ClearFocus()
		ligne.maj()
	end)
	ligne.champ:SetScript("OnEscapePressed", function(self) self:ClearFocus() ligne.maj() end)
	function ligne.maj()
		ligne.texte:SetText(ns.T("opt." .. el.chemin))
		ligne.champ:SetText(tostring(ns.Reglages.lire(el.chemin)))
	end
end

-- Liste des commandes d'ouverture : un champ, puis l'état de chaque commande (libre, déjà prise + proposition).
function constructeurs.commandes(ligne, el)
	local o = oc()
	ligne.texte = etiquette(ligne)
	ligne.texte:SetPoint("TOPLEFT", ligne, "TOPLEFT", o.retrait, -4)
	ligne.texte:SetPoint("TOPRIGHT", ligne, "TOPRIGHT", -o.retrait, -4)
	ligne.champ = champ(ligne)
	ligne.champ:SetPoint("TOPLEFT", ligne.texte, "BOTTOMLEFT", 0, -4)
	ligne.champ:SetPoint("TOPRIGHT", ligne, "TOPRIGHT", -o.retrait, -24)
	ligne.etat = etiquette(ligne, "petit")
	ligne.etat:SetPoint("TOPLEFT", ligne.champ, "BOTTOMLEFT", 0, -4)
	ligne.etat:SetPoint("TOPRIGHT", ligne, "TOPRIGHT", -o.retrait, 0)
	ligne.etat:SetJustifyV("TOP")
	ligne.champ:SetScript("OnEnterPressed", function(self)
		O.definir(el.chemin, O.analyserCommandes(self:GetText()), el.apres)
		self:ClearFocus()
		ligne.maj()
	end)
	ligne.champ:SetScript("OnEscapePressed", function(self) self:ClearFocus() ligne.maj() end)
	function ligne.maj()
		ligne.texte:SetText(ns.T("opt." .. el.chemin) .. " (" .. ns.T("opt.cmd.aide") .. ")")
		ligne.champ:SetText(table.concat(ns.Reglages.lire(el.chemin), " "))
		local lignes = {}
		for _, e in ipairs(O.etatCommandes()) do lignes[#lignes + 1] = e.texte end
		ligne.etat:SetText(table.concat(lignes, "\n"))
	end
end

function constructeurs.action(ligne, el)
	local o = oc()
	ligne.bouton = S.bouton(ligne, o.largeur_controle + 60, o.hauteur_bouton)
	ligne.bouton:SetPoint("LEFT", ligne, "LEFT", o.retrait, 0)
	ligne.bouton:SetScript("OnClick", function()
		if O.demandeConfirmation(el.action) and not ligne.confirme then
			ligne.confirme = true
			ligne.bouton:Texte(ns.T("opt.confirmer"))
			return
		end
		ligne.confirme = false
		O.faireAction(el.action)
	end)
	function ligne.maj()
		ligne.confirme = false
		ligne.bouton:Texte(ns.T("opt.action." .. el.action))
	end
end

------------------------------------------------------------------ panneau complet
-- Construit le panneau dans `parent` : à gauche les onglets en colonne (donnees/options.json › onglets) et la case
-- « réglages avancés » ; à droite la zone qui défile, avec une carte par groupe de l'onglet choisi. Sans la case,
-- seuls les réglages de tous les jours sont montrés (les autres portent `avance` dans le schéma).
-- Renvoie { zone, lignes, rafraichir, montrer }.
function O.construire(parent, surRafraichir)
	local d, o = ui(), oc()
	local inst = { lignes = {}, cartes = {}, onglets = {}, actif = O.ongletActif }
	local onglets = ns.donnees.options.onglets
	inst.actif = inst.actif or onglets[1].id

	-- colonne des onglets
	local colonne = CreateFrame("Frame", nil, parent)
	colonne:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
	colonne:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 4)
	colonne:SetWidth(o.largeur_onglet)
	for i, t in ipairs(onglets) do
		local b = S.bouton(colonne, o.largeur_onglet, o.hauteur_onglet)
		b.id = t.id
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", colonne, "TOPLEFT", 0, -(i - 1) * (o.hauteur_onglet + o.ecart_onglet))
		b:SetScript("OnClick", function() inst.montrer(t.id) end)
		inst.onglets[#inst.onglets + 1] = b
	end
	-- case « réglages avancés » au bas de la colonne
	local av = CreateFrame("Frame", nil, colonne)
	av:SetPoint("BOTTOMLEFT", colonne, "BOTTOMLEFT", 0, 0)
	av:SetPoint("BOTTOMRIGHT", colonne, "BOTTOMRIGHT", 0, 0)
	av:SetHeight(o.hauteur_avances * 2)
	inst.caseAvances = S.case(av)
	inst.caseAvances:SetPoint("TOPLEFT", av, "TOPLEFT", 0, 0)
	inst.texteAvances = S.texte(av, "petit")
	inst.texteAvances:SetPoint("TOPLEFT", inst.caseAvances, "TOPRIGHT", 4, -2)
	inst.texteAvances:SetPoint("RIGHT", av, "RIGHT", 0, 0)
	inst.texteAvances:SetJustifyH("LEFT")
	inst.texteAvances:SetWordWrap(true)
	S.peindre(function() S.couleurTexte(inst.texteAvances, "texte_doux") end)
	inst.caseAvances:SetScript("OnClick", function(self)
		ns.Reglages.ecrire("options.avances", self:GetChecked() and true or false)
		inst.montrer(inst.actif)
	end)
	inst.caseAvances:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(ns.T("opt.avances_aide"), 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	inst.caseAvances:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- zone qui défile, à droite de la colonne
	local zone = ns.Vue.defilement(parent)
	inst.zone = zone
	zone.sf:SetPoint("TOPLEFT", colonne, "TOPRIGHT", o.marge, 0)
	zone.sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(d.largeur_barre + 4), 4)
	zone.barre:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -3, -4)
	zone.barre:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 4)

	-- une carte par groupe : titre, puis ses lignes (rayées légèrement, éclairées au survol)
	for _, g in ipairs(ns.donnees.options.groupes) do
		local carte = S.creerCadre("Frame", nil, zone.contenu)
		S.fond(carte, "panneau")
		carte.groupe, carte.lignes = g.id, {}
		carte.titre = S.texte(carte, "entete")
		carte.titre:SetPoint("TOPLEFT", carte, "TOPLEFT", o.marge, -o.marge)
		S.peindre(function() S.couleurTexte(carte.titre, "dore_clair") end)
		for _, el in ipairs(g.elements) do
			local ligne = CreateFrame("Frame", nil, carte)
			ligne:SetHeight(el.type == "commandes" and o.hauteur_commandes or o.hauteur_ligne)
			ligne.el, ligne.groupe = el, g.id
			ligne.fond = ligne:CreateTexture(nil, "BACKGROUND", nil, 1)
			ligne.fond:SetAllPoints(ligne)
			ligne:EnableMouse(true)
			ligne:SetScript("OnEnter", function(self) S.colorier(self.fond, "lueur") end)
			ligne:SetScript("OnLeave", function(self) S.colorier(self.fond, "lueur", self.zebre and o.alpha_zebre or 0) end)
			constructeurs[el.type](ligne, el)
			inst.lignes[#inst.lignes + 1] = ligne
			carte.lignes[#carte.lignes + 1] = ligne
		end
		inst.cartes[#inst.cartes + 1] = carte
	end

	-- l'onglet choisi : place ses cartes (seulement les lignes visibles), cache le reste
	function inst.montrer(id)
		inst.actif, O.ongletActif = id, id
		local avances = ns.Reglages.lire("options.avances")
		inst.caseAvances:SetChecked(avances)
		local choisi
		for _, t in ipairs(onglets) do if t.id == id then choisi = t end end
		choisi = choisi or onglets[1]
		local dans = {}
		for _, gid in ipairs(choisi.groupes) do dans[gid] = true end
		for _, b in ipairs(inst.onglets) do
			if b.id == choisi.id then b.halo:Show() else b.halo:Hide() end
		end
		local y = 0
		for _, c in ipairs(inst.cartes) do
			local h, n = o.hauteur_groupe, 0
			for _, l in ipairs(c.lignes) do
				if dans[c.groupe] and (avances or not l.el.avance) then
					n = n + 1
					l.zebre = (n % 2 == 0)
					S.colorier(l.fond, "lueur", l.zebre and o.alpha_zebre or 0)
					l:ClearAllPoints()
					l:SetPoint("TOPLEFT", c, "TOPLEFT", o.marge_carte, -h)
					l:SetPoint("TOPRIGHT", c, "TOPRIGHT", -o.marge_carte, -h)
					l:Show()
					h = h + l:GetHeight()
				else
					l:Hide()
				end
			end
			if n > 0 then
				c:ClearAllPoints()
				c:SetPoint("TOPLEFT", zone.contenu, "TOPLEFT", 0, -y)
				c:SetPoint("TOPRIGHT", zone.contenu, "TOPRIGHT", 0, -y)
				c:SetHeight(h + o.marge_carte)
				c:Show()
				y = y + h + o.marge_carte + o.ecart_groupe
			else
				c:Hide()
			end
		end
		zone.hauteur(y + o.marge)
		zone.haut()
	end

	function inst.rafraichir()
		for _, c in ipairs(inst.cartes) do c.titre:SetText(ns.T("opt.groupe." .. c.groupe)) end
		for i, b in ipairs(inst.onglets) do b:Texte(ns.T("opt.onglet." .. onglets[i].id)) end
		inst.texteAvances:SetText(ns.T("opt.avances"))
		for _, l in ipairs(inst.lignes) do l.maj() end
		if surRafraichir then surRafraichir() end
	end
	O.instances[#O.instances + 1] = inst
	inst.rafraichir()
	inst.montrer(inst.actif)
	return inst
end

------------------------------------------------------------------ volet dans la fenêtre
function O.construireVolet()
	if O.volet then return end
	local F, o = ns.Fenetre, oc()
	F.construire()
	local v = S.creerCadre("Frame", nil, F.corps)
	O.volet = v
	S.fond(v, "volet")
	v:SetAllPoints(F.corps)
	v:SetFrameLevel(F.corps:GetFrameLevel() + o.niveau_volet)
	v:EnableMouse(true)
	v.titre = S.texte(v, "titre")
	v.titre:SetPoint("TOPLEFT", v, "TOPLEFT", o.marge + 4, -o.marge)
	S.peindre(function() S.couleurTexte(v.titre, "dore_clair") end)
	v.retour = S.bouton(v, o.largeur_retour, o.hauteur_bouton)
	v.retour:SetPoint("TOPRIGHT", v, "TOPRIGHT", -(o.marge + 4), -o.marge)
	v.retour:SetScript("OnClick", function() O.fermerVolet() end)
	local interieur = CreateFrame("Frame", nil, v)
	interieur:SetPoint("TOPLEFT", v, "TOPLEFT", o.marge, -(o.hauteur_titre + o.marge))
	interieur:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -o.marge, o.marge)
	O.instVolet = O.construire(interieur, function()
		v.titre:SetText(ns.T("opt.titre"))
		v.retour:Texte(ns.T("opt.retour"))
	end)
	v:SetScript("OnShow", function() O.instVolet.rafraichir() end)
	v:Hide()
end

function O.ouvrirVolet()
	ns.Fenetre.ouvrir()
	O.construireVolet()
	O.volet:Show()
end

function O.fermerVolet()
	if O.volet then O.volet:Hide() end
end

function O.voletOuvert() return O.volet ~= nil and O.volet:IsShown() end

function O.basculerVolet()
	if O.voletOuvert() then O.fermerVolet() else O.ouvrirVolet() end
end
