-- Commandes : /mesaddons et /maa répondent, /ma (prise par le jeu) est détectée, commandes personnalisables.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

T.test("/mesaddons et /maa répondent (aide)", function(B)
	local ns = B.demarrer()
	T.vrai(B.slash("/mesaddons aide"))
	T.vrai(B.chat_contient("Commandes (écris-les après /mesaddons)"), "titre de l'aide")
	B.chat = {}
	T.vrai(B.slash("/maa aide"))
	T.vrai(B.chat_contient("affiche cette aide"))
	T.eq(#ns.Commandes.actives, 2)
	T.sans_erreur()
end)

T.test("/ma n'est pas à nous : elle reste au jeu", function(B)
	B.demarrer()
	local pris, cle = B.slash("/ma")
	T.eq(cle, "MAINASSISTON")
	T.faux(B.chat_contient("Commandes"), "notre add-on ne répond pas à /ma")
end)

T.test("une commande déjà prise est refusée, signalée et mise au journal", function(B)
	local ns = B.demarrer()
	B.chat = {}
	B.slash("/mesaddons commandes ajouter ma")
	T.vrai(B.chat_contient("/ma : déjà prise (MAINASSISTON)"), "message de refus")
	T.eq(ns.Commandes.refusees.ma, "MAINASSISTON")
	T.faux(SLASH_MESADDONS3, "pas enregistrée")
	local derniere = MesAddonsDB.journal[#MesAddonsDB.journal]
	T.eq(derniere.k, "journal.commande_prise")
	-- toujours rejoignable par les autres noms
	T.vrai(B.slash("/maa version"))
end)

T.test("ajouter puis retirer une commande, conservé après /reload", function(B)
	B.demarrer()
	B.slash("/mesaddons commandes ajouter gestion")
	T.vrai(B.slash("/gestion version"), "nouvelle commande active tout de suite")
	B.recharger()
	T.vrai(B.slash("/gestion version"), "gardée après rechargement")
	B.slash("/mesaddons commandes retirer gestion")
	T.faux(B.slash("/gestion version"), "retirée")
	T.sans_erreur()
end)

T.test("nom de commande invalide refusé", function(B)
	B.demarrer()
	B.chat = {}
	B.slash("/mesaddons commandes ajouter a-b")
	T.vrai(B.chat_contient("Nom de commande invalide"))
end)

T.test("sans argument : ouvre (réglage commandes.sans_argument)", function(B)
	local ns = B.demarrer()
	B.chat = {}
	B.slash("/maa")
	T.vrai(ns.Fenetre.estOuverte(), "la fenêtre s'ouvre (depuis B2-01)")
	T.faux(B.chat_contient("La fenêtre arrive"), "plus de message provisoire")
end)

T.test("mot inconnu : message d'erreur poli avec la commande à taper", function(B)
	B.demarrer()
	B.chat = {}
	B.slash("/maa zzz")
	T.vrai(B.chat_contient("Commande inconnue : zzz. Tape /mesaddons"))
end)

T.test("aucune commande libre : message de chargement adapté", function(B)
	-- les deux noms de départ sont déjà pris par un autre add-on
	B.demarrer({ avant = nil })
	B.deconnecter()
	MesAddonsDB = nil
	B.nettoyer()
	-- on fabrique une sauvegarde où la liste est occupée
	B.effacer_sauvegardes()
	B.wtf.compte.MesAddonsDB = B.serialiser({ reglages = { commandes = { liste = { "ma" }, sans_argument = "ouvrir" } } })
	B.demarrer()
	T.vrai(B.chat_contient("aucune commande n'est libre"))
	T.sans_erreur()
end)

T.fin()
