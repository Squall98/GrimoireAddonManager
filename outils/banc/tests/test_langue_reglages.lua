-- Langue (français / anglais), réglages (valeurs de départ, mise à jour, types) et fiches.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

T.test("langue automatique : français puis anglais selon le client", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	T.eq(ns.Langue.code(), "frFR")
	T.eq(ns.T("sous.aide.desc"), "affiche cette aide")
	ns = B.demarrer({ locale = "enUS" })
	T.eq(ns.Langue.code(), "enUS")
	T.eq(ns.T("sous.aide.desc"), "shows this help")
end)

T.test("client dans une autre langue : repli sur l'anglais", function(B)
	local ns = B.demarrer({ locale = "deDE" })
	T.eq(ns.Langue.code(), "enUS")
end)

T.test("changer la langue à la main, gardé après /reload", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	B.slash("/mesaddons langue enUS")
	T.eq(ns.Langue.code(), "enUS")
	T.vrai(B.chat_contient("Language changed: English."))
	ns = B.recharger()
	T.eq(ns.Langue.code(), "enUS")
	B.slash("/mesaddons language auto")
	T.eq(ns.Langue.code(), "frFR", "auto revient à la langue du jeu")
	B.chat = {}
	B.slash("/mesaddons langue klingon")
	T.vrai(B.chat_contient("Langue inconnue : klingon"))
end)

T.test("les deux langues ont exactement les mêmes clés de texte", function(B)
	local ns = B.demarrer()
	for cle in pairs(ns.donnees.textes.frFR) do T.vrai(ns.donnees.textes.enUS[cle], "clé absente en anglais : " .. cle) end
	for cle in pairs(ns.donnees.textes.enUS) do T.vrai(ns.donnees.textes.frFR[cle], "clé absente en français : " .. cle) end
end)

T.test("clé inconnue : la clé elle-même s'affiche (jamais d'erreur)", function(B)
	local ns = B.demarrer()
	T.eq(ns.T("n.existe.pas"), "n.existe.pas")
end)

T.test("réglages : valeurs de départ, écriture typée, mise à jour sans perdre les choix", function(B)
	local ns = B.demarrer()
	T.eq(ns.Reglages.lire("journal.taille_max"), 200)
	T.vrai(ns.Reglages.ecrire("journal.taille_max", 50))
	T.faux(ns.Reglages.ecrire("journal.taille_max", "beaucoup"), "mauvais type refusé")
	T.faux(ns.Reglages.ecrire("n.existe.pas", 1), "réglage inconnu refusé")
	-- on simule une mise à jour de l'add-on qui ajoute un réglage dans les valeurs de départ
	B.deconnecter()
	local sauve = B.wtf.compte.MesAddonsDB
	B.nettoyer(); B.wtf.compte.MesAddonsDB = sauve
	ns = B.demarrer()
	T.eq(ns.Reglages.lire("journal.taille_max"), 50, "le choix de l'utilisateur est gardé")
	ns.Reglages.reinitialiser("journal.taille_max")
	T.eq(ns.Reglages.lire("journal.taille_max"), 200)
end)

T.test("fiches : 102 fiches, texte dans la bonne langue, absente = « pas encore de fiche »", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	T.eq(ns.Fiches.nombre(), 102)
	local fr = ns.Fiches.resume("Auctionator")
	T.vrai(fr:find("Hôtel des ventes"), fr)
	local texte, existe = ns.Fiches.resume("AddonQuiNexistePas")
	T.faux(existe)
	T.eq(texte, "Pas encore de fiche pour cet add-on.")
	ns = B.demarrer({ locale = "enUS" })
	T.vrai(ns.Fiches.resume("Auctionator"):find("auction house"))
	T.eq(ns.Fiches.resume("AddonQuiNexistePas"), "No entry for this add-on yet.")
	T.eq(ns.Fiches.nomCategorie("auction-economy"), "Auction & Economy")
end)

T.test("chaque add-on installé a une fiche (sauf le nôtre) : c'est la liste du banc", function(B)
	local ns = B.demarrer()
	local sans = {}
	for i = 1, C_AddOns.GetNumAddOns() do
		local nom = C_AddOns.GetAddOnInfo(i)
		if nom ~= "MesAddons" and not ns.Fiches.obtenir(nom) then sans[#sans + 1] = nom end
	end
	T.eq(#sans, 0, "sans fiche : " .. table.concat(sans, ", "))
end)

T.test("migration : l'ancien fond de fiche « jeu » passe une fois sur « uni », un choix refait ensuite est gardé", function(B)
	local ns = B.demarrer()
	T.eq(ns.Reglages.lire("fiche.fond"), "uni", "nouveau départ : uni")
	-- comme une sauvegarde d'avant la migration
	MesAddonsDB.reglages.fiche.fond = "jeu"
	MesAddonsDB.migrations = nil
	ns = B.recharger()
	T.eq(ns.Reglages.lire("fiche.fond"), "uni", "migré")
	ns.Reglages.ecrire("fiche.fond", "jeu")
	ns = B.recharger()
	T.eq(ns.Reglages.lire("fiche.fond"), "jeu", "choix refait : gardé")
	T.sans_erreur()
end)

T.fin()
