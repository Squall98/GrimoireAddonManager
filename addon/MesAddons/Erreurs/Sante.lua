-- Santé des add-ons : mémoire de chacun et du total (alerte au-delà d'un seuil réglable), mode mesure du processeur.
-- Les seuils, durées et noms de réglages du jeu viennent de ns.donnees.reglages (erreurs.* et interface.erreurs).
local _, ns = ...
local H = {}
ns.Sante = H

local function cfg() return ns.donnees.reglages.interface.erreurs end
local function lire(chemin) return ns.Reglages.lire("erreurs." .. chemin) end

H.alertes = {}   -- clé d'alerte -> moment (GetTime) du dernier avertissement
H.depart = nil   -- moment de la dernière remise à zéro des mesures du processeur

------------------------------------------------------------------ mémoire
-- Formate des Ko en « 12,3 Mo » ou « 800 Ko » (les unités viennent des textes).
function H.formaterKo(ko)
	if ko >= 1024 then return ns.T("unite.mo", ko / 1024) end
	return ns.T("unite.ko", math.floor(ko + 0.5))
end

-- Mesure tout de suite. Renvoie { { nom, ko } } trié du plus gourmand au plus sobre (add-ons chargés seulement), et le total en Ko.
function H.memoire()
	if UpdateAddOnMemoryUsage then UpdateAddOnMemoryUsage() end
	local liste, total = {}, 0
	for i = 1, C_AddOns.GetNumAddOns() do
		local nom = C_AddOns.GetAddOnInfo(i)
		if nom and GetAddOnMemoryUsage then
			local ko = tonumber(GetAddOnMemoryUsage(nom)) or 0
			if ko > 0 then
				liste[#liste + 1] = { nom = nom, ko = ko }
				total = total + ko
			end
		end
	end
	table.sort(liste, function(a, b)
		if a.ko ~= b.ko then return a.ko > b.ko end
		return a.nom < b.nom
	end)
	H.derniere = { liste = liste, total = total }
	return liste, total
end

local function avertir(cle, texteAlerte, valeur, seuil)
	local maintenant = GetTime()
	local avant = H.alertes[cle]
	if avant and maintenant - avant < lire("memoire_rappel") then return false end
	H.alertes[cle] = maintenant
	ns.dire(texteAlerte)
	ns.Journal.ecrire("avertissement", "journal.memoire_alerte", cle == "*" and ns.T("memoire.nom_total") or cle, H.formaterKo(seuil))
	return true
end

-- Compare la mémoire aux seuils et prévient (au plus une fois par « secondes avant de répéter »). Renvoie le nombre d'alertes dites.
function H.verifierMemoire()
	local liste, total = H.memoire()
	local dites = 0
	local seuilTotal = lire("memoire_seuil_total") * 1024
	local seuilAddon = lire("memoire_seuil_addon") * 1024
	if total > seuilTotal and avertir("*", ns.T("memoire.alerte_total", H.formaterKo(total), H.formaterKo(seuilTotal)), total, seuilTotal) then
		dites = dites + 1
	end
	for _, a in ipairs(liste) do
		if a.ko <= seuilAddon then break end
		if avertir(a.nom, ns.T("memoire.alerte_addon", a.nom, H.formaterKo(a.ko), H.formaterKo(seuilAddon)), a.ko, seuilAddon) then
			dites = dites + 1
		end
	end
	return dites
end

-- Une mesure, puis la suivante après l'intervalle réglé (relu à chaque tour : le changer n'exige pas de rechargement).
local function programmer()
	C_Timer.After(lire("memoire_intervalle"), function()
		if lire("memoire_alerte") then ns.Journal.proteger(H.verifierMemoire) end
		programmer()
	end)
end

------------------------------------------------------------------ processeur
-- Le mode mesure est le réglage du jeu « scriptProfile » (il faut recharger l'interface pour qu'il change).
function H.cpuAllume()
	return GetCVar ~= nil and GetCVar(cfg().cvar_cpu) == cfg().oui
end

-- Demande d'allumer ou de couper le mode mesure. Renvoie "demande", "coupe" ou "deja".
function H.cpuDefinir(allumer)
	local c = cfg()
	local voulu = allumer and c.oui or c.non
	if GetCVar(c.cvar_cpu) == voulu then return "deja" end
	SetCVar(c.cvar_cpu, voulu)
	ns.Journal.ecrire("info", "journal.cpu_mode", voulu)
	return allumer and "demande" or "coupe"
end

-- Le jeu ne mesure vraiment qu'après rechargement : tant que le réglage dit oui mais que les mesures restent nulles, c'est « en attente ».
function H.cpuMesures()
	if UpdateAddOnCPUUsage then UpdateAddOnCPUUsage() end
	local liste, total = {}, 0
	for i = 1, C_AddOns.GetNumAddOns() do
		local nom = C_AddOns.GetAddOnInfo(i)
		if nom and GetAddOnCPUUsage then
			local ms = tonumber(GetAddOnCPUUsage(nom)) or 0
			if ms > 0 then
				liste[#liste + 1] = { nom = nom, ms = ms }
				total = total + ms
			end
		end
	end
	table.sort(liste, function(a, b)
		if a.ms ~= b.ms then return a.ms > b.ms end
		return a.nom < b.nom
	end)
	return liste, total
end

function H.cpuZero()
	if ResetCPUUsage then ResetCPUUsage() end
	H.depart = GetTime()
end

-- Secondes écoulées depuis les dernières mesures remises à zéro (ou depuis la connexion).
function H.cpuDuree()
	return math.max(GetTime() - (H.depart or H.connexion or GetTime()), 0)
end

------------------------------------------------------------------ démarrage
local cadre = CreateFrame("Frame")
cadre:RegisterEvent("PLAYER_LOGIN")
cadre:SetScript("OnEvent", function()
	H.connexion = GetTime()
	programmer()
	if lire("cpu_rappel") and H.cpuAllume() then
		ns.dire(ns.T("cpu.rappel", ns.Commandes.principale() or ns.Reglages.technique().cle_commande))
	end
end)
