-- Sous-commande « diag » : vérifie en jeu les points incertains de l'API (fonctions, images, réglages, activation par GUID,
-- raisons de non-chargement, raccourcis). La liste des vérifications vient de reglages.json › diagnostic.
-- Le résultat s'écrit dans le chat et dans la sauvegarde (MesAddonsDB › diagnostic), que Claude peut relire.
local _, ns = ...
local D = {}
ns.Diag = D
local sous = ns.Commandes.sous

local function reglage() return ns.donnees.reglages.diagnostic or {} end

local function resoudre(chemin)
	local obj = _G
	for mot in string.gmatch(chemin, "[^%.]+") do
		if type(obj) ~= "table" then return nil end
		obj = obj[mot]
	end
	return obj
end

function D.lancer()
	local cfg = reglage()
	local lignes, total, echecs = {}, 0, 0
	local function noter(ok, cle, ...)
		total = total + 1
		if ok == false then echecs = echecs + 1 end
		local modele = (ok == nil) and "diag.info" or (ok and "diag.ok" or "diag.ko")
		lignes[#lignes + 1] = ns.T(modele, ns.T(cle, ...))
	end
	local function section(cle) lignes[#lignes + 1] = "|cffffd100" .. ns.T(cle) .. "|r" end

	section("diag.sect.divers")
	local version, build, _, interface = GetBuildInfo()
	noter(nil, "diag.version_jeu", tostring(version), tostring(build), tostring(interface))
	noter(nil, "diag.interface", ns.nom, tostring(C_AddOns.GetAddOnMetadata(ns.nom, "Interface")) .. " / " .. tostring(C_AddOns.GetAddOnInterfaceVersion and C_AddOns.GetAddOnInterfaceVersion(ns.nom)))
	for _, nom in ipairs(cfg.cadres or {}) do
		local f = resoudre(nom)
		if f and f.IsShown then noter(nil, "diag.cadre", nom, ns.T(f:IsShown() and "diag.cadre_montre" or "diag.cadre_cache"))
		else noter(false, "diag.cadre", nom, "?") end
	end
	local cat = ns.Options and ns.Options.categorie
	if cat then
		noter(true, "diag.page", tostring(cat.GetID and cat:GetID() or cat.ID))
	else
		noter(false, "diag.page_absente")
	end

	-- la fiche doit exister pour être mesurée : on construit la fenêtre et on montre un add-on s'il le faut
	if ns.Fenetre and ns.Fenetre.construire then pcall(ns.Fenetre.construire) end
	if ns.Vue and ns.Vue.pret and not ns.Vue.selection then
		local premier = ns.Liste.lesRacines()[1]
		if premier then
			ns.Vue.selection = premier.nom
			pcall(ns.Vue.rafraichirFiche)
		end
	end
	local titre = ns.Parchemin and ns.Parchemin.f and ns.Parchemin.f.titre
	if not titre then noter(false, "diag.parchemin_absent") end
	-- couleur réellement posée sur le texte du résumé, et opacité de chaque cadre parent jusqu'à la fenêtre
	local resume = ns.Parchemin and ns.Parchemin.f and ns.Parchemin.f.resume
	if resume and resume.GetTextColor then
		local r, g, b, a = resume:GetTextColor()
		local chaine, cadre = {}, resume:GetParent()
		while cadre and #chaine < 8 do
			chaine[#chaine + 1] = string.format("%.2f", cadre.GetAlpha and cadre:GetAlpha() or -1)
			cadre = cadre.GetParent and cadre:GetParent()
		end
		noter(nil, "diag.parchemin_resume", r or -1, g or -1, b or -1, a or 1,
			string.format("%.2f", resume.GetAlpha and resume:GetAlpha() or -1), table.concat(chaine, " > "),
			tostring(resume.GetDrawLayer and resume:GetDrawLayer()), tostring(resume:GetText()))
	end
	if titre and titre.GetTextColor then
		local r, g, b, a = titre:GetTextColor()
		local parent = titre:GetParent()
		-- GetEffectiveAlpha n'existe pas sur un texte dans ce client : on prend celle du cadre parent
		local porteur = titre.GetEffectiveAlpha and titre or parent
		local effective = porteur and porteur.GetEffectiveAlpha and porteur:GetEffectiveAlpha() or -1
		noter(nil, "diag.parchemin", r or -1, g or -1, b or -1, a or 1, effective,
			tostring(parent and parent:GetFrameLevel()), tostring(parent and parent:GetParent() and parent:GetParent():GetFrameLevel()))
	end

	section("diag.sect.fonctions")
	for _, nom in ipairs(cfg.fonctions or {}) do noter(resoudre(nom) ~= nil, "diag.fonction", nom) end

	section("diag.sect.images")
	local test = UIParent:CreateTexture()
	local vues, chemins = {}, {}
	local function collecter(o)
		if type(o) == "string" then
			if #o > #cfg.prefixe_chemin and string.sub(o, 1, #cfg.prefixe_chemin) == cfg.prefixe_chemin and not vues[o] then
				vues[o] = true
				chemins[#chemins + 1] = o
			end
		elseif type(o) == "table" then
			for _, v in pairs(o) do collecter(v) end
		end
	end
	collecter(ns.donnees.reglages)
	table.sort(chemins)
	for _, chemin in ipairs(chemins) do
		test:SetTexture(nil)
		test:SetTexture(chemin)
		noter(test:GetTexture() ~= nil, "diag.image", chemin)
	end
	local atlas = {}
	for _, e in pairs(ns.donnees.reglages.emblemes or {}) do
		for _, a in ipairs(e.atlas or {}) do atlas[#atlas + 1] = a end
	end
	table.sort(atlas)
	for _, a in ipairs(atlas) do
		noter(C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(a) ~= nil, "diag.atlas", a)
	end

	section("diag.sect.cvar")
	for _, nom in ipairs(cfg.reglages_cvar or {}) do
		local ok, valeur = pcall(GetCVar, nom)
		if ok and valeur ~= nil then noter(true, "diag.cvar", nom, tostring(valeur)) else noter(false, "diag.cvar_absent", nom) end
	end

	section("diag.sect.guid")
	local cibles = {}
	if ns.guid then cibles[#cibles + 1] = { guid = ns.guid, nom = UnitName("player") } end
	for guid, p in pairs(ns.Personnages.liste()) do
		if guid ~= ns.guid then cibles[#cibles + 1] = { guid = guid, nom = p.nom } end
	end
	if #cibles == 1 then noter(nil, "diag.guid_aucun") end
	for _, c in ipairs(cibles) do
		local avant = C_AddOns.GetAddOnEnableState(ns.nom, c.guid)
		local ok1, err1 = pcall(C_AddOns.DisableAddOn, ns.nom, c.guid)
		local eteint = C_AddOns.GetAddOnEnableState(ns.nom, c.guid)
		local ok2, err2 = pcall(C_AddOns.EnableAddOn, ns.nom, c.guid)
		local apres = C_AddOns.GetAddOnEnableState(ns.nom, c.guid)
		if not ok2 then pcall(C_AddOns.EnableAddOn, ns.nom, c.guid) end
		if ok1 and ok2 then
			noter(apres == avant and eteint == 0, "diag.guid_essai", c.nom, c.nom, tostring(avant), tostring(eteint), tostring(apres))
		else
			noter(false, "diag.guid_erreur", c.nom, c.nom, tostring(err1 or err2))
		end
	end

	section("diag.sect.raisons")
	local raisons = {}
	for i = 1, C_AddOns.GetNumAddOns() do
		local _, _, _, _, raison = C_AddOns.GetAddOnInfo(i)
		raison = raison or ""
		raisons[raison] = (raisons[raison] or 0) + 1
	end
	local cles = {}
	for r in pairs(raisons) do cles[#cles + 1] = r end
	table.sort(cles)
	for _, r in ipairs(cles) do
		if r == "" then noter(nil, "diag.raison_vide", raisons[r]) else noter(nil, "diag.raison", r, raisons[r]) end
	end

	section("diag.sect.raccourcis")
	for _, nom in ipairs(cfg.bindings or {}) do
		local touche = GetBindingKey and GetBindingKey(nom)
		if touche then noter(true, "diag.raccourci", nom, touche)
		elseif GetBindingAction and GetBinding then noter(nil, "diag.raccourci_sans", nom)
		else noter(false, "diag.raccourci_absent", nom) end
	end

	return lignes, total, echecs
end

function sous.diag()
	local lignes, total, echecs = D.lancer()
	ns.dire(ns.T("diag.titre", total, echecs))
	for i = 1, math.min(#lignes, reglage().lignes_max or #lignes) do ns.dire(lignes[i]) end
	local compte = ns.Reglages.compte
	if compte then
		compte.diagnostic = { date = date("%Y-%m-%d %H:%M:%S"), total = total, echecs = echecs, lignes = lignes }
		ns.dire(ns.T("diag.sauve"))
	end
end

------------------------------------------------------------------ trace de mise en page (/maa trace)
-- Quand elle est allumée, chaque disposition et chaque rafraîchissement de la liste notent la place, la taille et la
-- visibilité des morceaux de la fenêtre dans MesAddonsDB › trace (relu par Claude après un /reload).
local function cadresSuivis()
	local F, V = ns.Fenetre, ns.Vue
	return {
		corps = F.corps, cats = F.panneauCats, liste = F.panneauListe, fiche = F.panneauFiche,
		barre = ns.Barre.cadre, bandeau = V.bandeau, sf = V.liste and V.liste.sf, contenu = V.liste and V.liste.contenu,
		fleche_g = V.replierCats, fleche_d = V.replierFiche, compteur = V.compteur, titre = V.nomCategorie,
		ligne1 = V.lignes and V.lignes[1], entete1 = V.entetes and V.entetes[1],
	}
end

local function nombre(v)
	v = tonumber(v)
	return v and string.format("%.0f", v) or "nil"
end

local function mesure(o)
	if not o then return "absent" end
	local ok, l, b, w, h = pcall(o.GetRect, o)
	local ancres = {}
	for i = 1, (o.GetNumPoints and o:GetNumPoints() or 0) do
		local pt, rel, relpt, x, y = o:GetPoint(i)
		ancres[#ancres + 1] = string.format("%s>%s:%s(%.0f,%.0f)", tostring(pt), tostring(rel and rel.GetName and rel:GetName() or rel and "cadre" or "nil"), tostring(relpt), tonumber(x) or 0, tonumber(y) or 0)
	end
	return string.format("vu=%s/%s rect=%s,%s,%s,%s ancres=%s",
		tostring(o:IsShown()), tostring(o.IsVisible and o:IsVisible()),
		nombre(ok and l), nombre(ok and b), nombre(ok and w), nombre(ok and h), table.concat(ancres, ";"))
end

function D.tracer(etiquette)
	local c = ns.Reglages.compte
	if not (c and c.trace_actif) then return end
	c.trace = c.trace or {}
	local ligne = { quand = date("%H:%M:%S"), quoi = etiquette,
		reglages = string.format("cats_repliee=%s fiche_repliee=%s mini=%s", tostring(ns.Reglages.lire("fenetre.cats_repliee")),
			tostring(ns.Reglages.lire("fenetre.fiche_repliee")), tostring(ns.Reglages.lire("fenetre.compact"))) }
	local suivis = cadresSuivis()
	for _, nom in ipairs(reglage().trace_cadres or {}) do ligne[nom] = mesure(suivis[nom]) end
	table.insert(c.trace, ligne)
	while #c.trace > (reglage().trace_max or 300) do table.remove(c.trace, 1) end
end

function sous.trace()
	local c = ns.Reglages.compte
	if not c then return end
	if c.trace_actif then
		c.trace_actif = false
		ns.dire(ns.T("trace.off", #(c.trace or {})))
	else
		c.trace_actif, c.trace = true, {}
		ns.dire(ns.T("trace.on"))
		D.tracer("debut")
	end
end
