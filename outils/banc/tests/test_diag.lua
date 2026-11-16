-- B5-02 : /maa diag s'exécute au banc sans erreur, note son résultat et laisse les add-ons dans l'état de départ.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

T.test("diag écrit un titre, des sections et note le résultat dans la sauvegarde", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	B.slash("/maa diag")
	T.vrai(B.chat_contient("Diagnostic"), "titre")
	T.vrai(B.chat_contient("Fonctions et objets du jeu"), "section fonctions")
	local d = ns.Reglages.compte.diagnostic
	T.vrai(d and d.total and d.total > 20, "résultat noté")
	T.vrai(#d.lignes > 20, "lignes notées")
end)

T.test("diag laisse l'état d'activation de l'add-on comme avant", function(B)
	local ns = B.demarrer({ locale = "enUS" })
	local avant = C_AddOns.GetAddOnEnableState(ns.nom, ns.guid)
	B.slash("/maa diag")
	T.eq(C_AddOns.GetAddOnEnableState(ns.nom, ns.guid), avant)
end)

T.test("trace : /maa trace note la place des morceaux à chaque repli, puis s'arrête", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	ns.Fenetre.ouvrir()
	B.slash("/maa trace")
	T.vrai(B.chat_contient("Trace allumée"))
	ns.Vue.replierFiche:Click()
	ns.Vue.replierFiche:Click()
	T.sans_erreur()
	local t = ns.Reglages.compte.trace
	T.vrai(#t >= 3, "mesures notées")
	local derniere = t[#t]
	T.vrai(derniere.liste and derniere.liste:find("vu=", 1, true), "mesure de la liste")
	T.vrai(derniere.reglages:find("fiche_repliee", 1, true))
	B.slash("/maa trace")
	T.vrai(B.chat_contient("Trace arrêtée"))
	local n = #t
	ns.Vue.replierFiche:Click()
	T.eq(#ns.Reglages.compte.trace, n, "plus rien noté")
	ns.Vue.replierFiche:Click()
end)

T.fin()
