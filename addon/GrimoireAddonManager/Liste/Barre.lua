-- Barre au-dessus de la liste : champ de recherche, bouton de tri, bouton Options et puces de filtres rapides.
local _, ns = ...
local B = {}
ns.Barre = B

local S, R = ns.Style, ns.Recherche
local function ui() return ns.donnees.reglages.interface end
local function cfg() return ui().liste end

B.puces = {}

local function infobulle(bouton, texte)
	bouton:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(texte(), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	bouton:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Texte du bouton de tri : « Tri : Nom », avec la mention « inversé » si besoin.
function B.texteTri()
	local nom = ns.T("tri." .. ns.Reglages.lire("liste.tri"))
	if ns.Reglages.lire("liste.tri_inverse") then nom = ns.T("barre.tri_inverse", nom) end
	return ns.T("barre.tri", nom)
end

-- Passe au tri suivant (ou au précédent) dans la liste des tris.
function B.changerTri(sens)
	local liste = cfg().tris_ordre
	local actuel = ns.Reglages.lire("liste.tri")
	local i = 1
	for k, id in ipairs(liste) do if id == actuel then i = k end end
	i = (i - 1 + (sens or 1)) % #liste + 1
	ns.Reglages.ecrire("liste.tri", liste[i])
	B.actualiser()
end

function B.inverserTri()
	ns.Reglages.ecrire("liste.tri_inverse", not ns.Reglages.lire("liste.tri_inverse"))
	B.actualiser()
end

-- Tout ce qui dépend du tri, du filtre ou de la recherche est remis à jour.
function B.actualiser()
	if ns.Vue.pret then
		ns.Vue.liste.haut()
		ns.Vue.rafraichirListe()
	end
	B.rafraichir()
end

function B.choisirFiltre(id)
	if id == R.filtre() and id ~= "tous" then id = "tous" end
	R.definirFiltre(id)
	B.actualiser()
end

-- Entrées des listes déroulantes (filtre, vue, tri).
function B.entreesFiltre()
	local actuel, res = R.filtre(), {}
	for _, id in ipairs(R.filtresVisibles()) do
		res[#res + 1] = { id = id, coche = (id == actuel), texte = ns.T("filtre.puce", ns.T("filtre." .. id), R.compter(id)),
			action = function() R.definirFiltre(id) end }
	end
	return res
end

function B.entreesVue()
	local groupe = ns.Reglages.lire("liste.grouper_tous")
	local function choisir(v) return function() ns.Reglages.ecrire("liste.grouper_tous", v) end end
	return {
		{ id = "categories", coche = groupe, texte = ns.T("barre.vue_menu_categories"), action = choisir(true) },
		{ id = "liste", coche = not groupe, texte = ns.T("barre.vue_menu_liste"), action = choisir(false) },
	}
end

function B.entreesTri()
	local actuel, res = ns.Reglages.lire("liste.tri"), {}
	for _, id in ipairs(cfg().tris_ordre) do
		res[#res + 1] = { id = id, coche = (id == actuel), texte = ns.T("tri." .. id),
			action = function() ns.Reglages.ecrire("liste.tri", id) end }
	end
	res[#res + 1] = { id = "inverse", separe = true, coche = ns.Reglages.lire("liste.tri_inverse"),
		texte = ns.T("barre.tri_menu_inverse"), action = B.inverserTri }
	return res
end

function B.construire(parent)
	local d, L = ui(), cfg()
	local D = ns.Deroulant
	local f = CreateFrame("Frame", nil, parent)
	B.cadre = f
	f:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -4)
	f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -4)
	f:SetHeight(L.hauteur_champ)
	local function apres()
		B.actualiser()
		if ns.Options.toutRafraichir then ns.Options.toutRafraichir() end
	end

	B.options = S.bouton(f, L.largeur_options, L.hauteur_champ)
	B.options:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	B.options:SetScript("OnClick", function() ns.Options.basculerVolet() end)
	infobulle(B.options, function() return ns.T("barre.options_aide") end)

	B.tri = D.creer(f, L.largeur_bouton_tri, L.hauteur_champ, B.entreesTri, apres)
	B.tri:SetPoint("RIGHT", B.options, "LEFT", -L.ecart, 0)
	infobulle(B.tri, function() return ns.T("barre.tri_aide") end)

	B.vue = D.creer(f, L.largeur_bouton_vue, L.hauteur_champ, B.entreesVue, apres)
	B.vue:SetPoint("RIGHT", B.tri, "LEFT", -L.ecart, 0)
	infobulle(B.vue, function() return ns.T("barre.vue_aide") end)

	B.filtreBouton = D.creer(f, L.largeur_bouton_filtre, L.hauteur_champ, B.entreesFiltre, apres)
	B.filtreBouton:SetPoint("RIGHT", B.vue, "LEFT", -L.ecart, 0)
	infobulle(B.filtreBouton, function() return ns.T("barre.filtre_aide") end)

	local box = S.creerCadre("EditBox", nil, f)
	B.champ = box
	S.fond(box, "champ")
	box:SetAutoFocus(false)
	box:SetHeight(L.hauteur_champ)
	box:SetTextInsets(6, L.largeur_effacer + 4, 0, 0)
	box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	box:SetPoint("RIGHT", B.filtreBouton, "LEFT", -L.ecart, 0)
	S.peindre(function()
		local taille = ns.Style.taille("normal")
		box:SetFont(S.cheminPolice(d.police_repli), taille, d.contour_texte)
		pcall(box.SetFont, box, S.cheminPolice(), taille, d.contour_texte)
		box:SetTextColor(S.couleur("texte"))
	end)
	B.indice = S.texte(box, "normal")
	B.indice:SetPoint("LEFT", box, "LEFT", 6, 0)
	B.indice:SetPoint("RIGHT", box, "RIGHT", -(L.largeur_effacer + 4), 0)
	B.indice:SetJustifyH("LEFT")
	B.effacer = S.bouton(box, L.largeur_effacer, L.largeur_effacer)
	B.effacer:SetPoint("RIGHT", box, "RIGHT", -2, 0)
	B.effacer:Texte("x")
	B.effacer:SetScript("OnClick", function() box:SetText("") box:ClearFocus() end)
	infobulle(B.effacer, function() return ns.T("barre.effacer") end)
	box:SetScript("OnTextChanged", function(self)
		R.definirTexte(self:GetText())
		B.majChamp()
		B.actualiser()
	end)
	box:SetScript("OnEscapePressed", function(self)
		if self:GetText() ~= "" then self:SetText("") else self:ClearFocus() end
	end)
	box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	if R.texte ~= "" then box:SetText(R.texte) end
	B.majChamp()
	return f
end

function B.majChamp()
	local vide = (R.texte == "")
	B.indice:SetText(ns.T("barre.chercher"))
	S.couleurTexte(B.indice, "texte_eteint")
	if vide then B.indice:Show() B.effacer:Hide() else B.indice:Hide() B.effacer:Show() end
end

-- Textes des trois listes déroulantes (la barre garde toujours la même hauteur).
function B.rafraichir()
	if not B.cadre then return end
	B.tri:Texte(B.texteTri())
	B.vue:Texte(ns.T(ns.Reglages.lire("liste.grouper_tous") and "barre.vue_categories" or "barre.vue_liste"))
	local f = R.filtre()
	B.filtreBouton:Texte(ns.T("barre.filtre", ns.T("filtre.puce", ns.T("filtre." .. f), R.compter(f))))
	B.options:Texte(ns.T("barre.options"))
	B.majChamp()
	B.lignes = 0
end
