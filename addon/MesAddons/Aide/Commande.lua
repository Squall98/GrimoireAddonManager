-- Sous-commandes de l'aide : antiseche (toutes les commandes) et visite (visite guidée) ; bouton « ? » de la fenêtre.
local _, ns = ...
local sous = ns.Commandes.sous
local W = ns.AideFenetre

-- « antiseche » ouvre la fenêtre ; un mot après la commande remplit la recherche (« antiseche profil »).
function sous.antiseche(reste)
	W.ouvrir(reste or "")
end

function sous.visite()
	ns.Visite.demarrer()
end

-- Petit bouton « ? » dans l'en-tête de la fenêtre principale ; renvoie le bouton pour y accrocher le suivant.
function W.brancher(entete, ancre)
	local d = ns.donnees.reglages.interface.aide
	local b = ns.Style.bouton(entete, d.taille_bouton_entete, d.taille_bouton_entete)
	W.boutonEntete = b
	b:SetPoint("RIGHT", ancre, "LEFT", -d.ecart, 0)
	b:Texte(ns.T("aide.bouton_entete"))
	b:SetScript("OnClick", function() W.basculer() end)
	b:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(ns.T("aide.info_entete"), 1, 1, 1, true)
		GameTooltip:Show()
	end)
	b:HookScript("OnLeave", function() GameTooltip:Hide() end)
	return b
end
