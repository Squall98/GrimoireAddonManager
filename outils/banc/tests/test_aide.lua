-- B5-01 : antisèche des commandes, visite guidée, mode mini / complet, anglais complet.
local T = dofile((os.getenv("MAA_RACINE") or ".") .. "/outils/banc/test.lua")

local function lignes_de(ns, portee, recherche)
	local l, total, groupes = ns.Aide.lignes(portee or "tout", recherche or "")
	return l, total, groupes
end

local function trouver(liste, cmd)
	for _, l in ipairs(liste) do if l.type == "cmd" and l.cmd == cmd then return l end end
end

------------------------------------------------------------------ lecture des commandes
T.test("un texte de commandes de fiche est coupé aux virgules, pas dans les parenthèses", function(B)
	local ns = B.demarrer()
	local s = ns.Aide.segments("/nf (ou /nao, /naowh), /nfquests (quêtes et rares par zone)")
	T.eq(#s, 2)
	T.eq(s[1], "/nf (ou /nao, /naowh)")
	T.eq(s[2], "/nfquests (quêtes et rares par zone)")
	T.eq(#ns.Aide.segments(""), 0)
	T.eq(#ns.Aide.segments(" /a ,, /b "), 2)
end)

T.test("la ligne d'une fiche donne la commande, son texte et ce qu'on écrira dans le chat", function(B)
	local ns = B.demarrer()
	local l = ns.Aide.lignesFiche("Baganator")
	T.vrai(#l >= 2, "au moins deux commandes")
	T.eq(l[1].cmd, "/bgr")
	T.eq(l[1].ecrit, "/bgr ")
	T.vrai(l[1].desc:find("baganator", 1, true), "alias gardé dans le texte")
	T.eq(l[2].cmd, "/bgrs")
	-- une fiche sans commande, mais avec une indication : simple note, pas cliquable
	local n = ns.Aide.lignesFiche("DialogueUI")
	T.eq(#n, 1)
	T.vrai(n[1].note and not n[1].cmd, "note sans commande")
end)

T.test("les commandes de ce gestionnaire sont toutes dans l'antisèche, une fois chacune", function(B)
	local ns = B.demarrer()
	local liste, total = lignes_de(ns, "moi")
	T.eq(total, #ns.donnees.reglages.sous_commandes)
	local vus = {}
	for _, l in ipairs(liste) do
		if l.type == "cmd" then
			T.vrai(l.cmd:find("^/maa "), "écrite avec la commande du joueur : " .. l.cmd)
			T.faux(vus[l.cmd], "en double : " .. l.cmd)
			vus[l.cmd] = true
		end
	end
	for _, id in ipairs(ns.donnees.reglages.sous_commandes) do
		T.vrai(vus["/maa " .. ns.T("sous." .. id .. ".nom")], "manque : " .. id)
	end
	T.vrai(vus["/maa antiseche"] and vus["/maa visite"], "les deux nouvelles y sont")
end)

T.test("la commande affichée est la plus courte de celles qui marchent (une autre est prise par un autre add-on)", function(B)
	local ns = B.demarrer()
	T.eq(ns.Aide.principale(), "maa")
	_G.SLASH_AUTRE1 = "/maa"
	_G.SlashCmdList.AUTRE = function() end
	ns.Commandes.enregistrer()
	T.eq(ns.Aide.principale(), "mesaddons")
	T.vrai(trouver(lignes_de(ns, "moi"), "/mesaddons profil"))
	T.faux(trouver(lignes_de(ns, "moi"), "/maa profil"))
	_G.SLASH_AUTRE1, _G.SlashCmdList.AUTRE = nil, nil
end)

T.test("les commandes des add-ons viennent des fiches, avec les add-ons éteints grisés ou cachés", function(B)
	local ns = B.demarrer({ addons_actifs = { Baganator = false } })
	local tout = lignes_de(ns, "addons")
	T.vrai(trouver(tout, "/bgr"), "Baganator éteint mais montré")
	T.vrai(trouver(tout, "/bgr").eteint, "grisé")
	T.faux(trouver(tout, "/maa profil"), "portée « add-ons » : pas les nôtres")
	ns.Reglages.ecrire("aide.montrer_eteints", false)
	T.faux(trouver(lignes_de(ns, "addons"), "/bgr"), "caché si le réglage le demande")
end)

T.test("une commande que la fiche ne cite pas est repérée dans le jeu, pour un add-on chargé", function(B)
	local ns = B.demarrer()
	-- le premier add-on chargé qui a une fiche sans commande, ou n'importe quel chargé
	local cible
	for _, e in ipairs(ns.Liste.entrees()) do
		if not e.moi and #ns.Aide.lignesFiche(e.nom) == 0 then cible = e break end
	end
	T.vrai(cible, "un add-on sans commande de fiche")
	B.charge[cible.nom] = true -- le banc ne charge que l'add-on testé : on fait « charger » celui-ci
	local cle = string.upper(cible.nom:gsub("[^%w]", ""))
	_G["SLASH_" .. cle .. "1"] = "/zzdetecte"
	_G.SlashCmdList[cle] = function() end
	local d = ns.Aide.detectees()
	T.vrai(d[cible.nom] and d[cible.nom][1] == "/zzdetecte", "détectée pour " .. cible.nom)
	T.vrai(trouver(lignes_de(ns, "addons"), "/zzdetecte"), "dans l'antisèche")
	ns.Reglages.ecrire("aide.detecter", false)
	T.faux(trouver(lignes_de(ns, "addons"), "/zzdetecte"), "réglage coupé : plus détectée")
	-- une commande du jeu lui-même (aucun add-on de ce nom) n'est pas listée
	_G.SLASH_ZZINCONNU1 = "/zzinconnu"
	_G.SlashCmdList.ZZINCONNU = function() end
	ns.Reglages.ecrire("aide.detecter", true)
	T.faux(trouver(lignes_de(ns, "addons"), "/zzinconnu"), "commande du jeu ignorée")
end)

T.test("la recherche garde les commandes qui correspondent, sans tenir compte des accents ni des majuscules", function(B)
	local ns = B.demarrer()
	local tout, total_tout = lignes_de(ns, "tout")
	local l, total = lignes_de(ns, "tout", "PROFIL")
	T.vrai(total > 0 and total < total_tout, "filtrée")
	T.vrai(trouver(l, "/maa profil"))
	T.faux(trouver(l, "/maa erreurs"))
	-- un groupe entier si son titre correspond
	local g, tg = lignes_de(ns, "moi", "Erreurs et mesures")
	T.vrai(trouver(g, "/maa erreurs") and trouver(g, "/maa cpu"), "groupe entier")
	local rien, zero = lignes_de(ns, "tout", "zzzxqj")
	T.eq(zero, 0)
	T.eq(#rien, 0)
	-- accents ignorés
	T.vrai(trouver(lignes_de(ns, "tout", "antiseche"), "/maa antiseche"))
	T.vrai(select(2, lignes_de(ns, "tout", "quêtes")) == select(2, lignes_de(ns, "tout", "quetes")), "accents ignorés")
end)

------------------------------------------------------------------ la fenêtre
T.test("l'antisèche s'ouvre, se remplit, et un clic écrit la commande dans le chat sans l'envoyer", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	ns.Commandes.executer("antiseche")
	T.vrai(W.estOuverte(), "ouverte par /maa antiseche")
	T.vrai(#W.donnees > 0)
	T.eq(W.donnees[1].type, "groupe")
	local l = trouver(W.donnees, "/maa profil")
	W.cliquer(l, false)
	T.eq(B.chat_saisie, "/maa profil ")
	T.vrai(W.message:GetText():find("/maa profil", 1, true), "message dans la fenêtre")
	-- clic sur une vraie ligne de la page : la commande en doré, sa description dessous
	local r = W.lignesVisibles()[1]
	T.vrai(r and r.ligne.type == "cmd", "une ligne de commande montrée")
	T.eq(r.cmd:GetText(), r.ligne.cmd)
	T.eq(r.desc:GetText(), r.ligne.desc)
	T.vrai(r:GetHeight() == ns.donnees.reglages.interface.aide.hauteur_cmd, "deux étages : commande puis description")
	B.chat_saisie = nil
	r:Click()
	T.eq(B.chat_saisie, r.ligne.ecrit, "clic sur la ligne : écrite dans le chat")
	T.sans_erreur()
end)

T.test("Maj + clic lance la commande tout de suite (réglable)", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	W.ouvrir()
	local avant = ns.Fenetre.mode()
	W.cliquer(trouver(W.donnees, "/maa mini"), true)
	T.vrai(ns.Fenetre.mode() ~= avant, "/maa mini a été lancée")
	T.eq(B.chat_saisie, nil, "rien écrit dans le chat")
	-- réglage coupé : Maj + clic écrit comme un clic simple
	ns.Reglages.ecrire("aide.executer_maj", false)
	local mode = ns.Fenetre.mode()
	W.cliquer(trouver(W.donnees, "/maa mini"), true)
	T.eq(ns.Fenetre.mode(), mode)
	T.eq(B.chat_saisie, "/maa mini ")
	-- commande introuvable : message d'échec, pas d'erreur
	ns.Reglages.ecrire("aide.executer_maj", true)
	W.cliquer({ type = "cmd", cmd = "/zzabsente", ecrit = "/zzabsente " }, true)
	T.vrai(W.message:GetText():find("zzabsente", 1, true))
	T.sans_erreur()
end)

T.test("sans zone de saisie de chat, la commande est dite dans le chat du jeu", function(B)
	local ns = B.demarrer()
	_G.ChatFrame_OpenChat = nil
	ns.AideFenetre.ouvrir()
	ns.AideFenetre.cliquer(trouver(ns.AideFenetre.donnees, "/maa profil"), false)
	T.vrai(B.chat_contient("/maa profil"), "dite dans le chat")
	T.sans_erreur()
end)

T.test("une ligne de groupe ou de note ne fait rien au clic", function(B)
	local ns = B.demarrer()
	ns.AideFenetre.ouvrir()
	ns.AideFenetre.cliquer(ns.AideFenetre.donnees[1], false)
	T.eq(B.chat_saisie, nil)
	T.sans_erreur()
end)

-- Onglets montrés dans la colonne, dans l'ordre : { bouton, page }.
local function onglets(W)
	local res = {}
	for _, b in ipairs(W.onglets) do if b:IsShown() and b.page then res[#res + 1] = b end end
	return res
end

local function onglet_de(W, id)
	for _, b in ipairs(onglets(W)) do if b.page.id == id then return b end end
end

T.test("rangée en pages : un onglet par thème de ce gestionnaire, puis les add-ons par catégorie, une carte par add-on", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	local ra = ns.donnees.reglages.aide
	W.ouvrir()
	local o = onglets(W)
	-- d'abord les thèmes de ce gestionnaire, dans l'ordre des réglages
	for i, g in ipairs(ra.groupes) do
		T.eq(o[i].page.id, ra.prefixes_page.moi .. g.id)
		T.eq(o[i].etiquette:GetText(), ns.T("aide.groupe." .. g.id))
		T.eq(o[i].nombre:GetText(), tostring(#g.sous), "nombre de commandes sur l'onglet")
	end
	-- puis une page par catégorie d'add-ons, chacune avec une carte par add-on
	local suivant = o[#ra.groupes + 1]
	T.vrai(suivant and suivant.page.section == "addons", "les add-ons suivent")
	T.vrai(suivant.page.id:find(ra.prefixes_page.categorie, 1, true) == 1, "rangés par catégorie")
	-- deux titres de section dans la colonne
	T.eq(W.sections[1]:GetText(), ns.T("aideportee.moi"))
	T.eq(W.sections[2]:GetText(), ns.T("aideportee.addons"))
	-- seule la page choisie est montrée à droite
	T.eq(W.page, o[1].page, "première page au départ")
	T.vrai(o[1].halo:IsShown() and not o[2].halo:IsShown(), "onglet actif éclairé")
	T.eq(W.cartes[1].titre:GetText(), ns.T("aide.groupe." .. ra.groupes[1].id))
	T.faux(W.cartes[2] and W.cartes[2]:IsShown(), "une seule carte pour un thème")
	T.eq(#W.lignesVisibles(), #ra.groupes[1].sous)
	-- on choisit la page de la catégorie : une carte par add-on, chacune avec ses commandes
	suivant:Click()
	T.eq(W.page, suivant.page)
	T.vrai(suivant.halo:IsShown() and not o[1].halo:IsShown())
	T.eq(W.cartes[1].titre:GetText():gsub("%s*%(.*%)$", ""), suivant.page.cartes[1].titre)
	for i, c in ipairs(suivant.page.cartes) do T.vrai(W.cartes[i]:IsShown(), "carte " .. c.titre) end
	T.sans_erreur()
end)

T.test("réglage : un onglet par add-on au lieu d'un par catégorie ; l'onglet choisi est gardé après /reload", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	local ra = ns.donnees.reglages.aide
	W.ouvrir()
	ns.Options.definir("aide.regrouper", "addon", "peindre")
	local b = onglet_de(W, ra.prefixes_page.addon .. "Baganator")
	T.vrai(b, "onglet de Baganator")
	T.eq(#b.page.cartes, 1)
	b:Click()
	T.vrai(trouver(W.page.cartes[1].lignes, "/bgr"), "ses commandes")
	T.eq(W.memoire().onglet, b.page.id)
	-- pas d'onglet de catégorie dans ce mode
	for _, x in ipairs(onglets(W)) do T.faux(x.page.id:find(ra.prefixes_page.categorie, 1, true) == 1) end
	local ns2 = B.recharger()
	ns2.AideFenetre.ouvrir()
	T.eq(ns2.AideFenetre.page.id, ra.prefixes_page.addon .. "Baganator", "même onglet à la réouverture")
	T.sans_erreur()
end)

T.test("la recherche filtre toutes les pages : onglet « Résultats » en tête, puis chaque page filtrée", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	local ra = ns.donnees.reglages.aide
	ns.Commandes.executer("antiseche profil")
	T.eq(W.recherche, "profil")
	T.vrai(W.resume:GetText():find("profil", 1, true), "résumé du filtre")
	T.vrai(trouver(W.donnees, "/maa profils"))
	local o = onglets(W)
	T.eq(o[1].page.id, ra.id_resultats, "onglet des résultats en tête")
	T.eq(o[1].etiquette:GetText(), ns.T("aide.onglet_resultats"))
	T.eq(W.page.id, ra.id_resultats, "résultats montrés")
	T.vrai(W.effacer.actif, "bouton pour effacer")
	-- toutes pages confondues : autant de cartes que de pages trouvées (au moins)
	local cartes = 0
	for i = 2, #o do cartes = cartes + #o[i].page.cartes end
	T.eq(#W.page.cartes, cartes)
	-- un onglet pendant la recherche : sa page, filtrée
	local profils = onglet_de(W, ra.prefixes_page.moi .. "profils")
	T.vrai(profils, "le thème Profils a des résultats")
	profils:Click()
	T.eq(W.page.id, profils.page.id)
	o[1]:Click()
	T.eq(W.page.id, ra.id_resultats)
	-- rien trouvé : message, aucune carte
	W.champ:SetText("zzzxqj")
	T.eq(#W.donnees, 0)
	T.vrai(W.vide:IsShown() and W.vide:GetText() == ns.T("aide.vide"))
	T.faux(W.cartes[1]:IsShown())
	-- effacer : retour à l'onglet d'avant, plus d'onglet des résultats
	W.effacer:Click()
	T.eq(W.recherche, "")
	T.eq(W.champ:GetText(), "")
	T.faux(W.vide:IsShown())
	T.eq(W.page.id, ra.prefixes_page.moi .. "profils", "on retrouve l'onglet choisi")
	T.eq(onglets(W)[1].page.id, ra.prefixes_page.moi .. ra.groupes[1].id, "plus d'onglet des résultats")
	T.faux(W.effacer.actif)
	T.sans_erreur()
end)

T.test("choix du contenu : tout, ce gestionnaire, les add-ons", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	local ra = ns.donnees.reglages.aide
	W.ouvrir()
	T.eq(W.porteeActuelle(), "tout")
	W.changerPortee()
	T.eq(W.porteeActuelle(), "moi")
	T.vrai(W.boutonPortee.etiquette:GetText():find(ns.T("aideportee.moi"), 1, true))
	T.eq(#onglets(W), #ra.groupes, "seulement les thèmes")
	W.changerPortee()
	T.eq(W.porteeActuelle(), "addons")
	for _, b in ipairs(onglets(W)) do T.eq(b.page.section, "addons") end
	T.eq(W.page, onglets(W)[1].page, "l'onglet gardé n'existe plus ici : la première page")
	W.changerPortee()
	T.eq(W.porteeActuelle(), "tout")
	T.sans_erreur()
end)

T.test("Maj + clic sur une ligne de la page la lance", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	W.ouvrir()
	local cible
	for _, r in ipairs(W.lignesVisibles()) do if r.ligne.cmd == "/maa mini" then cible = r end end
	T.vrai(cible, "/maa mini sur la première page")
	local avant = ns.Fenetre.mode()
	B.maj = true
	cible:Click()
	B.maj = false
	T.vrai(ns.Fenetre.mode() ~= avant, "lancée")
	T.eq(B.chat_saisie, nil)
	T.sans_erreur()
end)

T.test("fenêtre déplaçable et redimensionnable (bornes), taille et place gardées après /reload, Échap la ferme", function(B)
	local ns = B.demarrer()
	local W = ns.AideFenetre
	local d = ns.donnees.reglages.interface.aide
	W.ouvrir()
	local f = W.cadre
	T.eq(f:GetWidth(), d.largeur, "taille de départ")
	T.eq(f:GetHeight(), d.hauteur)
	T.vrai(W.poignee, "poignée")
	local echap = false
	for _, n in ipairs(UISpecialFrames) do if n == d.nom_cadre then echap = true end end
	T.vrai(echap, "Échap la ferme")
	-- déplacement
	f.GetPoint = function() return "TOPLEFT", UIParent, "BOTTOMLEFT", 90, 650 end
	f._scripts.OnDragStart(f)
	T.vrai(f._deplace)
	f._scripts.OnDragStop(f)
	T.faux(f._deplace)
	-- redimensionnement : la mise en page attend le tour suivant (jamais pendant le changement de taille)
	W.poignee._scripts.OnMouseDown()
	T.vrai(f._redimensionne)
	f:SetSize(900, 640)
	T.vrai(W.prevu, "mise en page reportée")
	W.poignee._scripts.OnMouseUp()
	T.faux(f._redimensionne)
	B.avancer(1)
	T.faux(W.prevu, "faite au tour suivant")
	T.sans_erreur()
	local ns2 = B.recharger()
	local W2 = ns2.AideFenetre
	W2.ouvrir()
	T.eq(W2.cadre:GetWidth(), 900, "taille gardée")
	T.eq(W2.cadre:GetHeight(), 640)
	local p, _, rp, x, y = W2.cadre:GetPoint(1)
	T.eq(p, "TOPLEFT")
	T.eq(rp, "BOTTOMLEFT")
	T.eq(x, 90)
	T.eq(y, 650)
	-- taille hors bornes : ramenée entre la mini et la maxi
	local l, h = W2.limiter(10, 10)
	T.eq(l, d.taille_min.l)
	T.eq(h, d.taille_min.h)
	l, h = W2.limiter(99999, 99999)
	T.vrai(l <= d.taille_max.l and h <= d.taille_max.h, "maxi respectée")
	W2.reinitialiserTaille()
	T.eq(W2.cadre:GetWidth(), d.largeur, "taille oubliée")
	T.sans_erreur()
end)

T.test("le « ? » de l'en-tête ouvre l'antisèche, en version complète comme en version mini", function(B)
	local ns = B.demarrer()
	local F = ns.Fenetre
	F.ouvrir()
	T.vrai(F.boutonAide, "bouton présent")
	T.eq(F.boutonAide.etiquette:GetText(), "?")
	F.boutonAide:Click()
	T.vrai(ns.AideFenetre.estOuverte())
	F.boutonAide:Click()
	T.faux(ns.AideFenetre.estOuverte(), "re-clic : ferme")
	F.definirMini(true)
	T.eq(F.mode(), "mini")
	F.boutonAide:Click()
	T.vrai(ns.AideFenetre.estOuverte())
	T.sans_erreur()
end)

T.test("l'antisèche et la visite sont dans le menu du bouton de minicarte, avec le mode mini", function(B)
	local ns = B.demarrer()
	local textes = {}
	for _, it in ipairs(ns.Rapide.entrees()) do textes[#textes + 1] = it.texte end
	local tout = table.concat(textes, "\n")
	T.vrai(tout:find(ns.T("rapide.antiseche"), 1, true))
	T.vrai(tout:find(ns.T("rapide.visite"), 1, true))
	T.vrai(tout:find(ns.T("rapide.mini"), 1, true))
	for _, it in ipairs(ns.Rapide.entrees()) do
		if it.texte == ns.T("rapide.antiseche") then it.action() end
	end
	T.vrai(ns.AideFenetre.estOuverte())
end)

T.test("raccourcis clavier : antisèche et mode mini", function(B)
	local ns = B.demarrer()
	T.eq(_G["BINDING_NAME_MESADDONS_ANTISECHE"], ns.T("raccourci.antiseche"))
	T.eq(_G["BINDING_NAME_MESADDONS_MINI"], ns.T("raccourci.mini"))
	_G.MesAddonsRaccourci("antiseche")
	T.vrai(ns.AideFenetre.estOuverte())
	ns.Fenetre.ouvrir()
	local mode = ns.Fenetre.mode()
	_G.MesAddonsRaccourci("mini")
	T.vrai(ns.Fenetre.mode() ~= mode)
	_G.MesAddonsRaccourci("mini")
	T.eq(ns.Fenetre.mode(), mode)
	T.sans_erreur()
end)

T.test("les boutons des options ouvrent l'antisèche et relancent la visite", function(B)
	local ns = B.demarrer()
	ns.Options.faireAction("ouvrir_antiseche")
	T.vrai(ns.AideFenetre.estOuverte())
	ns.Options.faireAction("revoir_visite")
	T.vrai(ns.Visite.estActive())
	T.faux(ns.AideFenetre.estOuverte(), "l'antisèche se ferme pour la visite")
	T.sans_erreur()
end)

------------------------------------------------------------------ la visite guidée
local function bulle_visible(ns) return ns.Visite.bulle and ns.Visite.bulle:IsShown() end

T.test("au premier lancement la visite démarre toute seule après un court délai, une seule fois", function(B)
	local ns = B.demarrer({ visite = true })
	T.faux(ns.Visite.estActive(), "pas tout de suite")
	B.avancer(ns.donnees.reglages.aide.delai_visite + 1)
	T.vrai(ns.Visite.estActive(), "démarrée")
	T.vrai(ns.Fenetre.estOuverte(), "fenêtre ouverte pour la visite")
	T.eq(ns.Visite.etape, 1)
	T.vrai(bulle_visible(ns))
	T.eq(ns.Reglages.lire("aide.visite_vue"), true)
	T.sans_erreur()
	-- après un rechargement, plus de visite
	local ns2 = B.recharger({ visite = true })
	B.avancer(30)
	T.faux(ns2.Visite.estActive(), "pas rejouée")
end)

T.test("la visite montre 5 bulles dans l'ordre, chacune sur sa partie de la fenêtre", function(B)
	local ns = B.demarrer({ visite = true })
	local V = ns.Visite
	V.demarrer()
	local etapes = ns.donnees.reglages.aide.visite
	T.eq(V.nombre(), 5)
	for i, e in ipairs(etapes) do
		T.eq(V.etape, i)
		T.eq(V.titre:GetText(), ns.T("visite." .. e.id .. ".titre"))
		T.vrai(V.texte:GetText() ~= "" and V.texte:GetText() ~= "visite." .. e.id .. ".texte", "texte traduit")
		T.eq(V.compteur:GetText(), i .. " / 5")
		local cible = ns.Fenetre[e.cible]
		T.vrai(cible, "cible " .. e.cible)
		-- la bulle est accrochée à la partie montrée et celle-ci est entourée
		local p = V.bulle._points[1]
		T.eq(p[2], cible, "bulle accrochée à " .. e.cible)
		T.eq(V.cadre._points[1][2], cible, "cadre autour de " .. e.cible)
		T.eq(V.boutonPrecedent.actif, i > 1)
		T.eq(V.boutonSuivant.etiquette:GetText(), ns.T(i < 5 and "visite.suivant" or "visite.fin"))
		if i < 5 then V.suivant() end
	end
	-- retour en arrière
	V.precedent()
	T.eq(V.etape, 4)
	V.suivant()
	V.suivant()
	T.faux(V.estActive(), "terminée")
	T.faux(bulle_visible(ns))
	T.vrai(B.chat_contient("/maa " .. ns.T("sous.visite.nom")), "dit comment la revoir")
	T.vrai(B.chat_contient("/maa " .. ns.T("sous.antiseche.nom")), "dit où sont les commandes")
	T.sans_erreur()
end)

T.test("Passer ferme la visite sans message, et la visite ne revient pas", function(B)
	local ns = B.demarrer({ visite = true })
	local V = ns.Visite
	V.demarrer()
	V.suivant()
	V.boutonPasser:Click()
	T.faux(V.estActive())
	T.faux(bulle_visible(ns))
	T.faux(B.chat_contient(ns.T("sous.visite.nom")), "pas de message d'au revoir")
	T.eq(ns.Reglages.lire("aide.visite_vue"), true)
end)

T.test("en version mini, la visite passe en version complète puis remet la version mini", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	ns.Fenetre.definirMini(true)
	ns.Commandes.executer(ns.T("sous.visite.nom"))
	T.eq(ns.Fenetre.mode(), "complet", "complète pendant la visite")
	T.vrai(ns.Fenetre.panneauFiche:IsShown() and ns.Fenetre.panneauCats:IsShown(), "les deux panneaux montrés")
	for _ = 1, 5 do ns.Visite.suivant() end
	T.eq(ns.Fenetre.mode(), "mini", "mini remise")
	T.eq(ns.Reglages.lire("fenetre.compact"), true)
	-- visite passée au milieu : même retour
	ns.Commandes.executer(ns.T("sous.visite.nom"))
	ns.Visite.terminer(false)
	T.eq(ns.Fenetre.mode(), "mini")
end)

T.test("fermer la fenêtre pendant la visite arrête la visite", function(B)
	local ns = B.demarrer()
	ns.Visite.demarrer()
	ns.Fenetre.fermer()
	T.faux(ns.Visite.estActive())
	T.faux(bulle_visible(ns))
end)

T.test("en combat la visite attend la fin du combat ; réglage coupé : jamais", function(B)
	local ns = B.demarrer({ visite = true })
	B.en_combat = true
	B.avancer(ns.donnees.reglages.aide.delai_visite + 1)
	T.faux(ns.Visite.estActive(), "pas en combat")
	B.en_combat = false
	B.evenement("PLAYER_REGEN_ENABLED")
	T.vrai(ns.Visite.estActive(), "démarrée à la fin du combat")
	-- réglage coupé
	local ns2 = B.demarrer({ visite = true })
	ns2.Reglages.ecrire("aide.visite_auto", false)
	B.avancer(30)
	T.faux(ns2.Visite.estActive())
end)

T.test("revoir la visite : possible quand on veut, même déjà vue ; pas deux visites en même temps", function(B)
	local ns = B.demarrer()
	T.eq(ns.Reglages.lire("aide.visite_vue"), true)
	ns.Visite.demarrer()
	T.eq(ns.Visite.etape, 1)
	ns.Visite.suivant()
	ns.Visite.demarrer()
	T.eq(ns.Visite.etape, 2, "second lancement ignoré")
	T.sans_erreur()
end)

------------------------------------------------------------------ mode mini / complet
T.test("la version mini montre la liste seule, la complète les trois panneaux, chacune garde sa taille", function(B)
	local ns = B.demarrer()
	local F = ns.Fenetre
	F.ouvrir()
	T.eq(F.mode(), "complet")
	T.vrai(F.panneauCats:IsShown() and F.panneauFiche:IsShown())
	local l_complet = F.cadre:GetWidth()
	F.boutonMode:Click()
	T.eq(F.mode(), "mini")
	T.faux(F.panneauCats:IsShown() or F.panneauFiche:IsShown(), "liste seule")
	T.vrai(F.panneauListe:IsShown())
	T.vrai(F.cadre:GetWidth() < l_complet, "plus étroite")
	T.eq(F.boutonMode.etiquette:GetText(), ns.T("fenetre.vers_complet"))
	F.boutonMode:Click()
	T.eq(F.mode(), "complet")
	T.eq(F.cadre:GetWidth(), l_complet, "taille retrouvée")
	T.eq(F.boutonMode.etiquette:GetText(), ns.T("fenetre.vers_mini"))
	-- le mode choisi est gardé d'une session à l'autre
	F.boutonMode:Click()
	local ns2 = B.recharger()
	ns2.Fenetre.ouvrir()
	T.eq(ns2.Fenetre.mode(), "mini")
	T.sans_erreur()
end)

T.test("le mode mini se règle aussi par la commande et par la case des options", function(B)
	local ns = B.demarrer()
	ns.Fenetre.ouvrir()
	B.slash("/maa mini")
	T.eq(ns.Fenetre.mode(), "mini")
	B.slash("/maa mini")
	T.eq(ns.Fenetre.mode(), "complet")
	ns.Options.definir("fenetre.compact", true, "mini")
	T.eq(ns.Fenetre.mode(), "mini")
end)

------------------------------------------------------------------ l'anglais est complet à l'écran
local ACCENTS = "\195[\128-\191]" -- toute lettre accentuée (UTF-8, de À à ÿ)
local MOTS = { "le", "la", "les", "des", "une", "est", "pour", "avec", "sans", "dans", "sur", "ou", "que", "qui", "pas", "tes", "ses" }

-- Texte français qui traîne dans un cadre : renvoie (cadre, texte) ou nil. Les lignes de la liste (titres et notes des
-- add-ons, écrits par leurs auteurs) et le nom du produit ne comptent pas.
local function reste_de_francais(B, ignorer)
	for _, c in ipairs(B.cadres) do
		local t = c._texte
		if c._type == "FontString" and type(t) == "string" and t ~= "" and not (ignorer and ignorer(c, t)) then
			local propre = t:gsub("Mes Add%-ons", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			if propre:find(ACCENTS) then return c, t end
			local bas = " " .. propre:lower():gsub("[%p]", " ") .. " "
			for _, m in ipairs(MOTS) do
				if bas:find(" " .. m .. " ", 1, true) then return c, t end
			end
		end
	end
end

T.test("en anglais, tout ce que l'antisèche et la visite affichent est en anglais", function(B)
	local ns = B.demarrer({ locale = "enUS", visite = true })
	ns.AideFenetre.ouvrir()
	local c, t = reste_de_francais(B)
	T.faux(c, "antisèche : reste de français : " .. tostring(t))
	for i = 1, ns.Visite.nombre() do
		if not ns.Visite.estActive() then ns.Visite.demarrer() end
		T.eq(ns.Visite.etape, i)
		local c2, t2 = reste_de_francais(B)
		T.faux(c2, "visite étape " .. i .. " : reste de français : " .. tostring(t2))
		ns.Visite.suivant()
	end
	T.vrai(B.chat_contient("tour"), "fin de visite en anglais")
	for _, l in ipairs(B.chat_texte()) do
		T.faux(l:find(ACCENTS), "chat en français : " .. l)
	end
end)

T.test("en anglais, la fenêtre principale, la fiche, les profils, les options, les erreurs et le menu sont en anglais", function(B)
	local ns = B.demarrer({ locale = "enUS" })
	ns.Fenetre.ouvrir()
	ns.ProfilsUI.ouvrir()
	ns.ErreursFenetre.ouvrir()
	ns.Options.faireAction("ouvrir_antiseche")
	ns.Rapide.ouvrir()
	local ignorer = function(c)
		-- le titre et les notes des add-ons viennent de leurs auteurs
		local p = c._parent
		return p and p._type == "Button" and p._parent == ns.Fenetre.panneauListe
	end
	local c, t = reste_de_francais(B, ignorer)
	T.faux(c, "reste de français : " .. tostring(t))
end)

T.test("en français, le même passage ne montre pas d'anglais oublié (clés brutes)", function(B)
	local ns = B.demarrer({ locale = "frFR" })
	ns.Fenetre.ouvrir()
	ns.AideFenetre.ouvrir()
	ns.Visite.demarrer()
	for _, c in ipairs(B.cadres) do
		local t = c._texte
		if c._type == "FontString" and type(t) == "string" then
			T.faux(t:find("^aide%.") or t:find("^visite%.") or t:find("^rapide%."), "clé de texte brute affichée : " .. t)
		end
	end
	T.sans_erreur()
end)

T.fin()
