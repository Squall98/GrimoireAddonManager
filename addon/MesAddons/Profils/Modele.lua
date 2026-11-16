-- Profils : données, ce qui va changer, application, fusion, comparaison, verrous, copie en texte.
-- Sauvegarde du compte : compte.profils = { liste = { [id] = profil }, ordre = { id… }, verrous = { [add-on] = true },
-- actuel = id, amorce = true }. Un profil : { nom, icone, couleur, addons = { dossiers… }, modules = bool, note, pret }.
-- `nom` et `note` sont du texte, ou { fr =, en = } pour les profils prêts (ils suivent la langue tant qu'on ne les change pas).
local _, ns = ...
local P = {}
ns.Profils = P

local function cfg() return ns.donnees.reglages.profils end
local function lire(chemin) return ns.Reglages.lire("profils." .. chemin) end

------------------------------------------------------------------ sauvegarde
local function stock()
	local c = ns.Reglages.compte
	c.profils = c.profils or {}
	local s = c.profils
	s.liste = s.liste or {}
	s.ordre = s.ordre or {}
	s.verrous = s.verrous or {}
	return s
end

local function installe(nom) return ns.Liste.parNom(nom) ~= nil end

-- Les profils prêts du fichier de données, remplis avec les seuls add-ons installés (créés une fois, ou à la demande).
local function creerPret(id, d)
	local addons = {}
	for _, nom in ipairs(d.addons) do
		if installe(nom) then addons[#addons + 1] = nom end
	end
	local s = stock()
	s.liste[id] = {
		nom = ns.Reglages.copie(d.nom), icone = cfg().icones_depart[id] or cfg().icone_defaut,
		couleur = d.couleur or cfg().couleur_defaut, addons = addons, modules = d.avec_modules ~= false,
		note = d.note and ns.Reglages.copie(d.note) or nil, pret = id,
	}
	s.ordre[#s.ordre + 1] = id
end

-- Recrée les profils prêts qui manquent (jamais ceux qui existent). Renvoie le nombre créé.
function P.completerPrets()
	local s = stock()
	local n = 0
	for _, id in ipairs(cfg().ordre_prets) do
		local d = ns.donnees.profils[id]
		if d and not s.liste[id] then
			creerPret(id, d)
			n = n + 1
		end
	end
	return n
end

local function amorcer()
	local s = stock()
	if s.amorce then return s end
	s.amorce = true
	P.completerPrets()
	return s
end

------------------------------------------------------------------ lecture
local function texteLangue(v)
	if type(v) ~= "table" then return v end
	return v[ns.Langue.codeFiche()] or v[ns.Langue.codeFiche(ns.donnees.reglages.langue.repli)] or ""
end

function P.ids()
	local s = amorcer()
	local res = {}
	for _, id in ipairs(s.ordre) do
		if s.liste[id] then res[#res + 1] = id end
	end
	return res
end

function P.estVirtuel(id) return id == cfg().id_tout or id == cfg().id_rien end

-- Profil par son identifiant : les deux profils « Tout » et « Rien » sont toujours là (virtuels, jamais gardés).
function P.obtenir(id)
	if id == cfg().id_tout then
		return { id = id, virtuel = true, nom = ns.T("profil.tout"), icone = cfg().icones_depart[id],
			couleur = cfg().couleur_tout, note = ns.T("profil.tout_note"), addons = {} }
	elseif id == cfg().id_rien then
		return { id = id, virtuel = true, nom = ns.T("profil.rien"), icone = cfg().icones_depart[id],
			couleur = cfg().couleur_rien, note = ns.T("profil.rien_note"), addons = {} }
	end
	local p = amorcer().liste[id]
	if p then p.id = id end
	return p
end

function P.nom(p) return texteLangue(p.nom) end
function P.note(p) return texteLangue(p.note) or "" end
function P.icone(p) return p.icone or cfg().icone_defaut end
function P.couleur(p) return p.couleur or cfg().couleur_defaut end

-- Tous les profils dans l'ordre d'affichage : Tout, Rien, puis les profils gardés.
function P.tous()
	local res = { P.obtenir(cfg().id_tout), P.obtenir(cfg().id_rien) }
	for _, id in ipairs(P.ids()) do res[#res + 1] = P.obtenir(id) end
	return res
end

local function cle(texte) return ns.Liste.cleTri(texte or "") end

-- Retrouve un profil par identifiant, par nom (dans n'importe quelle langue), sinon par début de nom.
function P.trouver(texte)
	texte = string.gsub(string.gsub(texte or "", "^%s+", ""), "%s+$", "")
	if texte == "" then return nil end
	local voulu = cle(texte)
	local debut
	for _, p in ipairs(P.tous()) do
		if string.lower(p.id) == string.lower(texte) then return p end
		local noms = {}
		if type(p.nom) == "table" then
			for _, v in pairs(p.nom) do noms[#noms + 1] = v end
		else
			noms[1] = p.nom
		end
		if p.virtuel then
			for _, code in ipairs(ns.Langue.disponibles()) do
				noms[#noms + 1] = ns.Langue.texte(code, p.id == cfg().id_tout and "profil.tout" or "profil.rien")
			end
		end
		for _, n in ipairs(noms) do
			if cle(n) == voulu then return p end
			if not debut and string.sub(cle(n), 1, #voulu) == voulu then debut = p end
		end
	end
	return debut
end

function P.nombre() return #P.ids() end

------------------------------------------------------------------ verrous (jamais désactivés par un profil)
function P.verrou(nom) return stock().verrous[nom] == true end

function P.basculerVerrou(nom, valeur)
	local v = stock().verrous
	if valeur == nil then valeur = not v[nom] end
	if valeur then v[nom] = true else v[nom] = nil end
	ns.Journal.ecrire("info", valeur and "journal.verrou_pose" or "journal.verrou_retire", nom)
	return valeur
end

function P.verrous()
	local res = {}
	for nom in pairs(stock().verrous) do res[#res + 1] = nom end
	table.sort(res, function(a, b) return cle(a) < cle(b) end)
	return res
end

------------------------------------------------------------------ ce que contient un profil
-- Contenu : { set = { [add-on] = true }, ordre = { add-ons }, absents = { dossiers non installés },
-- deps = { add-ons ajoutés pour une dépendance }, deps_absentes = { { addon =, dep = } } }.
-- Les dépendances requises s'ajoutent d'elles-mêmes (réglage), les modules suivent leur principal (profil `modules`).
function P.contenu(p)
	local r = { set = {}, ordre = {}, absents = {}, deps = {}, deps_absentes = {} }
	local function ajouter(nom)
		if not r.set[nom] then
			r.set[nom] = true
			r.ordre[#r.ordre + 1] = nom
		end
	end
	if p.id == cfg().id_tout then
		for _, e in ipairs(ns.Liste.entrees()) do
			if not e.inutile or e.moi then ajouter(e.nom) end
		end
	elseif p.id ~= cfg().id_rien then
		for _, nom in ipairs(p.addons or {}) do
			local e = ns.Liste.parNom(nom)
			if not e then
				r.absents[#r.absents + 1] = nom
			else
				ajouter(nom)
				if p.modules then
					for _, m in ipairs(e.modules) do
						if not m.inutile then ajouter(m.nom) end
					end
				end
			end
		end
	end
	if lire("dependances_auto") then
		local i = 1
		while i <= #r.ordre do
			local nom = r.ordre[i]
			for _, dep in ipairs({ C_AddOns.GetAddOnDependencies(nom) }) do
				if installe(dep) then
					if not r.set[dep] then
						ajouter(dep)
						r.deps[#r.deps + 1] = dep
					end
				else
					r.deps_absentes[#r.deps_absentes + 1] = { addon = nom, dep = dep }
				end
			end
			-- facultatives : on n'ajoute que celles qui sont installées, sans rien signaler si elles manquent
			if lire("dependances_facultatives") then
				for _, dep in ipairs({ C_AddOns.GetAddOnOptionalDependencies(nom) }) do
					if installe(dep) and not r.set[dep] then
						ajouter(dep)
						r.deps[#r.deps + 1] = dep
					end
				end
			end
			i = i + 1
		end
	end
	return r
end

-- Un profil est incomplet quand il cite un add-on qui n'est plus installé.
function P.absents(p)
	local res = {}
	if p.virtuel then return res end
	for _, nom in ipairs(p.addons or {}) do
		if not installe(nom) then res[#res + 1] = nom end
	end
	return res
end

function P.incomplet(p) return #P.absents(p) > 0 end

-- Combien d'add-ons le profil active (compte des add-ons installés qu'il contient).
function P.taille(p)
	return #P.contenu(p).ordre
end

------------------------------------------------------------------ aperçu : ce qui changerait
local function actifPour(nom, guid)
	if guid then return C_AddOns.GetAddOnEnableState(nom, guid) ~= 0 end
	return ns.Liste.actif(nom)
end

-- mode : nil (le profil remplace l'état) ou "fusion" (le profil s'ajoute, rien ne s'éteint).
-- Renvoie { plus, moins, gardes (verrouillés qui seraient restés allumés), deps, absents, deps_absentes, contenu }.
function P.apercu(p, mode, guid)
	local c = P.contenu(p)
	local res = { plus = {}, moins = {}, gardes = {}, deps = c.deps, absents = c.absents, deps_absentes = c.deps_absentes, contenu = c }
	for _, e in ipairs(ns.Liste.entrees()) do
		local nom = e.nom
		local actif = actifPour(nom, guid)
		local voulu = c.set[nom] == true
		if e.moi then voulu = true end
		if voulu and not actif then
			res.plus[#res.plus + 1] = nom
		elseif actif and not voulu and mode ~= "fusion" then
			if P.verrou(nom) then
				res.gardes[#res.gardes + 1] = nom
			else
				res.moins[#res.moins + 1] = nom
			end
		end
	end
	return res
end

function P.changements(apercu) return #apercu.plus + #apercu.moins end

------------------------------------------------------------------ application
-- Autres personnages connus (mémorisés à leur connexion), sans celui qui joue.
function P.autresPersonnages()
	local res = {}
	for guid, perso in pairs(ns.Personnages.liste()) do
		if guid ~= ns.guid then res[#res + 1] = { guid = guid, nom = perso.nom } end
	end
	table.sort(res, function(a, b) return cle(a.nom or "") < cle(b.nom or "") end)
	return res
end

local function appliquerAutre(perso, p, mode)
	local a = P.apercu(p, mode, perso.guid)
	for _, nom in ipairs(a.plus) do C_AddOns.EnableAddOn(nom, perso.guid) end
	for _, nom in ipairs(a.moins) do C_AddOns.DisableAddOn(nom, perso.guid) end
	return #a.plus + #a.moins
end

-- Applique le profil au personnage qui joue (portée "perso") ou à tous les personnages connus (portée "tous").
-- Renvoie l'aperçu appliqué et le nombre de personnages touchés.
function P.appliquer(p, portee, mode)
	local a = P.apercu(p, mode)
	ns.Liste.lot(a.plus, a.moins)
	local touches = 1
	if portee == "tous" then
		for _, perso in ipairs(P.autresPersonnages()) do
			appliquerAutre(perso, p, mode)
			touches = touches + 1
		end
	end
	if not p.virtuel or mode == nil then stock().actuel = p.id end
	ns.Journal.ecrire("info", mode == "fusion" and "journal.profil_fusionne" or "journal.profil_applique",
		P.nom(p), #a.plus, #a.moins)
	return a, touches
end

function P.actuel()
	local id = stock().actuel
	return id and P.obtenir(id) or nil
end

-- Le profil appliqué correspond-il encore à l'état actuel ? (sinon on dit « modifié »)
function P.actuelModifie()
	local p = P.actuel()
	if not p then return false end
	return P.changements(P.apercu(p)) > 0
end

------------------------------------------------------------------ créer, modifier, supprimer
local function nomUnique(base, sauf)
	base = string.sub(string.gsub(string.gsub(base or "", "^%s+", ""), "%s+$", ""), 1, cfg().nom_max)
	if base == "" then base = ns.T("profil.nom_defaut") end
	local pris = {}
	for _, id in ipairs(P.ids()) do
		if id ~= sauf then pris[cle(P.nom(P.obtenir(id)))] = true end
	end
	pris[cle(ns.T("profil.tout"))] = true
	pris[cle(ns.T("profil.rien"))] = true
	local candidat, i = base, 1
	while pris[cle(candidat)] do
		i = i + 1
		candidat = string.sub(base, 1, cfg().nom_max - #tostring(i) - 3) .. " (" .. i .. ")"
	end
	return candidat
end
P.nomUnique = nomUnique

local function nouvelId()
	local s = stock()
	local i = (s.suivant or 0)
	repeat
		i = i + 1
	until not s.liste[cfg().prefixe_id .. i]
	s.suivant = i
	return cfg().prefixe_id .. i
end

-- Les add-ons activés en ce moment (tous, modules compris) : sert à garder l'état actuel dans un profil.
function P.addonsActifs()
	local res = {}
	for _, e in ipairs(ns.Liste.entrees()) do
		if ns.Liste.actif(e.nom) and not e.moi then res[#res + 1] = e.nom end
	end
	return res
end

-- Nouveau profil. `donnees` : { addons, modules, icone, couleur, note } (sinon l'état actuel). Renvoie le profil, ou nil + clé d'erreur.
function P.creer(nom, donnees)
	local s = amorcer()
	if #s.ordre >= cfg().max then return nil, "profil.erreur_max" end
	donnees = donnees or {}
	local id = nouvelId()
	s.liste[id] = {
		nom = nomUnique(nom), icone = donnees.icone or cfg().icone_defaut, couleur = donnees.couleur or cfg().couleur_defaut,
		addons = donnees.addons or P.addonsActifs(), modules = donnees.modules == true, note = donnees.note,
	}
	s.ordre[#s.ordre + 1] = id
	ns.Journal.ecrire("info", "journal.profil_cree", P.nom(s.liste[id]))
	return P.obtenir(id)
end

-- Remplace le contenu d'un profil par l'état actuel.
function P.enregistrerActuel(p)
	if p.virtuel then return false end
	p.addons = P.addonsActifs()
	p.modules = false
	stock().actuel = p.id
	ns.Journal.ecrire("info", "journal.profil_enregistre", P.nom(p), #p.addons)
	return true
end

function P.renommer(p, nom)
	if p.virtuel then return false end
	p.nom = nomUnique(nom, p.id)
	ns.Journal.ecrire("info", "journal.profil_renomme", P.nom(p))
	return true
end

function P.supprimer(p)
	if p.virtuel then return false end
	local s = stock()
	s.liste[p.id] = nil
	for i = #s.ordre, 1, -1 do
		if s.ordre[i] == p.id then table.remove(s.ordre, i) end
	end
	if s.actuel == p.id then s.actuel = nil end
	ns.Journal.ecrire("info", "journal.profil_supprime", P.nom(p))
	return true
end

-- Icône / couleur suivantes dans les listes du réglage de départ ; `sens` 1 ou -1.
local function suivante(liste, actuel, sens)
	local i = 0
	for k, v in ipairs(liste) do if v == actuel then i = k end end
	return liste[(i - 1 + sens) % #liste + 1]
end

function P.changerIcone(p, sens)
	if p.virtuel then return false end
	p.icone = suivante(cfg().icones, p.icone, sens or 1)
	return true
end

function P.changerCouleur(p, sens)
	if p.virtuel then return false end
	p.couleur = suivante(cfg().couleurs, p.couleur, sens or 1)
	return true
end

-- Retire d'un profil les add-ons désinstallés. Renvoie le nombre retiré.
function P.retirerAbsents(p)
	if p.virtuel then return 0 end
	local garde, n = {}, 0
	for _, nom in ipairs(p.addons) do
		if installe(nom) then garde[#garde + 1] = nom else n = n + 1 end
	end
	p.addons = garde
	if n > 0 then ns.Journal.ecrire("info", "journal.profil_complete", P.nom(p), n) end
	return n
end

------------------------------------------------------------------ comparer deux profils
-- { seulA = {…}, seulB = {…}, commun = {…} } (listes de dossiers, triées).
function P.comparer(a, b)
	local ca, cb = P.contenu(a), P.contenu(b)
	local res = { seulA = {}, seulB = {}, commun = {} }
	for _, nom in ipairs(ca.ordre) do
		if cb.set[nom] then res.commun[#res.commun + 1] = nom else res.seulA[#res.seulA + 1] = nom end
	end
	for _, nom in ipairs(cb.ordre) do
		if not ca.set[nom] then res.seulB[#res.seulB + 1] = nom end
	end
	local function trier(l) table.sort(l, function(x, y) return cle(x) < cle(y) end) end
	trier(res.seulA) trier(res.seulB) trier(res.commun)
	return res
end

------------------------------------------------------------------ copier / coller (texte)
-- Format : une ligne par élément, « ENTETE:TYPE:champ=valeur;champ=valeur », valeurs échappées en %XX.
local function echapper(texte)
	return (string.gsub(tostring(texte or ""), cfg().a_echapper, function(c) return string.format("%%%02X", string.byte(c)) end))
end

local function defaire(texte)
	return (string.gsub(texte or "", "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function liste(noms)
	local t = {}
	for i, n in ipairs(noms) do t[i] = echapper(n) end
	return table.concat(t, ",")
end

local function lireListe(texte)
	local res = {}
	for morceau in string.gmatch(texte or "", "[^,]+") do res[#res + 1] = defaire(morceau) end
	return res
end

local function ligneProfil(p)
	local c = cfg()
	return string.format("%s:%s:nom=%s;icone=%s;couleur=%s;modules=%d;note=%s;addons=%s", c.entete, c.type_profil,
		echapper(P.nom(p)), echapper(p.icone), echapper(p.couleur), p.modules and 1 or 0, echapper(P.note(p)), liste(p.addons or {}))
end

function P.exporter(p)
	return ligneProfil(p)
end

-- Sauvegarde complète : profils, verrous, notes perso et étiquettes, favoris.
function P.exporterTout()
	local c = cfg()
	local s = amorcer()
	local lignes = { c.entete .. ":" .. c.type_sauvegarde }
	for _, id in ipairs(P.ids()) do lignes[#lignes + 1] = ligneProfil(P.obtenir(id)) end
	lignes[#lignes + 1] = c.entete .. ":" .. c.type_verrous .. ":" .. liste(P.verrous())
	local notes = ns.Reglages.compte.fiches and ns.Reglages.compte.fiches.notes or {}
	local noms = {}
	for nom, texte in pairs(notes) do if texte ~= "" then noms[#noms + 1] = nom end end
	table.sort(noms)
	for _, nom in ipairs(noms) do
		lignes[#lignes + 1] = string.format("%s:%s:addon=%s;texte=%s", c.entete, c.type_note, echapper(nom), echapper(notes[nom]))
	end
	local st = ns.Reglages.compte.liste or {}
	local et = {}
	for nom in pairs(st.etiquettes or {}) do et[#et + 1] = nom end
	table.sort(et)
	for _, nom in ipairs(et) do
		lignes[#lignes + 1] = string.format("%s:%s:addon=%s;liste=%s", c.entete, c.type_etiquettes, echapper(nom), liste(st.etiquettes[nom]))
	end
	local fav = {}
	for nom in pairs(st.favoris or {}) do fav[#fav + 1] = nom end
	table.sort(fav)
	lignes[#lignes + 1] = c.entete .. ":" .. c.type_favoris .. ":" .. liste(fav)
	if s.actuel then lignes[#lignes + 1] = c.entete .. ":" .. c.type_actuel .. ":" .. echapper(s.actuel) end
	return table.concat(lignes, c.separateur_enregistrements)
end

local function champs(texte)
	local res = {}
	for cle_, valeur in string.gmatch(texte or "", "([%w_]+)=([^;]*)") do res[cle_] = valeur end
	return res
end

-- Lit une ligne de profil ; renvoie la table des données ou nil.
local function lireProfil(reste)
	local f = champs(reste)
	if not f.nom or f.nom == "" then return nil end
	local couleur = defaire(f.couleur)
	if not string.find(couleur, cfg().motif_couleur) then couleur = cfg().couleur_defaut end
	local addons = lireListe(f.addons)
	while #addons > cfg().addons_max do table.remove(addons) end
	local note = defaire(f.note)
	return {
		nom = defaire(f.nom), icone = defaire(f.icone) ~= "" and defaire(f.icone) or cfg().icone_defaut, couleur = couleur,
		modules = f.modules == "1", addons = addons, note = note ~= "" and note or nil,
	}
end

local function decouper(ligne)
	local c = cfg()
	local entete, type_, reste = string.match(ligne, "^(%w+):(%w+):?(.*)$")
	if entete ~= c.entete then return nil end
	return type_, reste
end

local function lignesDe(texte)
	local res = {}
	texte = string.gsub(texte or "", cfg().separateur_enregistrements, "\n")
	for ligne in string.gmatch((string.gsub(texte, "\r", "")), "[^\n]+") do
		ligne = string.gsub(string.gsub(ligne, "^%s+", ""), "%s+$", "")
		if ligne ~= "" then res[#res + 1] = ligne end
	end
	return res
end

-- Colle un profil ou une sauvegarde complète. Renvoie { profils = n, notes = n, etiquettes = n, verrous = n, favoris = n }
-- ou nil + clé d'erreur. Aucun profil existant n'est écrasé : un nom déjà pris reçoit un numéro.
function P.importer(texte)
	local lignes = lignesDe(texte)
	if #lignes == 0 then return nil, "profil.import_vide" end
	local c = cfg()
	local resultat = { profils = 0, notes = 0, etiquettes = 0, verrous = 0, favoris = 0 }
	local lus = {}
	for _, ligne in ipairs(lignes) do
		local type_, reste = decouper(ligne)
		if not type_ then return nil, "profil.import_invalide" end
		lus[#lus + 1] = { type_, reste }
	end
	local p0 = lus[1][1]
	if p0 ~= c.type_profil and p0 ~= c.type_sauvegarde then return nil, "profil.import_invalide" end
	for _, l in ipairs(lus) do
		local type_, reste = l[1], l[2]
		if type_ == c.type_profil then
			local d = lireProfil(reste)
			if not d then return nil, "profil.import_invalide" end
			local p, err = P.creer(d.nom, d)
			if not p then return nil, err end
			resultat.profils = resultat.profils + 1
			resultat.dernier = p
		elseif type_ == c.type_verrous then
			for _, nom in ipairs(lireListe(reste)) do
				if not P.verrou(nom) then
					P.basculerVerrou(nom, true)
					resultat.verrous = resultat.verrous + 1
				end
			end
		elseif type_ == c.type_note then
			local f = champs(reste)
			if f.addon then
				local compte = ns.Reglages.compte
				compte.fiches = compte.fiches or {}
				compte.fiches.textes = compte.fiches.textes or {}
				compte.fiches.notes = compte.fiches.notes or {}
				compte.fiches.notes[defaire(f.addon)] = string.sub(defaire(f.texte), 1, ns.Reglages.lire("fiche.note_max"))
				resultat.notes = resultat.notes + 1
			end
		elseif type_ == c.type_etiquettes then
			local f = champs(reste)
			if f.addon then
				ns.Recherche.definirEtiquettes(defaire(f.addon), ns.Recherche.analyserEtiquettes(table.concat(lireListe(f.liste), ",")))
				resultat.etiquettes = resultat.etiquettes + 1
			end
		elseif type_ == c.type_favoris then
			for _, nom in ipairs(lireListe(reste)) do
				if not ns.Recherche.favori(nom) then
					ns.Recherche.basculerFavori(nom, true)
					resultat.favoris = resultat.favoris + 1
				end
			end
		end
	end
	ns.Journal.ecrire("info", "journal.profil_importe", resultat.profils, resultat.notes + resultat.etiquettes + resultat.favoris)
	return resultat
end

------------------------------------------------------------------ profil associé à une situation (donjon, raid, champ de bataille)
-- Type d'instance du jeu -> nom de la situation dans les réglages (profils.situation.<nom>).
function P.situationDe(type_instance)
	return cfg().situations[type_instance]
end

function P.profilDeSituation(situation)
	if not situation then return nil end
	local texte = lire("situation." .. situation)
	if not texte or texte == "" then return nil end
	return P.trouver(texte)
end
