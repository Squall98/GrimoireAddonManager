-- Page « Mes Add-ons » dans Échap › Options › AddOns (Settings.RegisterCanvasLayoutCategory) et commande « options ».
local _, ns = ...
local O = ns.Options
local S = ns.Style

local function oc() return ns.donnees.reglages.interface.options end

-- Contenu de la page, construit à la première ouverture.
local function remplir(page)
	if page.pret then return end
	page.pret = true
	local o = oc()
	page.titre = S.texte(page, "titre")
	page.titre:SetPoint("TOPLEFT", page, "TOPLEFT", o.marge, -o.marge)
	S.peindre(function() S.couleurTexte(page.titre, "dore_clair") end)
	page.aide = S.texte(page, "normal")
	page.aide:SetPoint("TOPLEFT", page.titre, "BOTTOMLEFT", 0, -6)
	page.aide:SetJustifyH("LEFT")
	S.peindre(function() S.couleurTexte(page.aide, "texte_doux") end)
	page.ouvrir = S.bouton(page, o.largeur_controle, o.hauteur_bouton)
	page.ouvrir:SetPoint("TOPRIGHT", page, "TOPRIGHT", -o.marge, -o.marge)
	page.ouvrir:SetScript("OnClick", function() ns.Fenetre.ouvrir() end)
	local interieur = CreateFrame("Frame", nil, page)
	interieur:SetPoint("TOPLEFT", page, "TOPLEFT", o.marge, -(o.hauteur_titre + o.marge + 22))
	interieur:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -o.marge, o.marge)
	page.inst = O.construire(interieur, function()
		page.titre:SetText(ns.T("opt.titre"))
		page.aide:SetText(ns.T("opt.page_aide"))
		page.ouvrir:Texte(ns.T("opt.page_ouvrir"))
	end)
end

local function rafraichirPage(page)
	remplir(page)
	page.inst.rafraichir()
end

function O.creerPage()
	if O.page or not Settings or not Settings.RegisterCanvasLayoutCategory then return end
	local page = CreateFrame("Frame", oc().nom_page)
	page.name = ns.T("nom")
	O.page = page
	page:SetScript("OnShow", function() ns.Journal.proteger(rafraichirPage, page) end)
	O.categorie = Settings.RegisterCanvasLayoutCategory(page, ns.T("nom"))
	Settings.RegisterAddOnCategory(O.categorie)
end

-- Ouvre la page du jeu ; renvoie faux si le jeu ne la propose pas.
function O.ouvrirPage()
	if not O.categorie or not Settings.OpenToCategory then return false end
	local id = O.categorie.GetID and O.categorie:GetID() or O.categorie.ID
	Settings.OpenToCategory(id)
	return true
end

local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function() ns.Journal.proteger(O.creerPage) end)

------------------------------------------------------------------ commande « options »
local function mot_est(mot, cle)
	mot = string.lower(mot or "")
	for _, code in ipairs(ns.Langue.disponibles()) do
		local t = ns.Langue.texte(code, cle)
		if t and string.lower(t) == mot then return true end
	end
	return false
end

ns.Commandes.sous.options = function(reste)
	if reste ~= "" and mot_est(reste, "arg.page") then
		if not O.ouvrirPage() then O.ouvrirVolet() end
		return
	end
	O.ouvrirVolet()
end
