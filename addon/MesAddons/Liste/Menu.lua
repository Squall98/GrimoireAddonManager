-- Menu du clic droit sur une ligne : favori, essai, « à désinstaller », utilité, vu, étiquettes.
local _, ns = ...
local N = {}
ns.Menu = N

local S, R = ns.Style, ns.Recherche
local function cfg() return ns.donnees.reglages.interface.liste.menu end

N.boutons = {}

local function construire()
	if N.cadre then return end
	local c = cfg()
	local f = S.creerCadre("Frame", c.nom, UIParent)
	N.cadre = f
	f:SetFrameStrata(c.strate)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetWidth(c.largeur)
	S.fond(f, "fenetre")
	f:Hide()
	-- un voile invisible derrière le menu : un clic ailleurs le ferme
	local voile = CreateFrame("Button", nil, UIParent)
	N.voile = voile
	voile:SetAllPoints(UIParent)
	voile:SetFrameStrata(c.strate)
	voile:SetScript("OnClick", function() N.fermer() end)
	voile:Hide()
	N.titre = S.texte(f, "normal")
	N.titre:SetPoint("TOPLEFT", f, "TOPLEFT", c.marge, -c.marge)
	N.titre:SetPoint("TOPRIGHT", f, "TOPRIGHT", -c.marge, -c.marge)
	N.titre:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(N.titre, "dore_clair") end)
	N.legende = S.texte(f, "petit")
	N.legende:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(N.legende, "texte_doux") end)
	local box = S.creerCadre("EditBox", nil, f)
	N.champ = box
	S.fond(box, "champ")
	box:SetAutoFocus(false)
	box:SetHeight(c.hauteur_champ)
	box:SetTextInsets(6, 6, 0, 0)
	S.peindre(function()
		local d = ns.donnees.reglages.interface
		box:SetFont(S.cheminPolice(d.police_repli), ns.Style.taille("normal"), d.contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), ns.Style.taille("normal"), d.contour_texte)
		box:SetTextColor(S.couleur("texte"))
	end)
	box:SetScript("OnEnterPressed", function(self)
		if N.nom then
			R.definirEtiquettes(N.nom, R.analyserEtiquettes(self:GetText()))
		end
		N.fermer()
		ns.Fenetre.rafraichir()
	end)
	box:SetScript("OnEscapePressed", function() N.fermer() end)
	f:SetScript("OnHide", function() voile:Hide() end)
	table.insert(UISpecialFrames, c.nom)
end

-- Entrées du menu pour un add-on : { texte, action, garde (menu reste ouvert) }.
function N.entrees(e)
	local nom = e.nom
	local liste = {}
	local function ajouter(texte, action, garde) liste[#liste + 1] = { texte = texte, action = action, garde = garde } end
	ajouter(ns.T(R.favori(nom) and "menu.favori_retirer" or "menu.favori"), function() R.basculerFavori(nom) end)
	ajouter(ns.T(R.essai(nom) and "menu.essai_fin" or "menu.essai"), function() ns.Actions.basculerEssai(nom) end)
	ajouter(ns.T(R.aDesinstaller(nom) and "menu.desinstaller_fin" or "menu.desinstaller"),
		function() R.basculerDesinstaller(nom) end)
	local u = R.utilite(e)
	ajouter(ns.T("menu.utilite", u and ns.T("utilite." .. u) or ns.T("menu.utilite_aucune")),
		function() R.utiliteSuivante(nom) N.ouvrirPour(e) end, true)
	if R.nouveau(e) or R.misAJour(e) or (R.erreurs[nom] or 0) > 0 then
		ajouter(ns.T("menu.vu"), function() R.reconnaitre(nom) R.erreurs[nom] = nil end)
	end
	if ns.Profils then
		ajouter(ns.T(ns.Profils.verrou(nom) and "menu.deverrouiller" or "menu.verrouiller"), function() ns.Profils.basculerVerrou(nom) end)
	end
	if ns.Actions then
		ajouter(ns.T("menu.complet"), function() ns.Actions.activerComplet(nom) end)
		ajouter(ns.T("menu.seul"), function() ns.Actions.seul(nom) end)
		if ns.FicheModele.lien(e) ~= "" then ajouter(ns.T("menu.lien"), function() ns.Actions.montrerLien(nom) end) end
	end
	return liste
end

function N.ouvrirPour(e)
	construire()
	local c = cfg()
	N.nom = e.nom
	N.titre:SetText(e.titre)
	local y = c.marge + 18
	local liste = N.entrees(e)
	for i, it in ipairs(liste) do
		local b = N.boutons[i]
		if not b then
			b = S.bouton(N.cadre, c.largeur - 2 * c.marge, c.hauteur_item)
			b:SetScript("OnClick", function(self)
				local it_ = self.entree
				if not it_ then return end
				it_.action()
				if not it_.garde then
					N.fermer()
					ns.Fenetre.rafraichir()
				else
					ns.Fenetre.rafraichir()
				end
			end)
			N.boutons[i] = b
		end
		b.entree = it
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", N.cadre, "TOPLEFT", c.marge, -y)
		b:Texte(it.texte)
		b:Show()
		y = y + c.hauteur_item + c.ecart
	end
	for i = #liste + 1, #N.boutons do N.boutons[i].entree = nil N.boutons[i]:Hide() end
	N.legende:ClearAllPoints()
	N.legende:SetPoint("TOPLEFT", N.cadre, "TOPLEFT", c.marge, -y)
	N.legende:SetPoint("TOPRIGHT", N.cadre, "TOPRIGHT", -c.marge, -y)
	N.legende:SetText(ns.T("menu.etiquettes"))
	y = y + 16
	N.champ:ClearAllPoints()
	N.champ:SetPoint("TOPLEFT", N.cadre, "TOPLEFT", c.marge, -y)
	N.champ:SetPoint("TOPRIGHT", N.cadre, "TOPRIGHT", -c.marge, -y)
	N.champ:SetText(R.texteEtiquettes(e.nom))
	y = y + c.hauteur_champ + c.marge
	N.cadre:SetHeight(y)
end

-- Ouvre le menu à côté du curseur.
function N.ouvrir(ligne)
	local e = ligne and ligne.entree
	if not e then return end
	N.ouvrirPour(e)
	local x, y = GetCursorPosition()
	local echelle = UIParent:GetEffectiveScale()
	N.cadre:ClearAllPoints()
	N.cadre:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / echelle, y / echelle)
	N.voile:Show()
	N.cadre:Show()
end

function N.fermer()
	if N.cadre then
		N.cadre:Hide()
		N.champ:ClearFocus()
	end
	N.nom = nil
end

function N.ouvert() return N.cadre ~= nil and N.cadre:IsShown() end
