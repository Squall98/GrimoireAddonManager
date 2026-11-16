-- GÉNÉRÉ par outils/generer_donnees.py depuis donnees/options.json : ne pas modifier à la main.
local _, ns = ...
ns.donnees.options = {
	exclus = {
		["aide.visite_vue"] = "état interne : dit si la visite a déjà eu lieu (le bouton « Revoir la visite guidée » la relance)",
		["liste.filtre"] = "choisi avec la liste déroulante « Filtre » de la barre",
		["options.avances"] = "case « Montrer les réglages avancés » en haut du panneau d'options",
	},
	groupes = {
		{
			elements = {
				{
					apres = "peindre",
					chemin = "fenetre.theme",
					choix = {
						"auto",
						"horde",
						"alliance",
						"neutre",
					},
					texte_choix = "theme.%s",
					type = "choix",
				},
				{
					apres = "taille",
					chemin = "fenetre.taille",
					choix = {
						"grande",
						"moyenne",
						"compacte",
					},
					texte_choix = "taille.%s",
					type = "choix",
				},
				{
					apres = "peindre",
					chemin = "fenetre.taille_texte",
					choix = {
						"petite",
						"normale",
						"grande",
					},
					texte_choix = "taille_texte.%s",
					type = "choix",
				},
				{
					apres = "peindre",
					avance = true,
					chemin = "fenetre.police",
					choix = {
						"jeu",
						"gothique",
						"cinzel",
					},
					texte_choix = "police.%s",
					type = "choix",
				},
				{
					apres = "peindre",
					chemin = "fenetre.opacite",
					choix = {
						100,
						85,
						70,
						50,
					},
					texte_choix = "opacite.%s",
					type = "choix",
				},
				{
					apres = "mini",
					chemin = "fenetre.compact",
					type = "bool",
				},
				{
					apres = "disposer",
					chemin = "fenetre.cats_repliee",
					type = "bool",
				},
				{
					apres = "disposer",
					chemin = "fenetre.fiche_repliee",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fenetre.annuler_max",
					max = 20,
					min = 1,
					pas = 1,
					type = "nombre",
				},
				{
					chemin = "fenetre.modules_replies",
					type = "bool",
				},
				{
					apres = "echap",
					chemin = "fenetre.fermer_avec_echap",
					type = "bool",
				},
				{
					apres = "langue",
					chemin = "langue.choix",
					choix = {
						"auto",
						"frFR",
						"enUS",
					},
					texte_choix = "optlangue.%s",
					type = "choix",
				},
				{
					action = "reinit_tailles",
					avance = true,
					type = "action",
				},
			},
			id = "fenetre",
		},
		{
			elements = {
				{
					apres = "minicarte",
					chemin = "acces.bouton_minicarte",
					type = "bool",
				},
				{
					chemin = "acces.bouton_menu_echap",
					type = "bool",
				},
				{
					apres = "minicarte",
					avance = true,
					chemin = "acces.angle_minicarte",
					max = 359,
					min = 0,
					pas = 15,
					type = "nombre",
				},
				{
					chemin = "acces.compteur_minicarte",
					type = "bool",
				},
				{
					avance = true,
					chemin = "acces.clic_droit",
					choix = {
						"menu",
						"recharger",
					},
					texte_choix = "clicdroit.%s",
					type = "choix",
				},
				{
					avance = true,
					chemin = "acces.profils_minicarte",
					type = "bool",
				},
			},
			id = "acces",
		},
		{
			elements = {
				{
					chemin = "actions.resume_connexion",
					type = "bool",
				},
				{
					chemin = "actions.maj_clic",
					type = "bool",
				},
				{
					avance = true,
					chemin = "actions.essai_message",
					type = "bool",
				},
			},
			id = "actions",
		},
		{
			elements = {
				{
					apres = "commandes",
					chemin = "commandes.liste",
					type = "commandes",
				},
				{
					avance = true,
					chemin = "commandes.sans_argument",
					choix = {
						"ouvrir",
						"aide",
						"options",
					},
					texte_choix = "sous.%s.nom",
					type = "choix",
				},
			},
			id = "commandes",
		},
		{
			elements = {
				{
					chemin = "liste.tri",
					choix = {
						"nom",
						"categorie",
						"etat",
						"memoire",
						"utilite",
					},
					texte_choix = "tri.%s",
					type = "choix",
				},
				{
					avance = true,
					chemin = "liste.tri_inverse",
					type = "bool",
				},
				{
					chemin = "liste.grouper_tous",
					type = "bool",
				},
				{
					chemin = "liste.groupes_replies",
					type = "bool",
				},
				{
					chemin = "liste.favoris_en_haut",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.nouveaux_en_haut",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.nouveau_sans_fiche",
					type = "bool",
				},
			},
			id = "tri",
		},
		{
			elements = {
				{
					avance = true,
					chemin = "liste.filtres_visibles.tous",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.actives",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.desactivees",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.perimes",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.doublons",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.sans_fiche",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.favoris",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.a_desinstaller",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.nouveaux",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.mis_a_jour",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.erreurs",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.essais",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.filtres_visibles.en_attente",
					type = "bool",
				},
			},
			id = "filtres",
		},
		{
			elements = {
				{
					avance = true,
					chemin = "liste.recherche.nom",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.fiche",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.note",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.commandes",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.etiquettes",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.notes_toc",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.categorie",
					type = "bool",
				},
				{
					chemin = "liste.recherche.tolerance",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.distance",
					max = 3,
					min = 0,
					pas = 1,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "liste.recherche.longueur_min",
					max = 8,
					min = 2,
					pas = 1,
					type = "nombre",
				},
				{
					chemin = "liste.recherche.toutes_categories",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.pertinence",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.recherche.garder",
					type = "bool",
				},
			},
			id = "recherche",
		},
		{
			elements = {
				{
					chemin = "liste.colonnes.icone",
					type = "bool",
				},
				{
					chemin = "liste.colonnes.etoile",
					type = "bool",
				},
				{
					chemin = "liste.colonnes.badges",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.colonnes.raison",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.colonnes.etat_charge",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.colonnes.memoire",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges_max",
					max = 6,
					min = 0,
					pas = 1,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "liste.etiquettes_max",
					max = 20,
					min = 1,
					pas = 1,
					type = "nombre",
				},
			},
			id = "colonnes",
		},
		{
			elements = {
				{
					avance = true,
					chemin = "liste.badges.nouveau",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.mis_a_jour",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.erreur",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.doublon",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.inutile",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.essai",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.desinstaller",
					type = "bool",
				},
				{
					avance = true,
					chemin = "liste.badges.verrou",
					type = "bool",
				},
				{
					action = "tout_vu",
					avance = true,
					type = "action",
				},
			},
			id = "badges",
		},
		{
			elements = {
				{
					chemin = "fiche.infobulle",
					type = "bool",
				},
				{
					apres = "peindre",
					chemin = "fiche.fond",
					choix = {
						"jeu",
						"uni",
					},
					texte_choix = "fond_fiche.%s",
					type = "choix",
				},
				{
					chemin = "fiche.parties.resume",
					type = "bool",
				},
				{
					chemin = "fiche.parties.commandes",
					type = "bool",
				},
				{
					chemin = "fiche.parties.remarques",
					type = "bool",
				},
				{
					chemin = "fiche.parties.note",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fiche.parties.technique",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fiche.parties.dependances",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fiche.parties.doublons",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fiche.parties.badges",
					type = "bool",
				},
				{
					avance = true,
					chemin = "fiche.note_max",
					max = 5000,
					min = 100,
					pas = 100,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "fiche.texte_max",
					max = 5000,
					min = 100,
					pas = 100,
					type = "nombre",
				},
			},
			id = "fiche",
		},
		{
			elements = {
				{
					avance = true,
					chemin = "journal.actif",
					type = "bool",
				},
				{
					avance = true,
					chemin = "journal.taille_max",
					max = 1000,
					min = 50,
					pas = 50,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "journal.niveau_min",
					choix = {
						"debug",
						"info",
						"avertissement",
						"erreur",
					},
					texte_choix = "niveau.%s",
					type = "choix",
				},
				{
					avance = true,
					chemin = "journal.dedoublonner",
					type = "bool",
				},
				{
					avance = true,
					chemin = "journal.capturer_erreurs",
					type = "bool",
				},
				{
					avance = true,
					chemin = "journal.lignes_chat",
					max = 50,
					min = 1,
					pas = 1,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "personnages.memoriser",
					type = "bool",
				},
				{
					action = "effacer_journal",
					avance = true,
					type = "action",
				},
			},
			id = "journal",
		},
		{
			elements = {
				{
					chemin = "erreurs.actif",
					type = "bool",
				},
				{
					chemin = "erreurs.annonce",
					choix = {
						"fenetre",
						"chat",
						"rien",
					},
					texte_choix = "annonce.%s",
					type = "choix",
				},
				{
					avance = true,
					chemin = "erreurs.annonce_delai",
					max = 120,
					min = 0,
					pas = 5,
					type = "nombre",
				},
				{
					chemin = "erreurs.masquer_fenetre_jeu",
					type = "bool",
				},
				{
					chemin = "erreurs.son",
					type = "bool",
				},
				{
					avance = true,
					chemin = "erreurs.max",
					max = 500,
					min = 10,
					pas = 10,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.taille_message",
					max = 2000,
					min = 100,
					pas = 100,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.taille_pile",
					max = 6000,
					min = 200,
					pas = 200,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.lignes_liste",
					max = 20,
					min = 5,
					pas = 1,
					type = "nombre",
				},
				{
					chemin = "erreurs.memoire_alerte",
					type = "bool",
				},
				{
					avance = true,
					chemin = "erreurs.memoire_seuil_total",
					max = 4000,
					min = 100,
					pas = 50,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.memoire_seuil_addon",
					max = 1000,
					min = 10,
					pas = 10,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.memoire_intervalle",
					max = 600,
					min = 10,
					pas = 10,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.memoire_rappel",
					max = 3600,
					min = 60,
					pas = 60,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.memoire_lignes",
					max = 50,
					min = 3,
					pas = 1,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "erreurs.cpu_rappel",
					type = "bool",
				},
				{
					avance = true,
					chemin = "erreurs.cpu_lignes",
					max = 50,
					min = 3,
					pas = 1,
					type = "nombre",
				},
				{
					action = "ouvrir_erreurs",
					type = "action",
				},
				{
					action = "effacer_erreurs",
					type = "action",
				},
			},
			id = "erreurs",
		},
		{
			elements = {
				{
					chemin = "affichage.message_chargement",
					type = "bool",
				},
				{
					avance = true,
					chemin = "affichage.couleur_prefixe",
					motif = "couleur",
					type = "texte",
				},
				{
					action = "tout_reinitialiser",
					type = "action",
				},
			},
			id = "divers",
		},
		{
			elements = {
				{
					chemin = "profils.confirmer",
					type = "bool",
				},
				{
					chemin = "profils.dependances_auto",
					type = "bool",
				},
				{
					avance = true,
					chemin = "profils.dependances_facultatives",
					type = "bool",
				},
				{
					avance = true,
					chemin = "profils.portee",
					choix = {
						"perso",
						"tous",
					},
					texte_choix = "profil.portee_%s",
					type = "choix",
				},
				{
					chemin = "profils.proposer",
					type = "bool",
				},
				{
					avance = true,
					chemin = "profils.delai_proposition",
					max = 30,
					min = 0,
					pas = 1,
					type = "nombre",
				},
				{
					avance = true,
					chemin = "profils.situation.groupe",
					type = "texte",
				},
				{
					avance = true,
					chemin = "profils.situation.raid",
					type = "texte",
				},
				{
					avance = true,
					chemin = "profils.situation.champ",
					type = "texte",
				},
			},
			id = "profils",
		},
		{
			elements = {
				{
					chemin = "aide.visite_auto",
					type = "bool",
				},
				{
					avance = true,
					chemin = "aide.portee",
					choix = {
						"tout",
						"moi",
						"addons",
					},
					texte_choix = "aideportee.%s",
					type = "choix",
				},
				{
					apres = "peindre",
					chemin = "aide.regrouper",
					choix = {
						"categorie",
						"addon",
					},
					texte_choix = "aideregroupe.%s",
					type = "choix",
				},
				{
					avance = true,
					chemin = "aide.executer_maj",
					type = "bool",
				},
				{
					avance = true,
					chemin = "aide.montrer_eteints",
					type = "bool",
				},
				{
					avance = true,
					chemin = "aide.detecter",
					type = "bool",
				},
				{
					action = "ouvrir_antiseche",
					type = "action",
				},
				{
					action = "revoir_visite",
					type = "action",
				},
			},
			id = "aide",
		},
	},
	onglets = {
		{
			groupes = {
				"fenetre",
				"acces",
				"aide",
			},
			id = "fenetre",
		},
		{
			groupes = {
				"tri",
				"filtres",
				"recherche",
				"colonnes",
				"badges",
			},
			id = "liste",
		},
		{
			groupes = {
				"fiche",
			},
			id = "fiches",
		},
		{
			groupes = {
				"profils",
				"actions",
				"commandes",
			},
			id = "profils",
		},
		{
			groupes = {
				"erreurs",
				"journal",
				"divers",
			},
			id = "erreurs",
		},
	},
	version = 1,
}
