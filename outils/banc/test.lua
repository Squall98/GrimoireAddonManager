-- Mini cadre de tests pour le banc : un fichier de tests = un processus Lua.
-- Usage dans un fichier de tests :
--   local T = dofile(racine .. "/outils/banc/test.lua")
--   T.test("nom", function(B) ... end)   -- B = banc, remis à zéro avant chaque test
--   T.fin()                              -- affiche le bilan et sort avec le bon code
local afficher = print -- le banc remplace print par une capture : on garde l'original
local racine = os.getenv("MAA_RACINE") or "."
local B = dofile(racine .. "/outils/banc/wow.lua")

local T = { B = B, ok = 0, ko = 0, nom_fichier = "?" }

function T.test(nom, fn)
	B.nettoyer()
	B.effacer_sauvegardes()
	B.etat_perso = {}
	local ok, err = xpcall(function() fn(B) end, function(m) return debug.traceback(tostring(m), 2) end)
	if ok then
		T.ok = T.ok + 1
		afficher("  ok  " .. nom)
	else
		T.ko = T.ko + 1
		afficher("  KO  " .. nom .. "\n      " .. tostring(err):gsub("\n", "\n      "))
	end
end

function T.eq(a, b, msg)
	if a ~= b then error((msg or "différent") .. " : attendu " .. tostring(b) .. ", obtenu " .. tostring(a), 2) end
end

function T.vrai(v, msg)
	if not v then error(msg or "attendu vrai", 2) end
end

function T.faux(v, msg)
	if v then error(msg or "attendu faux", 2) end
end

-- Aucune erreur Lua levée dans le jeu simulé.
function T.sans_erreur()
	if #B.erreurs_jeu > 0 then error("erreurs dans le jeu simulé :\n" .. table.concat(B.erreurs_jeu, "\n"), 2) end
end

function T.fin()
	afficher(string.format("RESULTAT %d/%d", T.ok, T.ok + T.ko))
	os.exit(T.ko == 0 and 0 or 1)
end

return T
