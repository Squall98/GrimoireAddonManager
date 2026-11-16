-- Fiches Add-ons : textes affichés et réglages.
-- On peut tout changer ici sans toucher au code. Après une modif : /reload en jeu.
local _, ns = ...

ns.Textes = {
	-- Commande de chat (sans le « / »). On peut en mettre plusieurs.
	commandes = { "fiche", "fiches" },

	-- Titres des parties de la fiche dans l'infobulle
	titre         = "Fiche FR",
	resume        = "À quoi ça sert",
	commandesFiche = "Commandes",
	remarques     = "À savoir",
	maNote        = "Ma note",
	moduleDe      = "Module de %s",          -- %s = titre de l'add-on principal
	sansFiche     = "Pas encore de fiche. Ta note : /fiche %s <texte>",  -- %s = dossier

	-- Messages dans le chat
	prefixe        = "|cff66ccff[Fiches]|r ",
	aide = {
		"/fiche <dossier> : affiche la fiche dans le chat",
		"/fiche <dossier> <texte> : écrit ta note sur cet add-on",
		"/fiche <dossier> - : efface ta note",
		"/fiche notes : liste tes notes",
		"Le dossier, c'est le nom gris sous le titre dans l'infobulle (ex. NaowhForever).",
	},
	inconnu        = "Aucun add-on installé dans le dossier « %s ».",
	noteEnregistree = "Note enregistrée pour %s.",
	noteEffacee    = "Note effacée pour %s.",
	aucuneNote     = "Tu n'as encore écrit aucune note.",
}

ns.Reglages = {
	-- Afficher la ligne « Pas encore de fiche » sur les add-ons sans fiche
	afficherSansFiche = true,
	-- Couleurs (rouge, vert, bleu entre 0 et 1)
	couleurTitre     = { 0.40, 0.80, 1.00 },
	couleurEtiquette = { 1.00, 0.82, 0.00 },
	couleurTexte     = { 1.00, 1.00, 1.00 },
	couleurCommandes = { 0.60, 1.00, 0.60 },
	couleurRemarques = { 1.00, 0.60, 0.40 },
	couleurNote      = { 0.90, 0.70, 1.00 },
	couleurGris      = { 0.60, 0.60, 0.60 },
	-- Nom global de l'infobulle de Simple Addon Manager (si SAM change un jour)
	infobulleSAM     = "SAM_ADDON_LIST_TOOLTIP",
	-- Nom global de la liste d'add-ons du jeu, et des infobulles qu'elle peut utiliser
	listeDuJeu       = "AddonList",
	infobullesDuJeu  = { "GameTooltip", "AddonTooltip" },
}
