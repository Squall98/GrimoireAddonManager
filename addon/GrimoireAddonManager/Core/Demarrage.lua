-- Démarrage : branche les événements du jeu et lance les modules dans l'ordre.
local nom, ns = ...

local cadre = CreateFrame("Frame")
ns.cadreEvenements = cadre
cadre:RegisterEvent("ADDON_LOADED")
cadre:RegisterEvent("PLAYER_LOGIN")

cadre:SetScript("OnEvent", function(_, evenement, argument)
	if evenement == "ADDON_LOADED" and argument == nom then
		ns.Reglages.init()
		ns.Journal.vider_attente()
		ns.Journal.surveiller_erreurs()
		ns.Journal.ecrire("info", "journal.demarrage", C_AddOns.GetAddOnMetadata(nom, "Version"),
			select(4, GetBuildInfo()), GetLocale())
		ns.Journal.ecrire("info", "journal.donnees", ns.Fiches.nombre(), ns.Fiches.nombreCategories(), ns.Fiches.nombreProfils())
		ns.Commandes.enregistrer()
	elseif evenement == "PLAYER_LOGIN" then
		ns.Journal.proteger(ns.Personnages.memoriser)
		if ns.Reglages.lire("affichage.message_chargement") then
			local version = C_AddOns.GetAddOnMetadata(nom, "Version")
			local principale = ns.Commandes.principale()
			if principale then
				ns.dire(ns.T("chargement.ok", version, principale))
			else
				ns.dire(ns.T("chargement.sans_commande", version))
			end
		end
	end
end)
