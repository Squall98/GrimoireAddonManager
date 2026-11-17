-- Journal de débogage interne et mémorisation des personnages.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

T.test("le démarrage est écrit au journal, dans les deux langues", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	local j = MesAddonsDB.journal
	T.eq(j[1].k, "journal.demarrage")
	T.vrai(ns.Journal.formater(j[1]):find("Démarrage v1.2.0"))
	ns = B.demarrer({ locale = "enUS" })
	T.vrai(ns.Journal.formater(MesAddonsDB.journal[1]):find("Starting v1.2.0"))
end)

T.test("taille maximale respectée (réglage)", function(B)
	local ns = B.demarrer()
	ns.Reglages.ecrire("journal.taille_max", 5)
	ns.Reglages.ecrire("journal.dedoublonner", false)
	for i = 1, 20 do ns.Journal.ecrire("info", "journal.langue", "x" .. i) end
	T.eq(#MesAddonsDB.journal, 5)
	T.eq(MesAddonsDB.journal[5].a1, "x20", "les plus récentes sont gardées")
end)

T.test("les lignes identiques se regroupent (x3)", function(B)
	local ns = B.demarrer()
	for _ = 1, 3 do ns.Journal.ecrire("avertissement", "journal.langue", "pareil") end
	local l = MesAddonsDB.journal[#MesAddonsDB.journal]
	T.eq(l.x, 3)
	T.vrai(ns.Journal.formater(l):find("(x3)", 1, true))
end)

T.test("niveau minimal et journal coupé", function(B)
	local ns = B.demarrer()
	local avant = #MesAddonsDB.journal
	ns.Journal.ecrire("debug", "journal.langue", "bruit")
	T.eq(#MesAddonsDB.journal, avant, "debug ignoré au niveau info")
	ns.Reglages.ecrire("journal.actif", false)
	ns.Journal.ecrire("erreur", "journal.langue", "x")
	T.eq(#MesAddonsDB.journal, avant, "rien écrit quand le journal est coupé")
end)

T.test("les erreurs de l'add-on sont attrapées sans casser le gestionnaire d'erreurs du jeu", function(B)
	local ns = B.demarrer()
	local recu = {}
	-- le jeu (ou BugSack) avait son gestionnaire avant nous : B.gestionnaire est maintenant le nôtre qui le chaîne
	local avant = #B.erreurs_jeu
	B.gestionnaire("Interface/AddOns/GrimoireAddonManager/Core/Truc.lua:12: oups")
	B.gestionnaire("Interface/AddOns/AutreAddon/Machin.lua:3: pas pour nous")
	T.eq(#B.erreurs_jeu, avant + 2, "le gestionnaire d'origine reçoit tout")
	local erreurs = 0
	for _, l in ipairs(MesAddonsDB.journal) do if l.n == "erreur" then erreurs = erreurs + 1 recu[#recu + 1] = l.a1 end end
	T.eq(erreurs, 1, "seule notre erreur est au journal")
	T.vrai(recu[1]:find("Truc.lua:12"))
	B.erreurs_jeu = {}
end)

T.test("Journal.proteger : une erreur interne va au journal et n'arrête rien", function(B)
	local ns = B.demarrer()
	local ok = ns.Journal.proteger(function() error("boum") end)
	T.faux(ok)
	local l = MesAddonsDB.journal[#MesAddonsDB.journal]
	T.eq(l.n, "erreur")
	T.vrai(l.a1:find("boum"))
end)

T.test("/mesaddons journal affiche et efface", function(B)
	B.demarrer()
	B.chat = {}
	B.slash("/mesaddons journal")
	T.vrai(B.chat_contient("Journal :"))
	T.vrai(B.chat_contient("Démarrage v1.2.0"))
	B.chat = {}
	B.slash("/mesaddons journal effacer")
	T.vrai(B.chat_contient("Journal vidé."))
	T.eq(#MesAddonsDB.journal, 0)
end)

T.test("journal gardé après /reload", function(B)
	B.demarrer()
	B.recharger()
	local n = 0
	for _, l in ipairs(MesAddonsDB.journal) do if l.k == "journal.demarrage" then n = n + (l.x or 1) end end
	T.eq(n, 2, "deux démarrages notés")
end)

T.test("personnages : mémorisés par GUID dans le compte, journal du perso à part", function(B)
	B.demarrer({ guid = "Player-1-AAAA", nom = "Un", faction = "Horde" })
	B.deconnecter()
	local sauve_compte = B.wtf.compte.MesAddonsDB
	B.nettoyer()
	B.wtf.compte.MesAddonsDB = sauve_compte
	B.demarrer({ guid = "Player-1-BBBB", nom = "Deux", faction = "Alliance" })
	local p = MesAddonsDB.personnages
	T.eq(p["Player-1-AAAA"].nom, "Un")
	T.eq(p["Player-1-BBBB"].faction, "Alliance")
	-- la variable du personnage est propre à chacun
	MesAddonsPersoDB.note = "deux"
	B.deconnecter()
	T.eq(B.wtf.perso["Player-1-BBBB/MesAddonsPersoDB"] ~= nil, true)
	T.eq(B.wtf.perso["Player-1-AAAA/MesAddonsPersoDB"] ~= nil, true, "le premier perso a aussi sa variable")
end)

T.test("la mémorisation des personnages peut être coupée", function(B)
	B.demarrer()
	B.deconnecter()
	local s = B.wtf.compte.MesAddonsDB
	local copie = deserialiser
	B.nettoyer(); B.wtf.compte.MesAddonsDB = s
	local ns = B.demarrer({ guid = "Player-1-CCCC" })
	T.vrai(MesAddonsDB.personnages["Player-1-CCCC"], "mémorisé par défaut")
	ns.Reglages.ecrire("personnages.memoriser", false)
	B.recharger({ guid = "Player-1-DDDD" })
	T.faux(MesAddonsDB.personnages["Player-1-DDDD"], "non mémorisé une fois coupé")
end)

T.test("/mesaddons version affiche version, langue et nombre de fiches", function(B)
	B.demarrer()
	B.chat = {}
	B.slash("/mesaddons version")
	T.vrai(B.chat_contient("v1.2.0, interface 16001, langue Français, 102 fiches"))
end)

T.fin()
