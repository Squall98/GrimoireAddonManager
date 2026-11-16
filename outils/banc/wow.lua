-- Banc d'essai de Mes Add-ons : imitation minimale de l'API de WoW Forever 1.60.1 pour Lua 5.1, hors du jeu.
-- Ce qui est imité vient de docs/API-FOREVER.md (C_AddOns, SavedVariables, événements, SlashCmdList, cadres, infobulle…).
-- Usage : local B = dofile("outils/banc/wow.lua") ; B.demarrer{ locale="frFR", ... } ; B.slash("/mesaddons aide") ; B.chat

local B = {}
B.racine = os.getenv("MAA_RACINE") or "."

-- Globales d'origine de Lua : tout ce qui apparaît ensuite dans _G est retiré par B.nettoyer().
local d_origine = {}
for k in pairs(_G) do d_origine[k] = true end

local function chemin(rel)
	if rel:match("^%a:[/\\]") or rel:sub(1, 1) == "/" then return rel end
	return B.racine .. "/" .. rel
end

---------------------------------------------------------------- sérialisation (SavedVariables)
local function serialiser(v, marge)
	marge = marge or ""
	local t = type(v)
	if t == "string" then return string.format("%q", v) end
	if t == "number" or t == "boolean" then return tostring(v) end
	if t == "table" then
		local out = {}
		for k, x in pairs(v) do
			local cle = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
			out[#out + 1] = marge .. "\t" .. cle .. " = " .. serialiser(x, marge .. "\t")
		end
		table.sort(out)
		return "{\n" .. table.concat(out, ",\n") .. "\n" .. marge .. "}"
	end
	error("type non sauvegardable : " .. t)
end
B.serialiser = serialiser

local function deserialiser(texte)
	local f = assert(loadstring("return " .. texte))
	setfenv(f, {})
	return f()
end

---------------------------------------------------------------- état de la « machine »
-- Les sauvegardes survivent à B.nettoyer() : c'est le disque du joueur (dossier WTF).
B.wtf = B.wtf or { compte = {}, perso = {} }

function B.nettoyer()
	for k in pairs(_G) do
		if not d_origine[k] and k ~= "B" then _G[k] = nil end
	end
	B.chat, B.sorties, B.erreurs_jeu, B.cadres, B.minuteries, B.xml_ignores = {}, {}, {}, {}, {}, {}
	B.horloge = 1800000000
end

local function lire_instantane()
	local f = assert(loadfile(chemin("outils/banc/addons_installes.lua")))
	return f()
end

---------------------------------------------------------------- cadres
local Cadre = {}
Cadre.__index = function(self, k)
	local v = rawget(Cadre, k)
	if v ~= nil then return v end
	if type(k) == "string" and k:match("^%u") then -- toute autre méthode de cadre : sans effet
		return function(s) return s end
	end
end

function Cadre:RegisterEvent(e) self._evenements[e] = true end
function Cadre:UnregisterEvent(e) self._evenements[e] = nil end
function Cadre:UnregisterAllEvents() self._evenements = {} end
function Cadre:IsEventRegistered(e) return self._evenements[e] == true end
function Cadre:SetScript(nom, f) self._scripts[nom] = f end
function Cadre:GetScript(nom) return self._scripts[nom] end
function Cadre:HookScript(nom, f)
	local ancien = self._scripts[nom]
	self._scripts[nom] = function(...)
		if ancien then ancien(...) end
		return f(...)
	end
end
function Cadre:Show()
	local avant = self._visible
	self._visible = true
	local f = self._scripts.OnShow
	if f and not avant then f(self) end
end
function Cadre:Hide()
	local avant = self._visible
	self._visible = false
	local f = self._scripts.OnHide
	if f and avant then f(self) end
end
function Cadre:IsShown() return self._visible end
function Cadre:IsVisible() return self._visible end
function Cadre:GetName() return self._nom end
function Cadre:GetParent() return self._parent end
function Cadre:SetParent(p) self._parent = p end
function Cadre:SetText(t)
	self._texte = t
	-- comme le jeu : un champ de saisie prévient (saisie = false) quand le code change son texte
	if self._type == "EditBox" then
		local f = self._scripts.OnTextChanged
		if f then f(self, false) end
	end
end
function Cadre:GetText() return self._texte end
local function taille_changee(self)
	local f = self._scripts.OnSizeChanged
	if f then f(self, self._w or 0, self._h or 0) end
end
function Cadre:SetSize(w, h) self._w, self._h = w, h; taille_changee(self) end
function Cadre:GetWidth() return self._w or 0 end
function Cadre:GetHeight() return self._h or 0 end
function Cadre:SetWidth(w) self._w = w; taille_changee(self) end
function Cadre:SetHeight(h) self._h = h; taille_changee(self) end
function Cadre:CreateFontString(nom, calque) return B.creer_cadre("FontString", nil, self) end
function Cadre:CreateTexture(nom, calque) return B.creer_cadre("Texture", nil, self) end
function Cadre:SetTexture(t) self._texture = t end
function Cadre:GetTexture()
	-- comme le jeu : une image qui n'existe pas (témoin « Absent ») ne donne rien
	if type(self._texture) == "string" and B.images_absentes and self._texture:lower():find(B.images_absentes, 1, true) then return nil end
	return self._texture
end
function Cadre:Click()
	if self._actif == false then return end
	if self._type == "CheckButton" then self._coche = not self._coche end
	local f = self._scripts.OnClick
	if f then f(self, "LeftButton") end
end
function Cadre:GetChildren() if self._enfants then return unpack(self._enfants) end end

-- Ajouts de B2-01 : ancres, cases, curseurs, défilement, couleurs, polices (de quoi voir ce que la fenêtre demande au jeu).
function Cadre:SetPoint(point, rel, rpoint, x, y)
	if type(rel) == "number" then x, y, rel, rpoint = rel, rpoint, self._parent, point end
	self._points = self._points or {}
	self._points[#self._points + 1] = { point, rel or self._parent, rpoint or point, x or 0, y or 0 }
end
function Cadre:ClearAllPoints() self._points = {} end
function Cadre:GetPoint(i)
	local p = self._points and self._points[i or 1]
	if p then return unpack(p) end
end
function Cadre:GetNumPoints() return self._points and #self._points or 0 end
function Cadre:SetChecked(v) self._coche = v and true or false end
function Cadre:GetChecked() return self._coche == true end
function Cadre:Enable() self._actif = true end
function Cadre:Disable() self._actif = false end
function Cadre:IsEnabled() return self._actif ~= false end
function Cadre:SetValue(v) self._valeur = v; local f = self._scripts.OnValueChanged; if f then f(self, v) end end
function Cadre:GetValue() return self._valeur or 0 end
function Cadre:SetMinMaxValues(a, b) self._min, self._max = a, b end
function Cadre:GetMinMaxValues() return self._min or 0, self._max or 0 end
function Cadre:SetVerticalScroll(v) self._defil = v end
function Cadre:GetVerticalScroll() return self._defil or 0 end
function Cadre:SetAlpha(a) self._alpha = a end
function Cadre:GetAlpha() return self._alpha or 1 end
function Cadre:SetColorTexture(r, g, b, a) self._couleur = { r, g, b, a or 1 } end
function Cadre:SetVertexColor(r, g, b, a) self._teinte = { r, g, b, a or 1 } end
function Cadre:SetTextColor(r, g, b, a) self._couleur = { r, g, b, a or 1 } end
function Cadre:SetBackdrop(t) self._fond = t end
function Cadre:SetBackdropColor(r, g, b, a) self._couleur_fond = { r, g, b, a or 1 } end
function Cadre:SetBackdropBorderColor(r, g, b, a) self._couleur_bord = { r, g, b, a or 1 } end
function Cadre:SetAtlas(a) self._atlas = a end
function Cadre:SetFont(chemin, taille, contour)
	if B.polices_absentes and chemin:lower():find(B.polices_absentes, 1, true) then return false end
	self._police = { chemin, taille, contour }
	return true
end
function Cadre:IsMouseOver() return false end
-- Ajouts de B2-02 : niveau de cadre, taille d'un texte (estimée : le banc ne dessine rien), champ de saisie.
function Cadre:GetFrameLevel() return 1 end
function Cadre:SetShown(v) if v then self:Show() else self:Hide() end end
function Cadre:SetMaxLetters(n) self._max_lettres = n end
local function lignes_estimees(self)
	local taille = self._police and self._police[2] or 12
	local largeur = self._w and self._w > 0 and self._w or 240
	local par_ligne = math.max(1, math.floor(largeur / (taille * 0.5)))
	local n = 0
	for paragraphe in ((self._texte or "") .. "\n"):gmatch("(.-)\n") do
		n = n + math.max(1, math.ceil(#paragraphe / par_ligne))
	end
	return n, taille
end
function Cadre:GetStringHeight()
	if not self._texte or self._texte == "" then return 0 end
	local n, taille = lignes_estimees(self)
	return n * (taille + 2)
end
function Cadre:GetStringWidth() return #(self._texte or "") * 6 end
function Cadre:GetEffectiveScale() return 1 end
function Cadre:GetCenter() return (self._w or 0) / 2, (self._h or 0) / 2 end
function Cadre:StartMoving() self._deplace = true end
function Cadre:StartSizing() self._redimensionne = true end
function Cadre:StopMovingOrSizing() self._deplace, self._redimensionne = false, false end

function B.creer_cadre(type_, nom, parent)
	local c = setmetatable({ _type = type_, _nom = nom, _parent = parent, _evenements = {}, _scripts = {}, _visible = true }, Cadre)
	B.cadres[#B.cadres + 1] = c
	if nom then _G[nom] = c end
	if parent and type_ ~= "FontString" and type_ ~= "Texture" then
		parent._enfants = parent._enfants or {}
		parent._enfants[#parent._enfants + 1] = c
	end
	return c
end

-- Distribue un événement à tous les cadres qui l'écoutent ; une erreur dans un script va au gestionnaire d'erreurs du jeu.
function B.evenement(nom, ...)
	local liste = {}
	for _, c in ipairs(B.cadres) do
		if c._evenements[nom] and c._scripts.OnEvent then liste[#liste + 1] = c end
	end
	local args = { ... }
	for _, c in ipairs(liste) do
		xpcall(function() c._scripts.OnEvent(c, nom, unpack(args)) end, function(m) return B.erreur_jeu(m) end)
	end
end

function B.erreur_jeu(message)
	local h = B.gestionnaire
	if h then return h(message) end
	return message
end

---------------------------------------------------------------- installation de l'API
local function installer_api(opts)
	local G = _G

	-- utilitaires de WoW (Lua 5.1 + ajouts du jeu)
	G.strlower, G.strupper, G.strsub, G.strfind, G.strlen = string.lower, string.upper, string.sub, string.find, string.len
	G.strmatch, G.strrep, G.strbyte, G.strchar, G.gsub, G.gmatch, G.format = string.match, string.rep, string.byte, string.char, string.gsub, string.gmatch, string.format
	G.tinsert, G.tremove, G.sort, G.wipe = table.insert, table.remove, table.sort, function(t) for k in pairs(t) do t[k] = nil end return t end
	G.floor, G.ceil, G.abs, G.max, G.min, G.mod, G.random = math.floor, math.ceil, math.abs, math.max, math.min, math.fmod, math.random
	G.strtrim = function(s, c) c = c or "%s"; return (s:gsub("^[" .. c .. "]+", ""):gsub("[" .. c .. "]+$", "")) end
	G.strjoin = function(sep, ...) return table.concat({ ... }, sep) end
	G.strsplit = function(sep, s, n)
		local res, i = {}, 1
		while true do
			if n and #res == n - 1 then res[#res + 1] = s:sub(i) break end
			local a, b = s:find(sep, i, true)
			if not a then res[#res + 1] = s:sub(i) break end
			res[#res + 1] = s:sub(i, a - 1)
			i = b + 1
		end
		return unpack(res)
	end
	G.time = function() return B.horloge end
	G.date = function(f, t) return os.date(f, t or B.horloge) end
	G.GetTime = function() return B.horloge - 1800000000 end
	G.debugstack = function() return debug.traceback() end
	G.debugprofilestop = function() return os.clock() * 1000 end

	-- état du joueur
	G.GetLocale = function() return opts.locale end
	G.GetBuildInfo = function() return "1.60.1", "70938", "Nov  1 2026", 16001 end
	G.GetRealmName = function() return opts.royaume end
	G.UnitName = function() return opts.nom end
	G.UnitGUID = function() return opts.guid end
	G.UnitFactionGroup = function() return opts.faction, opts.faction end
	G.UnitClass = function() return opts.classe_nom, opts.classe end
	-- B3-01 : type d'instance simulé (B.instance_type = "party" | "raid" | "pvp" | "arena" | nil), identifiant B.instance_id
	G.IsInInstance = function() return B.instance_type ~= nil, B.instance_type or "none" end
	G.GetInstanceInfo = function() return "Instance", B.instance_type or "none", 1, "", 5, 0, false, B.instance_id or 0 end
	G.Enum = { AddOnEnableState = { None = 0, Some = 1, All = 2 } }

	-- chat
	G.print = function(...)
		local t = {}
		for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
		B.sorties[#B.sorties + 1] = table.concat(t, " ")
	end
	G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, texte) B.chat[#B.chat + 1] = texte end }
	G.ChatFrame1 = G.DEFAULT_CHAT_FRAME

	-- gestionnaire d'erreurs
	B.gestionnaire = function(m) B.erreurs_jeu[#B.erreurs_jeu + 1] = tostring(m) return m end
	G.seterrorhandler = function(f) B.gestionnaire = f end
	G.geterrorhandler = function() return B.gestionnaire end
	G.securecall = function(f, ...) return f(...) end

	-- cadres, infobulle
	G.CreateFrame = function(type_, nom, parent) return B.creer_cadre(type_, nom, parent) end
	G.UIParent = B.creer_cadre("Frame", "UIParent")
	G.UIParent._w, G.UIParent._h = 1600, 900
	G.Minimap = B.creer_cadre("Frame", "Minimap")
	G.Minimap._w, G.Minimap._h = 140, 140
	G.UISpecialFrames = {}
	G.ADDONS = "Add-ons"
	G.C_Texture = { GetAtlasInfo = function(nom) if B.atlas_absents and nom:find(B.atlas_absents, 1, true) then return nil end return { width = 32, height = 32 } end }
	G.GetCursorPosition = function() return 0, 0 end
	-- B3-02 : touche Maj (B.maj = true pour la simuler)
	B.maj = false
	G.IsShiftKeyDown = function() return B.maj end
	-- B5-01 : zone de saisie du chat (B.chat_saisie = dernier texte écrit sans être envoyé)
	B.chat_saisie = nil
	G.ChatFrame_OpenChat = function(texte) B.chat_saisie = texte end
	-- mémoire des add-ons (Ko) : celle qu'un test pose dans B.memoire, 0 sinon
	B.memoire = {}
	G.UpdateAddOnMemoryUsage = function() B.memoire_mesures = (B.memoire_mesures or 0) + 1 end
	G.GetAddOnMemoryUsage = function(nom) return B.memoire[nom] or 0 end
	-- B4-01 : réglages du jeu (CVar), processeur par add-on (ms), combat, son
	B.cvars = B.cvars_sauves or { scriptErrors = "1", scriptProfile = "0" } -- réglages du jeu : gardés d'une session à l'autre
	G.GetCVar = function(n) return B.cvars[n] end
	G.SetCVar = function(n, v) B.cvars[n] = tostring(v) return true end
	B.cpu = {}
	G.UpdateAddOnCPUUsage = function() end
	G.GetAddOnCPUUsage = function(nom) if B.cvars.scriptProfile ~= "1" then return 0 end return B.cpu[nom] or 0 end
	G.ResetCPUUsage = function() B.cpu_remis = (B.cpu_remis or 0) + 1 for k in pairs(B.cpu) do B.cpu[k] = 0 end end
	B.en_combat, B.sons = false, {}
	G.InCombatLockdown = function() return B.en_combat end
	G.PlaySound = function(id) B.sons[#B.sons + 1] = id end
	B.rechargements, B.sauvegardes_addons = 0, 0
	G.ReloadUI = function() B.rechargements = B.rechargements + 1 end
	G.GameMenuFrame = B.creer_cadre("Frame", "GameMenuFrame", G.UIParent)
	G.GameMenuFrame._visible = false
	local tip = B.creer_cadre("GameTooltip", "GameTooltip")
	tip.lignes = {}
	tip._visible = false -- comme le jeu : cachée tant qu'on ne l'affiche pas
	function tip:ClearLines() self.lignes = {}; self.detail = {} end
	function tip:AddLine(t, r, g, b, retour)
		self.lignes[#self.lignes + 1] = t
		self.detail = self.detail or {}
		self.detail[#self.lignes] = { r = r, g = g, b = b, retour = retour }
	end
	function tip:AddDoubleLine(a, b) self.lignes[#self.lignes + 1] = a .. " " .. b end
	function tip:SetText(t) self.lignes = { t } end
	function tip:NumLines() return #self.lignes end
	function tip:SetOwner(p) self._proprietaire = p end
	G.GameTooltip = tip
	B.parametres = { categories = {}, ouvertures = {} } -- page d'options enregistrée, pages ouvertes
	G.Settings = {
		RegisterCanvasLayoutCategory = function(cadre, nom)
			local cat = { nom = nom, cadre = cadre, ID = #B.parametres.categories + 1 }
			function cat:GetID() return self.ID end
			B.parametres.categories[#B.parametres.categories + 1] = cat
			return cat
		end,
		RegisterAddOnCategory = function(cat) cat.ajoutee = true end,
		OpenToCategory = function(id) B.parametres.ouvertures[#B.parametres.ouvertures + 1] = id end,
	}

	-- minuteries (B.avancer fait passer le temps)
	local function ajouter(delai, f, repete)
		B.minuteries[#B.minuteries + 1] = { quand = B.horloge + delai, f = f, delai = delai, repete = repete }
		return B.minuteries[#B.minuteries]
	end
	G.C_Timer = {
		After = function(d, f) ajouter(d, f) end,
		NewTicker = function(d, f) return ajouter(d, f, true) end,
		NewTimer = function(d, f) return ajouter(d, f) end,
	}

	-- commandes slash du jeu (de quoi tester la détection de commande déjà prise)
	G.SlashCmdList = {}
	local jeu = {
		MAINASSISTON = { "/mainassiston", "/ma" },
		RELOAD = { "/reload", "/reloadui", "/rl" },
		SCRIPT = { "/script", "/run" },
		LOGOUT = { "/logout", "/camp" },
		DUMP = { "/dump" },
		CONSOLE = { "/console" },
		INVITE = { "/invite", "/inv" },
		SONDE = { "/sonde" },
	}
	for cle, noms in pairs(jeu) do
		G.SlashCmdList[cle] = function() B.commandes_jeu[#B.commandes_jeu + 1] = cle end
		for i, n in ipairs(noms) do G["SLASH_" .. cle .. i] = n end
	end
	B.commandes_jeu = {}

	-- C_AddOns : la liste vient des vrais .toc installés (instantané) + l'add-on testé
	local liste = opts.liste_addons
	local par_nom = {}
	for i, a in ipairs(liste) do par_nom[a.nom] = a; a.index = i end
	local active = opts.addons_actifs or {}
	local charge = {}
	B.charge = charge
	local function trouver(x) if type(x) == "number" then return liste[x] end return par_nom[x] end
	G.C_AddOns = {
		GetNumAddOns = function() return #liste end,
		DoesAddOnExist = function(n) return trouver(n) ~= nil end,
		GetAddOnInfo = function(x)
			local a = trouver(x)
			if not a then return nil end
			local on = active[a.nom] ~= false
			return a.nom, a.titre, a.notes, on, on and "" or "DISABLED", "INSECURE"
		end,
		GetAddOnMetadata = function(x, champ)
			local a = trouver(x)
			return a and a.metadonnees[champ] or nil
		end,
		GetAddOnEnableState = function(x, guid)
			local a = trouver(x)
			if not a then return 0 end
			local etat = B.etat_perso[guid or opts.guid] or active
			return etat[a.nom] == false and 0 or 2
		end,
		EnableAddOn = function(x, guid) local a = trouver(x); if a then (B.etat_perso[guid or opts.guid] or active)[a.nom] = true end end,
		DisableAddOn = function(x, guid) local a = trouver(x); if a then (B.etat_perso[guid or opts.guid] or active)[a.nom] = false end end,
		IsAddOnLoaded = function(x) local a = trouver(x); return a ~= nil and charge[a.nom] == true end,
		GetAddOnDependencies = function(x) local a = trouver(x); return unpack(a and a.dependances or {}) end,
		GetAddOnOptionalDependencies = function(x) local a = trouver(x); return unpack(a and a.facultatives or {}) end,
		IsAddOnLoadOnDemand = function(x) local a = trouver(x); return a ~= nil and a.a_la_demande end,
		SaveAddOns = function() B.sauvegardes_addons = B.sauvegardes_addons + 1 end,
	}
	B.etat_perso = B.etat_perso or {}
end

---------------------------------------------------------------- vie d'une session de jeu
-- Charge un add-on depuis son .toc : variables sauvegardées → fichiers dans l'ordre → ADDON_LOADED.
local function charger_addon(nom, dossier, ns)
	local toc = assert(io.open(chemin(dossier .. "/" .. nom .. ".toc"), "rb"), "toc introuvable : " .. nom)
	local sv_compte, sv_perso, fichiers = {}, {}, {}
	for ligne in toc:lines() do
		ligne = ligne:gsub("\r", ""):gsub("^\239\187\191", "")
		local cle, val = ligne:match("^##%s*([^:]+):%s*(.-)%s*$")
		if cle == "SavedVariables" then
			for v in val:gmatch("[^,%s]+") do sv_compte[#sv_compte + 1] = v end
		elseif cle == "SavedVariablesPerCharacter" then
			for v in val:gmatch("[^,%s]+") do sv_perso[#sv_perso + 1] = v end
		elseif not cle and ligne ~= "" and not ligne:match("^#") then
			fichiers[#fichiers + 1] = ligne:gsub("\\", "/")
		end
	end
	toc:close()
	for _, v in ipairs(sv_compte) do
		local texte = B.wtf.compte[v]
		if texte then _G[v] = deserialiser(texte) end
	end
	for _, v in ipairs(sv_perso) do
		local texte = B.wtf.perso[B.opts.guid .. "/" .. v]
		if texte then _G[v] = deserialiser(texte) end
	end
	B.sv_compte, B.sv_perso = sv_compte, sv_perso
	for _, f in ipairs(fichiers) do
		if f:lower():match("%.lua$") then
			local morceau, err = loadfile(chemin(dossier .. "/" .. f))
			if not morceau then error("syntaxe : " .. tostring(err), 0) end
			local ok, e = xpcall(function() morceau(nom, ns) end, function(m) return B.erreur_jeu(m) end)
			if not ok then B.erreurs_jeu[#B.erreurs_jeu + 1] = "chargement de " .. f .. " : " .. tostring(e) end
		else
			B.xml_ignores[#B.xml_ignores + 1] = f
		end
	end
	B.charge[nom] = true
	B.evenement("ADDON_LOADED", nom)
end

local valeurs_defaut = {
	locale = "frFR", royaume = "Royaume-Test", nom = "Testeur", guid = "Player-1-0000AAAA",
	faction = "Horde", classe = "WARRIOR", classe_nom = "Guerrier",
	addon = "MesAddons", dossier = "addon/MesAddons",
}

-- Lance une session de jeu complète : API, add-on testé, ADDON_LOADED, PLAYER_LOGIN, PLAYER_ENTERING_WORLD.
-- opts : locale, nom, guid, faction, addons_actifs{nom=false…}, addon, dossier
function B.demarrer(opts)
	opts = opts or {}
	for k, v in pairs(valeurs_defaut) do if opts[k] == nil then opts[k] = v end end
	B.nettoyer()
	B.opts = opts
	local liste = lire_instantane()
	-- l'add-on testé est lu dans son vrai .toc (même s'il n'est pas encore installé dans le jeu)
	local nouveau = true
	for _, a in ipairs(liste) do if a.nom == opts.addon then nouveau = false end end
	if nouveau then
		liste[#liste + 1] = { nom = opts.addon, titre = opts.addon, notes = "", dependances = {}, facultatives = {}, a_la_demande = false, metadonnees = {} }
	end
	for _, a in ipairs(liste) do
		if a.nom == opts.addon then
			local f = assert(io.open(chemin(opts.dossier .. "/" .. opts.addon .. ".toc"), "rb"))
			a.metadonnees = {}
			for ligne in f:lines() do
				ligne = ligne:gsub("\r", "")
				local cle, val = ligne:match("^##%s*([^:]+):%s*(.-)%s*$")
				if cle then a.metadonnees[cle] = val end
			end
			f:close()
			a.titre = a.metadonnees.Title or a.nom
			a.notes = a.metadonnees.Notes or ""
		end
	end
	opts.liste_addons = liste
	installer_api(opts)
	B.ns = { }
	charger_addon(opts.addon, opts.dossier, B.ns)
	-- B5-01 : la visite guidée du premier lancement n'a lieu que si le test la demande (opts.visite = true)
	if not opts.visite and B.ns.Reglages and B.ns.Reglages.compte then B.ns.Reglages.ecrire("aide.visite_vue", true) end
	B.evenement("PLAYER_LOGIN")
	B.evenement("PLAYER_ENTERING_WORLD", true, false)
	return B.ns
end

-- Déconnexion : PLAYER_LOGOUT puis écriture des variables sauvegardées (comme le jeu).
function B.deconnecter()
	B.evenement("PLAYER_LOGOUT")
	B.cvars_sauves = {}
	for k, v in pairs(B.cvars or {}) do B.cvars_sauves[k] = v end
	for _, v in ipairs(B.sv_compte or {}) do
		if _G[v] ~= nil then B.wtf.compte[v] = serialiser(_G[v]) end
	end
	for _, v in ipairs(B.sv_perso or {}) do
		if _G[v] ~= nil then B.wtf.perso[B.opts.guid .. "/" .. v] = serialiser(_G[v]) end
	end
end

-- /reload : déconnexion silencieuse puis nouvelle session avec les mêmes réglages du joueur.
function B.recharger(opts)
	B.deconnecter()
	local o = {}
	for k, v in pairs(B.opts) do o[k] = v end
	for k, v in pairs(opts or {}) do o[k] = v end
	o.liste_addons = nil
	return B.demarrer(o)
end

-- Efface le « disque » (nouvelle installation du jeu).
function B.effacer_sauvegardes() B.wtf = { compte = {}, perso = {} } B.cvars_sauves = nil end

---------------------------------------------------------------- commandes, temps
-- Tape une commande dans le chat (« /mesaddons aide »). Renvoie true si une commande l'a prise.
function B.slash(ligne)
	local nom, reste = ligne:match("^(/%S+)%s*(.-)%s*$")
	if not nom then return false end
	nom = nom:lower()
	local cles = {}
	for k in pairs(_G.SlashCmdList) do cles[#cles + 1] = k end
	table.sort(cles)
	for _, cle in ipairs(cles) do
		local i = 1
		while _G["SLASH_" .. cle .. i] do
			if _G["SLASH_" .. cle .. i]:lower() == nom then
				local ok, err = xpcall(function() _G.SlashCmdList[cle](reste, nil) end, function(m) return B.erreur_jeu(m) end)
				return true, cle
			end
			i = i + 1
		end
	end
	return false
end

-- Fait passer `secondes` de temps de jeu et déclenche les minuteries échues.
function B.avancer(secondes)
	local fin = B.horloge + secondes
	while true do
		local prochaine
		for _, m in ipairs(B.minuteries) do
			if not m.annulee and m.quand <= fin and (not prochaine or m.quand < prochaine.quand) then prochaine = m end
		end
		if not prochaine then break end
		B.horloge = math.max(B.horloge, prochaine.quand)
		if prochaine.repete then prochaine.quand = prochaine.quand + prochaine.delai else prochaine.annulee = true end
		xpcall(prochaine.f, function(m) return B.erreur_jeu(m) end)
	end
	B.horloge = fin
end

-- Texte du chat sans les codes de couleur, une ligne par message.
function B.chat_texte()
	local t = {}
	for i, l in ipairs(B.chat) do t[i] = (l:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
	return t
end

function B.chat_contient(morceau)
	for _, l in ipairs(B.chat_texte()) do
		if l:find(morceau, 1, true) then return true end
	end
	return false
end

B.nettoyer()
return B
