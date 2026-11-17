-- Antisèche : toutes les commandes (celles de ce gestionnaire, celles citées dans la fiche de chaque add-on, celles
-- que le jeu connaît en plus), écrites dans le chat ou lancées. Réglages : ns.donnees.reglages.aide et `aide.*`.
local _, ns = ...
local A = {}
ns.Aide = A

local function cfg() return ns.donnees.reglages.aide end
local function lire(chemin) return ns.Reglages.lire("aide." .. chemin) end

local function rogner(texte) return (string.match(texte or "", "^%s*(.-)%s*$")) end

-- Clé de comparaison : minuscules, sans accents (comme la recherche de la liste).
local function cle(texte) return ns.Liste.cleTri(texte) end

-- Lettres et chiffres seulement, en minuscules : sert à rapprocher le nom d'un add-on de la clé d'une commande.
local function lettres(texte) return (string.gsub(string.lower(texte or ""), "[^%w]", "")) end

------------------------------------------------------------------ lecture d'un texte de commandes de fiche
-- Coupe « /bgr (ou /baganator), /bgrs <mot> pour chercher » aux virgules qui ne sont pas entre parenthèses.
function A.segments(texte)
	local c, res, profondeur, debut = cfg(), {}, 0, 1
	texte = texte or ""
	for i = 1, #texte do
		local car = string.sub(texte, i, i)
		if car == c.ouvrant then
			profondeur = profondeur + 1
		elseif car == c.fermant then
			profondeur = math.max(0, profondeur - 1)
		elseif car == c.separateur and profondeur == 0 then
			res[#res + 1] = rogner(string.sub(texte, debut, i - 1))
			debut = i + 1
		end
	end
	res[#res + 1] = rogner(string.sub(texte, debut))
	local propres = {}
	for _, s in ipairs(res) do if s ~= "" then propres[#propres + 1] = s end end
	return propres
end

-- Une ligne par segment : { cmd = "/atr", ecrit = "/atr ", desc = "(ou /auctionator)" } ou { note = "texte" }.
function A.lignesFiche(nom)
	local res = {}
	for _, segment in ipairs(A.segments(ns.FicheModele.champ(nom, "commandes"))) do
		local cmd = string.match(segment, cfg().motif_commande)
		if cmd then
			res[#res + 1] = { cmd = cmd, ecrit = cmd .. " ", desc = rogner(string.sub(segment, #cmd + 1)) }
		else
			res[#res + 1] = { note = segment }
		end
	end
	return res
end

------------------------------------------------------------------ commandes que le jeu connaît
-- { [nom d'add-on] = { "/cmd", ... } } d'après SlashCmdList, pour les add-ons chargés (les commandes du jeu lui-même
-- ne correspondent à aucun add-on et sont ignorées).
function A.detectees()
	local res = {}
	if type(SlashCmdList) ~= "table" then return res end
	local propre = ns.Reglages.technique().cle_commande
	local entrees = ns.Liste.entrees()
	local min = cfg().prefixe_min
	local noms = {}
	for _, e in ipairs(entrees) do
		if not e.moi and C_AddOns.IsAddOnLoaded(e.nom) then noms[#noms + 1] = { e = e, l = lettres(e.nom) } end
	end
	local cles = {}
	for k in pairs(SlashCmdList) do if k ~= propre then cles[#cles + 1] = k end end
	table.sort(cles)
	for _, k in ipairs(cles) do
		local kl = lettres((string.gsub(k, "%d+$", "")))
		local proprietaire
		for _, n in ipairs(noms) do
			if n.l == kl
				or (#kl >= min and string.sub(n.l, 1, #kl) == kl)
				or (#n.l >= min and string.sub(kl, 1, #n.l) == n.l) then
				proprietaire = n.e
				break
			end
		end
		if proprietaire then
			local i = 1
			while _G["SLASH_" .. k .. i] do
				local liste = res[proprietaire.nom] or {}
				res[proprietaire.nom] = liste
				liste[#liste + 1] = _G["SLASH_" .. k .. i]
				i = i + 1
			end
		end
	end
	return res
end

------------------------------------------------------------------ les groupes
-- Nom sous lequel on tape les commandes de ce gestionnaire : la plus courte de celles qui ont pu être enregistrées.
function A.principale()
	local meilleure
	for _, nom in ipairs(ns.Commandes.actives) do
		if not meilleure or #nom < #meilleure then meilleure = nom end
	end
	return meilleure or ns.Reglages.lire("commandes.liste")[1] or string.lower(ns.Reglages.technique().cle_commande)
end

-- Les commandes de ce gestionnaire, groupées d'après `reglages.aide.groupes`.
function A.groupesMiens()
	local res = {}
	local principale = A.principale()
	for _, g in ipairs(cfg().groupes) do
		local lignes = {}
		for _, id in ipairs(g.sous) do
			local cmd = "/" .. principale .. " " .. ns.T("sous." .. id .. ".nom")
			lignes[#lignes + 1] = { cmd = cmd, ecrit = cmd .. " ", desc = ns.T("sous." .. id .. ".desc"), moi = true }
		end
		res[#res + 1] = { titre = ns.T("aide.groupe." .. g.id), lignes = lignes, moi = true }
	end
	return res
end

-- Un groupe par add-on qui a des commandes (fiche, puis commandes détectées en plus), triés par nom.
function A.groupesAddons()
	local res = {}
	local detectees = lire("detecter") and A.detectees() or {}
	local liste = {}
	for _, e in ipairs(ns.Liste.entrees()) do if not e.moi then liste[#liste + 1] = e end end
	table.sort(liste, function(a, b) return a.cle < b.cle end)
	for _, e in ipairs(liste) do
		local actif = ns.Liste.actif(e.nom)
		if actif or lire("montrer_eteints") then
			local lignes = A.lignesFiche(e.nom)
			local connues = {}
			for _, l in ipairs(lignes) do
				if l.cmd then connues[string.lower(l.cmd)] = true end
			end
			for _, texte in ipairs(detectees[e.nom] or {}) do
				if not connues[string.lower(texte)] then
					connues[string.lower(texte)] = true
					lignes[#lignes + 1] = { cmd = texte, ecrit = texte .. " ", desc = "" }
				end
			end
			if #lignes > 0 then
				for _, l in ipairs(lignes) do l.eteint = not actif end
				res[#res + 1] = { titre = e.titre, nom = e.nom, categorie = e.categorie, lignes = lignes, eteint = not actif }
			end
		end
	end
	return res
end

------------------------------------------------------------------ la liste à afficher
-- Lignes d'un groupe qui correspondent à `voulu` (clé déjà préparée) : toutes si le titre du groupe correspond.
local function filtrer(g, voulu)
	if voulu == "" or string.find(cle(g.titre), voulu, 1, true) then return g.lignes end
	local gardes = {}
	for _, l in ipairs(g.lignes) do
		local texte = l.cmd and (l.cmd .. " " .. l.desc) or l.note
		if string.find(cle(texte), voulu, 1, true) then gardes[#gardes + 1] = l end
	end
	return gardes
end

-- Ligne prête pour la fenêtre : { type = "cmd", cmd, ecrit, desc, eteint, moi } ou { type = "note", texte, eteint }.
local function preparer(l)
	if l.cmd then return { type = "cmd", cmd = l.cmd, ecrit = l.ecrit, desc = l.desc, eteint = l.eteint, moi = l.moi } end
	return { type = "note", texte = l.note, eteint = l.eteint }
end

-- Les groupes à montrer selon la portée ("tout", "moi" ou "addons").
local function groupesDe(portee)
	local res = {}
	if portee ~= "addons" then
		for i, g in ipairs(A.groupesMiens()) do
			g.id = cfg().groupes[i].id
			res[#res + 1] = g
		end
	end
	if portee ~= "moi" then for _, g in ipairs(A.groupesAddons()) do res[#res + 1] = g end end
	return res
end

-- Lignes à plat : { type = "groupe", texte }, { type = "cmd", cmd, ecrit, desc, eteint, moi }, { type = "note", texte }.
-- `portee` : "tout", "moi" ou "addons" ; `recherche` : texte tapé (vide = tout).
function A.lignes(portee, recherche)
	local voulu = cle(rogner(recherche))
	local res, total, nombre = {}, 0, 0
	for _, g in ipairs(groupesDe(portee)) do
		local gardes = filtrer(g, voulu)
		if #gardes > 0 then
			nombre = nombre + 1
			res[#res + 1] = { type = "groupe", texte = g.titre, eteint = g.eteint }
			for _, l in ipairs(gardes) do
				local p = preparer(l)
				if p.type == "cmd" then total = total + 1 end
				res[#res + 1] = p
			end
		end
	end
	return res, total, nombre
end

-- Les pages de la fenêtre (un onglet chacune) : { id, titre, section = "moi" | "addons", eteint, total,
-- cartes = { { titre, eteint, total, lignes = { lignes préparées } } } }.
-- Ce gestionnaire : une page par thème (reglages.aide.groupes). Les autres add-ons : une page par catégorie (une carte
-- par add-on) ou une page par add-on, selon le réglage aide.regrouper. La recherche ne garde que ce qui correspond ;
-- une page vide n'est pas rendue. Renvoie les pages et le nombre de commandes.
function A.pages(portee, recherche)
	local c = cfg()
	local voulu = cle(rogner(recherche))
	local pages, index, total = {}, {}, 0
	local parCategorie = lire("regrouper") == c.regroupement_categorie
	local rang = {}
	for i, cat in ipairs(ns.Liste.categories()) do rang[cat.id] = i end
	for _, g in ipairs(groupesDe(portee)) do
		local gardes = filtrer(g, voulu)
		if #gardes > 0 then
			local id, titre, section, r
			if g.moi then
				id, titre, section, r = c.prefixes_page.moi .. g.id, g.titre, c.sections[1], 0
			elseif parCategorie then
				id, titre, section = c.prefixes_page.categorie .. g.categorie, ns.Liste.nomCategorie(g.categorie), c.sections[2]
				r = rang[g.categorie] or math.huge
			else
				id, titre, section, r = c.prefixes_page.addon .. g.nom, g.titre, c.sections[2], 1
			end
			local p = index[id]
			if not p then
				p = { id = id, titre = titre, section = section, cartes = {}, total = 0, eteint = true, rang = r,
					ordre = #pages + 1 }
				index[id] = p
				pages[#pages + 1] = p
			end
			local carte = { titre = g.titre, eteint = g.eteint, total = 0, lignes = {} }
			for _, l in ipairs(gardes) do
				local pl = preparer(l)
				carte.lignes[#carte.lignes + 1] = pl
				if pl.type == "cmd" then carte.total = carte.total + 1 end
			end
			p.cartes[#p.cartes + 1] = carte
			p.total = p.total + carte.total
			p.eteint = (p.eteint and g.eteint) and true or false
			total = total + carte.total
		end
	end
	-- les pages de catégorie suivent l'ordre des catégories de la liste ; les autres gardent le leur
	table.sort(pages, function(a, b)
		if a.rang ~= b.rang then return a.rang < b.rang end
		return a.ordre < b.ordre
	end)
	return pages, total
end

------------------------------------------------------------------ agir sur une commande
-- Écrit le texte dans la zone de saisie du chat, sans l'envoyer. Faux si le jeu n'a pas de zone à offrir.
function A.ecrireDansChat(texte)
	if type(ChatFrame_OpenChat) == "function" then
		ChatFrame_OpenChat(texte)
		return true
	end
	if type(ChatEdit_ChooseBoxForSend) == "function" and type(ChatEdit_ActivateChat) == "function" then
		local boite = ChatEdit_ChooseBoxForSend()
		if boite then
			ChatEdit_ActivateChat(boite)
			boite:SetText(texte)
			return true
		end
	end
	return false
end

-- Fonction du jeu qui répond à « /mot », ou nil.
local function gestionnaire(mot)
	local voulu = string.lower(mot)
	for k, v in pairs(_G) do
		if type(k) == "string" and type(v) == "string" and string.sub(k, 1, 6) == "SLASH_" and string.lower(v) == voulu then
			local clef = string.gsub(string.sub(k, 7), "%d+$", "")
			if SlashCmdList and SlashCmdList[clef] then return SlashCmdList[clef] end
		end
	end
end

-- Lance « /mot arguments » comme si on l'avait tapé. Renvoie vrai si la commande existe et n'a pas planté.
function A.lancer(texte)
	local mot, reste = string.match(rogner(texte), "^(/%S+)%s*(.-)$")
	local f = mot and gestionnaire(mot)
	if not f then return false end
	return (pcall(f, reste or ""))
end

-- Clic sur une ligne de commande ; `executer` = lancer tout de suite (Maj + clic). Renvoie le texte à dire dans la fenêtre.
function A.agir(ligne, executer)
	if executer and lire("executer_maj") then
		if A.lancer(ligne.ecrit) then return ns.T("aide.lance", rogner(ligne.ecrit)) end
		return ns.T("aide.echec", rogner(ligne.ecrit))
	end
	if A.ecrireDansChat(ligne.ecrit) then return ns.T("aide.ecrit", rogner(ligne.ecrit)) end
	ns.dire(ns.T("aide.chat_absent", rogner(ligne.ecrit)))
	return ns.T("aide.chat_absent", rogner(ligne.ecrit))
end
