-- Petit menu du clic droit sur le bouton de la minicarte : recharger, liste des profils, dépannage, périmés, ouvrir.
local _, ns = ...
local Q = {}
ns.Rapide = Q

local S, A, M = ns.Style, ns.Actions, ns.Liste
local function cfg() return ns.donnees.reglages.interface.rapide end

Q.boutons = {}

local function construire()
	if Q.cadre then return end
	local c = cfg()
	local f = S.creerCadre("Frame", c.nom, UIParent)
	Q.cadre = f
	f:SetFrameStrata(c.strate)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetWidth(c.largeur)
	S.fond(f, "fenetre")
	f:Hide()
	-- un voile invisible derrière le menu : un clic ailleurs le ferme
	local voile = CreateFrame("Button", nil, UIParent)
	Q.voile = voile
	voile:SetAllPoints(UIParent)
	voile:SetFrameStrata(c.strate)
	voile:SetScript("OnClick", function() Q.fermer() end)
	voile:Hide()
	f:SetScript("OnHide", function() voile:Hide() end)
	table.insert(UISpecialFrames, c.nom)
end

-- Entrées : { texte, action } ; sans action, c'est un simple titre.
function Q.entrees()
	local liste = {}
	local function ajouter(texte, action) liste[#liste + 1] = { texte = texte, action = action } end
	local attente = M.enAttente()
	if attente > 0 then
		ajouter(ns.T("rapide.recharger", attente), function() M.recharger() end)
	end
	if ns.Profils and ns.Reglages.lire("acces.profils_minicarte") then
		ajouter(ns.T("rapide.profils"))
		local actuel = ns.Profils.actuel()
		for _, p in ipairs(ns.Profils.tous()) do
			local marque = (actuel and actuel.id == p.id) and ns.T("profil.marque_actuel") or ""
			ajouter(marque .. ns.Profils.nom(p), function() A.appliquerProfil(p) end)
		end
	end
	ajouter(ns.T("rapide.outils"))
	if A.depannageActif() then
		ajouter(ns.T("rapide.retour"), function()
			local ok, plus, moins = A.retour()
			if ok then ns.dire(ns.T("actions.retour", plus, moins)) end
		end)
	else
		ajouter(ns.T("rapide.depannage"), function()
			local plus, moins = A.depannage({})
			ns.dire(ns.T("actions.depannage", 0, plus, moins))
		end)
	end
	ajouter(ns.T(A.perimesActif() and "rapide.perimes_oui" or "rapide.perimes_non"),
		function() A.definirPerimes(not A.perimesActif()) end)
	ajouter(ns.T("rapide.mini"), function() ns.Fenetre.definirMini(ns.Fenetre.mode() ~= "mini") end)
	ajouter(ns.T("rapide.antiseche"), function() ns.AideFenetre.basculer() end)
	ajouter(ns.T("rapide.visite"), function() ns.Visite.demarrer() end)
	ajouter(ns.T("rapide.ouvrir"), function() ns.Fenetre.ouvrir() end)
	return liste
end

function Q.remplir()
	construire()
	local c = cfg()
	local y = c.marge
	local liste = Q.entrees()
	for i, it in ipairs(liste) do
		local b = Q.boutons[i]
		if not b then
			b = S.bouton(Q.cadre, c.largeur - 2 * c.marge, c.hauteur_item)
			b:SetScript("OnClick", function(self)
				local it_ = self.entree
				if not it_ or not it_.action then return end
				Q.fermer()
				ns.Journal.proteger(it_.action)
				if ns.Fenetre.estOuverte() then ns.Fenetre.rafraichir() end
			end)
			Q.boutons[i] = b
		end
		b.entree = it
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", Q.cadre, "TOPLEFT", c.marge, -y)
		b:Texte(it.texte)
		b:Show()
		y = y + c.hauteur_item + c.ecart
	end
	for i = #liste + 1, #Q.boutons do Q.boutons[i].entree = nil Q.boutons[i]:Hide() end
	Q.cadre:SetHeight(y + c.marge)
end

function Q.ouvrir()
	Q.remplir()
	local x, y = GetCursorPosition()
	local echelle = UIParent:GetEffectiveScale()
	Q.cadre:ClearAllPoints()
	Q.cadre:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / echelle, y / echelle)
	Q.voile:Show()
	Q.cadre:Show()
end

function Q.fermer()
	if Q.cadre then Q.cadre:Hide() end
end

function Q.ouvert() return Q.cadre ~= nil and Q.cadre:IsShown() end

-- Clic droit sur le bouton : recharger tout de suite (si réglé ainsi et si des changements attendent), sinon le menu.
function Q.clicDroit()
	if Q.ouvert() then return Q.fermer() end
	if ns.Reglages.lire("acces.clic_droit") == "recharger" and M.enAttente() > 0 then
		return M.recharger()
	end
	Q.ouvrir()
end
