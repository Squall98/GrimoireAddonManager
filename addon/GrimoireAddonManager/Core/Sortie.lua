-- Écriture dans la fenêtre de discussion, avec le préfixe coloré.
local _, ns = ...

function ns.dire(texte)
	local couleur = ns.Reglages.lire("affichage.couleur_prefixe")
	local ligne = "|cff" .. couleur .. ns.T("chat.prefixe") .. "|r : " .. texte
	local cadre = DEFAULT_CHAT_FRAME
	if cadre and cadre.AddMessage then cadre:AddMessage(ligne) else print(ligne) end
end
