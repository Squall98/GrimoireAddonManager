"""Fabrique les pages Commands.md et Options.md du wiki (en + fr) depuis donnees/.

Lancer depuis la racine du projet :  python -X utf8 outils/fabriquer_wiki.py
Sources : donnees/reglages.json (sous_commandes, defauts), donnees/options.json,
donnees/textes/enUS.json et frFR.json. Les phrases "à quoi ça sert" de chaque option
sont dans DESC ci-dessous (le seul texte écrit à la main de ce script).
"""
import json
import pathlib
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
D = RACINE / "donnees"
SORTIE = RACINE / "docs" / "wiki"


def lire(p):
    return json.loads((D / p).read_text(encoding="utf-8"))


reg = lire("reglages.json")
opt = lire("options.json")
T = {"en": lire("textes/enUS.json")["textes"], "fr": lire("textes/frFR.json")["textes"]}
defauts = reg["defauts"]

# --- phrases d'explication : chemin -> (anglais, français) -------------------------------------
DESC = {
    "fenetre.theme": ("Colours of the window. “auto” follows your character's faction (red and gold for Horde, blue for Alliance).", "Les couleurs de la fenêtre. « auto » suit la faction de ton personnage (rouge et or pour la Horde, bleu pour l'Alliance)."),
    "fenetre.taille": ("Size the window has the first time you open it (you can still drag its bottom-right corner).", "Taille de la fenêtre à la première ouverture (tu peux ensuite tirer son coin en bas à droite)."),
    "fenetre.taille_texte": ("Makes all the text of the window smaller or bigger.", "Rend tout le texte de la fenêtre plus petit ou plus grand."),
    "fenetre.police": ("Typeface used in the window: the game's own, a gothic one or Cinzel.", "Police de caractères de la fenêtre : celle du jeu, une gothique ou Cinzel."),
    "fenetre.opacite": ("How see-through the window background is.", "Plus ou moins de transparence pour le fond de la fenêtre."),
    "fenetre.compact": ("Shows only the list, for quick ticking. Same as the Mini version button in the header.", "Ne garde que la liste, pour cocher vite. Comme le bouton Version mini de l'en-tête."),
    "fenetre.cats_repliee": ("Folds the left column (categories). Same as the arrow in the banner.", "Replie la colonne de gauche (catégories). Comme la flèche du bandeau."),
    "fenetre.fiche_repliee": ("Folds the right column (the sheet). Same as the arrow in the banner.", "Replie la colonne de droite (la fiche). Comme la flèche du bandeau."),
    "fenetre.annuler_max": ("How many changes the Undo button can take back.", "Combien de changements le bouton Annuler peut défaire."),
    "fenetre.modules_replies": ("Add-on modules (the small parts of a big add-on) start hidden under their main add-on.", "Les modules d'un gros add-on sont cachés sous lui au départ."),
    "fenetre.fermer_avec_echap": ("Pressing Esc closes the window.", "La touche Échap ferme la fenêtre."),
    "langue.choix": ("Language of the interface. “auto” follows the game's language.", "Langue de l'interface. « auto » suit la langue du jeu."),
    "acces.bouton_minicarte": ("Shows the round button near the minimap. Click: open; right-click: menu; drag: move it.", "Affiche le bouton rond près de la minicarte. Clic : ouvre ; clic droit : menu ; glisser : le déplacer."),
    "acces.bouton_menu_echap": ("The “AddOns” button of the game's Esc menu opens GAM.", "Le bouton « AddOns » du menu Échap du jeu ouvre GAM."),
    "acces.angle_minicarte": ("Where the button sits around the minimap, in degrees (dragging it changes this too).", "Place du bouton autour de la minicarte, en degrés (le glisser change aussi cette valeur)."),
    "acces.compteur_minicarte": ("Small red counter on the button when there are errors (or changes waiting).", "Petit compteur rouge sur le bouton quand il y a des erreurs (ou des changements en attente)."),
    "acces.clic_droit": ("What a right-click on the minimap button does.", "Ce que fait le clic droit sur le bouton de la minicarte."),
    "acces.profils_minicarte": ("Lists your profiles in the button's right-click menu.", "Met tes profils dans le menu du clic droit du bouton."),
    "actions.resume_connexion": ("Prints one line in the chat at login: add-ons, profile, pending changes, errors.", "Écrit une ligne dans le chat à la connexion : add-ons, profil, changements en attente, erreurs."),
    "actions.maj_clic": ("Shift + click on a box also turns on the add-on's modules and dependencies.", "Maj + clic sur une case allume aussi les modules et les dépendances de l'add-on."),
    "actions.essai_message": ("At login, says which trial add-ons have just been turned off.", "À la connexion, dit quels add-ons en essai viennent de s'éteindre."),
    "commandes.liste": ("The words that open the window (/gam, /maa, /mesaddons…), separated by spaces. A name already used by another add-on is refused.", "Les mots qui ouvrent la fenêtre (/gam, /maa, /mesaddons…), séparés par des espaces. Un nom déjà pris par un autre add-on est refusé."),
    "commandes.sans_argument": ("What typing the command with nothing after it does: open the window, show help or open the options.", "Ce que fait la commande tapée seule : ouvrir la fenêtre, afficher l'aide ou ouvrir les options."),
    "liste.tri": ("How the list is sorted. Click the sort button to change it; right-click to reverse.", "Le tri de la liste. Clique le bouton de tri pour le changer ; clic droit pour l'inverser."),
    "liste.tri_inverse": ("Reverses the sort order.", "Inverse l'ordre du tri."),
    "liste.grouper_tous": ("In “All add-ons”, groups the add-ons by category in folding sections (off = one plain list).", "Dans « Tous les add-ons », range les add-ons par catégories repliables (décoché = une simple liste)."),
    "liste.groupes_replies": ("Category sections start folded.", "Les sections de catégories sont repliées au départ."),
    "liste.favoris_en_haut": ("Favourites (star) stay at the top of the list.", "Les favoris (étoile) restent en haut de la liste."),
    "liste.nouveaux_en_haut": ("Add-ons that just arrived come first.", "Les add-ons qui viennent d'arriver passent devant."),
    "liste.nouveau_sans_fiche": ("Only add-ons without a sheet get the “New” badge.", "Seuls les add-ons sans fiche reçoivent le badge « Nouveau »."),
    "liste.recherche.nom": ("The search looks in add-on names.", "La recherche regarde dans les noms."),
    "liste.recherche.fiche": ("The search looks in the sheets' text.", "La recherche regarde dans le texte des fiches."),
    "liste.recherche.note": ("The search looks in your personal notes.", "La recherche regarde dans tes notes perso."),
    "liste.recherche.commandes": ("The search looks in the add-ons' commands (e.g. /way).", "La recherche regarde dans les commandes des add-ons (ex. /way)."),
    "liste.recherche.etiquettes": ("The search looks in tags (#pvp…).", "La recherche regarde dans les étiquettes (#pvp…)."),
    "liste.recherche.notes_toc": ("The search looks in the description the add-on gives about itself.", "La recherche regarde dans la description que l'add-on donne de lui-même."),
    "liste.recherche.categorie": ("The search looks in category names.", "La recherche regarde dans les noms de catégories."),
    "liste.recherche.tolerance": ("Small typos still find the add-on (“Questei” finds Questie).", "Les petites fautes de frappe trouvent quand même l'add-on (« Questei » trouve Questie)."),
    "liste.recherche.distance": ("How many wrong letters are forgiven in one word.", "Combien de lettres fausses sont pardonnées dans un mot."),
    "liste.recherche.longueur_min": ("Words shorter than this must be typed exactly.", "Les mots plus courts que ça doivent être tapés exactement."),
    "liste.recherche.toutes_categories": ("A search looks in every category, not only the one you selected.", "Une recherche regarde dans toutes les catégories, pas seulement celle choisie."),
    "liste.recherche.pertinence": ("The best matches come first instead of following the normal sort.", "Les meilleurs résultats passent devant, au lieu de suivre le tri normal."),
    "liste.recherche.garder": ("Keeps what you typed in the search box after a reload.", "Garde ce que tu as tapé dans la recherche après un rechargement."),
    "liste.colonnes.icone": ("Shows each add-on's icon on its row.", "Montre l'icône de chaque add-on sur sa ligne."),
    "liste.colonnes.etoile": ("Shows the favourite star on each row.", "Montre l'étoile des favoris sur chaque ligne."),
    "liste.colonnes.badges": ("Shows the badges (new, error…) on each row.", "Montre les badges (nouveau, erreur…) sur chaque ligne."),
    "liste.colonnes.raison": ("Says in plain words why an add-on is not loaded (missing dependency, out of date…).", "Dit en clair pourquoi un add-on ne se charge pas (dépendance absente, périmé…)."),
    "liste.colonnes.etat_charge": ("Also writes “loaded” or “disabled” on each row.", "Écrit aussi « chargé » ou « désactivé » sur chaque ligne."),
    "liste.colonnes.memoire": ("Shows the memory each add-on uses on its row.", "Montre la mémoire utilisée par chaque add-on sur sa ligne."),
    "liste.badges_max": ("Most badges drawn on one row (0 = none).", "Nombre maximal de badges sur une ligne (0 = aucun)."),
    "liste.etiquettes_max": ("Most tags you can give to one add-on.", "Nombre maximal d'étiquettes pour un add-on."),
    "liste.badges.nouveau": ("Badge for an add-on that just arrived in your AddOns folder.", "Badge pour un add-on qui vient d'arriver dans ton dossier AddOns."),
    "liste.badges.mis_a_jour": ("Badge for an add-on whose version changed since last time.", "Badge pour un add-on dont la version a changé depuis la dernière fois."),
    "liste.badges.erreur": ("Badge for an add-on that caused at least one Lua error.", "Badge pour un add-on qui a causé au moins une erreur Lua."),
    "liste.badges.doublon": ("Badge when another turned-on add-on does the same job.", "Badge quand un autre add-on allumé fait la même chose."),
    "liste.badges.inutile": ("Badge for an add-on not made for WoW Forever (greyed out).", "Badge pour un add-on non prévu pour WoW Forever (grisé)."),
    "liste.badges.essai": ("Badge for an add-on turned on for this session only.", "Badge pour un add-on allumé pour cette session seulement."),
    "liste.badges.desinstaller": ("Badge for an add-on in your “to remove” list (a reminder only).", "Badge pour un add-on de ta liste « à retirer » (un pense-bête)."),
    "liste.badges.verrou": ("Badge for a locked add-on (no profile will turn it off).", "Badge pour un add-on verrouillé (aucun profil ne l'éteindra)."),
    "fiche.infobulle": ("Shows a short summary in a tooltip when you hover an add-on.", "Montre un petit résumé en infobulle quand tu survoles un add-on."),
    "fiche.fond": ("Background of the sheet: plain light (easiest to read) or the game's parchment texture.", "Fond de la fiche : uni clair (le plus lisible) ou la texture de parchemin du jeu."),
    "fiche.parties.resume": ("Shows the “what it is for” part of the sheet.", "Montre la partie « à quoi il sert » de la fiche."),
    "fiche.parties.commandes": ("Shows the add-on's own commands in the sheet.", "Montre les commandes de l'add-on dans la fiche."),
    "fiche.parties.remarques": ("Shows the “good to know” part (pitfalls, settings to do).", "Montre la partie « à savoir » (pièges, réglages à faire)."),
    "fiche.parties.note": ("Shows your personal note box in the sheet.", "Montre la zone de ta note perso dans la fiche."),
    "fiche.parties.technique": ("Shows version, author, memory and state.", "Montre la version, l'auteur, la mémoire et l'état."),
    "fiche.parties.dependances": ("Shows the add-ons this one needs, and whether they are there and on.", "Montre les add-ons dont celui-ci a besoin, et s'ils sont là et allumés."),
    "fiche.parties.doublons": ("Shows turned-on add-ons that do the same job.", "Montre les add-ons allumés qui font la même chose."),
    "fiche.parties.badges": ("Shows the same badges as on the row.", "Montre les mêmes badges que sur la ligne."),
    "fiche.note_max": ("Longest personal note, in characters.", "Longueur maximale d'une note perso, en signes."),
    "fiche.texte_max": ("Longest text you can write when editing a sheet, in characters.", "Longueur maximale d'un texte quand tu modifies une fiche, en signes."),
    "journal.actif": ("Turns the add-on's own log on (a diary of what GAM did).", "Allume le journal de l'add-on (ce que GAM a fait)."),
    "journal.taille_max": ("How many log lines are kept.", "Combien de lignes de journal sont gardées."),
    "journal.niveau_min": ("Lowest importance written in the log: debug, info, warning or error.", "Importance minimale écrite dans le journal : debug, info, avertissement ou erreur."),
    "journal.dedoublonner": ("Identical lines in a row are merged into one with a counter.", "Les lignes identiques qui se suivent sont regroupées, avec un compteur."),
    "journal.capturer_erreurs": ("Also writes Lua errors in the log.", "Écrit aussi les erreurs Lua dans le journal."),
    "journal.lignes_chat": ("How many log lines the /gam log command prints in the chat.", "Combien de lignes du journal la commande /gam journal écrit dans le chat."),
    "personnages.memoriser": ("Remembers your characters so a profile can be applied to all of them.", "Retient tes personnages pour appliquer un profil à tous."),
    "erreurs.actif": ("Catches Lua errors from all add-ons and keeps their details.", "Attrape les erreurs Lua de tous les add-ons et garde leurs détails."),
    "erreurs.annonce": ("What happens when a new error arrives: open the error window, one chat line, or nothing.", "Ce qui se passe quand une nouvelle erreur arrive : ouvrir la fenêtre, une ligne dans le chat, ou rien."),
    "erreurs.annonce_delai": ("Minimum wait between two notices, so you are not flooded.", "Attente minimale entre deux annonces, pour ne pas être submergé."),
    "erreurs.masquer_fenetre_jeu": ("Hides the game's red error window; the errors stay recorded here.", "Cache la fenêtre rouge d'erreur du jeu ; les erreurs restent notées ici."),
    "erreurs.son": ("Plays a small sound on each new error.", "Joue un petit son à chaque nouvelle erreur."),
    "erreurs.max": ("How many different errors are kept (the oldest go first).", "Combien d'erreurs différentes sont gardées (les plus vieilles partent d'abord)."),
    "erreurs.taille_message": ("Characters kept of each error message.", "Signes gardés de chaque message d'erreur."),
    "erreurs.taille_pile": ("Characters kept of each error's call stack (the path that led to it).", "Signes gardés de la pile d'appels de chaque erreur (le chemin qui y mène)."),
    "erreurs.lignes_liste": ("Rows shown in the error window's list.", "Lignes montrées dans la liste de la fenêtre des erreurs."),
    "erreurs.memoire_alerte": ("Warns you when memory use goes over the limits below.", "Te prévient quand la mémoire dépasse les seuils ci-dessous."),
    "erreurs.memoire_seuil_total": ("Warning limit for the memory of all add-ons together.", "Seuil d'alerte pour la mémoire de tous les add-ons ensemble."),
    "erreurs.memoire_seuil_addon": ("Warning limit for a single add-on.", "Seuil d'alerte pour un seul add-on."),
    "erreurs.memoire_intervalle": ("How often memory is measured.", "Toutes les combien de secondes la mémoire est mesurée."),
    "erreurs.memoire_rappel": ("Wait before the same warning is repeated.", "Attente avant de répéter la même alerte."),
    "erreurs.memoire_lignes": ("Rows printed by /gam memory.", "Lignes écrites par /gam memoire."),
    "erreurs.cpu_rappel": ("Reminds you that CPU measuring is on (it slows the game a little).", "Te rappelle que le mode mesure du processeur est allumé (il ralentit un peu le jeu)."),
    "erreurs.cpu_lignes": ("Rows printed by /gam cpu.", "Lignes écrites par /gam cpu."),
    "affichage.message_chargement": ("Prints a short “loaded” message in the chat when the game starts.", "Écrit un petit message « chargé » dans le chat au lancement du jeu."),
    "affichage.couleur_prefixe": ("Colour of the [GAM] prefix in chat messages, 6 hex digits (e.g. ffd100).", "Couleur du préfixe [GAM] dans les messages du chat, 6 chiffres hexadécimaux (ex. ffd100)."),
    "profils.confirmer": ("Before applying a profile, shows what changes: +x to turn on, −y to turn off.", "Avant d'appliquer un profil, montre ce qui change : +x à allumer, −y à éteindre."),
    "profils.dependances_auto": ("A profile also turns on the dependencies its add-ons need.", "Un profil allume aussi les dépendances dont ses add-ons ont besoin."),
    "profils.dependances_facultatives": ("Also turns on optional dependencies (e.g. Baganator brings Syndicator).", "Allume aussi les dépendances facultatives (ex. Baganator amène Syndicator)."),
    "profils.portee": ("Who a profile is applied to by default: this character or all known ones.", "À qui un profil s'applique par défaut : ce personnage ou tous ceux qu'on connaît."),
    "profils.proposer": ("Offers the matching profile when you enter a dungeon, raid or battleground. Never automatic: it asks first and waits for the end of combat.", "Propose le profil associé en entrant en donjon, raid ou champ de bataille. Jamais automatique : il demande d'abord et attend la fin du combat."),
    "profils.delai_proposition": ("Seconds to wait after entering before suggesting.", "Secondes d'attente après l'entrée avant de proposer."),
    "profils.situation.groupe": ("Name of the profile suggested in a dungeon.", "Nom du profil proposé en donjon."),
    "profils.situation.raid": ("Name of the profile suggested in a raid.", "Nom du profil proposé en raid."),
    "profils.situation.champ": ("Name of the profile suggested in a battleground or arena (empty = no suggestion).", "Nom du profil proposé en champ de bataille ou arène (vide = pas de proposition)."),
    "aide.visite_auto": ("Starts the 5-bubble guided tour the first time. It runs only once.", "Lance la visite guidée en 5 bulles au premier lancement. Une seule fois."),
    "aide.portee": ("What the cheat sheet shows when opened: everything, only GAM's commands, or only your add-ons'.", "Ce que l'antisèche montre à l'ouverture : tout, seulement les commandes de GAM, ou seulement celles de tes add-ons."),
    "aide.regrouper": ("How the add-ons' commands are arranged in the cheat sheet.", "Comment les commandes des add-ons sont rangées dans l'antisèche."),
    "aide.executer_maj": ("Shift + click on a command in the cheat sheet runs it instead of only typing it.", "Maj + clic sur une commande de l'antisèche la lance au lieu de seulement l'écrire."),
    "aide.montrer_eteints": ("Also lists commands of add-ons that are turned off.", "Liste aussi les commandes des add-ons éteints."),
    "aide.detecter": ("Finds commands that add-ons register but the sheets do not mention.", "Repère les commandes que des add-ons déclarent mais que les fiches ne citent pas."),
}
# Filtres : une seule phrase modèle, le nom du filtre vient des textes (filtre.<id>)
FILTRES = ("Keeps the “%s” choice in the window's Filter drop-down list.", "Garde le choix « %s » dans la liste déroulante Filtre de la fenêtre.")
for _id in ("tous", "actives", "desactivees", "perimes", "doublons", "sans_fiche", "favoris", "a_desinstaller", "nouveaux", "mis_a_jour", "erreurs", "essais", "en_attente"):
    DESC["liste.filtres_visibles." + _id] = (FILTRES[0] % T["en"]["filtre." + _id], FILTRES[1] % T["fr"]["filtre." + _id])

ACT = {
    "reinit_tailles": ("Forgets the saved size and place of the windows.", "Oublie la taille et la place gardées des fenêtres."),
    "tout_vu": ("Removes the “New” and “Updated” badges from every add-on.", "Retire les badges « Nouveau » et « Mis à jour » de tous les add-ons."),
    "effacer_journal": ("Empties the log.", "Vide le journal."),
    "ouvrir_erreurs": ("Opens the error window.", "Ouvre la fenêtre des erreurs."),
    "effacer_erreurs": ("Deletes every recorded error.", "Efface toutes les erreurs notées."),
    "tout_reinitialiser": ("Puts every setting back to its starting value (asks to confirm).", "Remet tous les réglages à leur valeur de départ (demande confirmation)."),
    "ouvrir_antiseche": ("Opens the command cheat sheet.", "Ouvre l'antisèche des commandes."),
    "revoir_visite": ("Plays the guided tour again.", "Rejoue la visite guidée."),
}

TXT = {
    "en": dict(opts="⚙️ Options", cmds="⌨️ Commands", tab="Tab", grp="Group", name="Option", what="What it does", start="Default", adv="Advanced",
               yes="on", no="off", advyes="🔧 yes", advno="—", btn="button", head="Everything below is generated from the add-on's data files. Options marked 🔧 only appear when you tick **Show advanced settings** at the top of the options panel.",
               other="Other language", otherlink="Lire en français", lang="en", sep="Choices", range="from {a} to {b}", empty="(empty)",
               ctitle="⌨️ Commands", cintro="`/gam`, `/maa` and `/mesaddons` all work the same (you can change them in the options). Words in French work too: `/gam aide` = `/gam help`.",
               ccol=("Command", "What it does"), cn="{n} sub-commands, generated from the add-on's data."),
    "fr": dict(opts="⚙️ Options", cmds="⌨️ Commandes", tab="Onglet", grp="Groupe", name="Option", what="À quoi ça sert", start="Au départ", adv="Avancée",
               yes="oui", no="non", advyes="🔧 oui", advno="—", btn="bouton", head="Tout ce qui suit est généré depuis les fichiers de données de l'add-on. Les options marquées 🔧 n'apparaissent que si tu coches **Montrer les réglages avancés** en haut du panneau d'options.",
               other="Autre langue", otherlink="Read in English", lang="fr", sep="Choix", range="de {a} à {b}", empty="(vide)",
               ctitle="⌨️ Commandes", cintro="`/gam`, `/maa` et `/mesaddons` marchent pareil (modifiables dans les options). Les mots anglais marchent aussi : `/gam help` = `/gam aide`.",
               ccol=("Commande", "Ce qu'elle fait"), cn="{n} sous-commandes, générées depuis les données de l'add-on."),
}


def esc(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def choix_txt(e, v, L):
    mod = e.get("texte_choix")
    if mod:
        t = T[L].get(mod % v)
        if t:
            return t
    return str(v)


def val_depart(e, c, L):
    x = defauts
    for s in c.split("."):
        x = x[s]
    t = e["type"]
    if t == "bool":
        return "✅ " + TXT[L]["yes"] if x else "⬜ " + TXT[L]["no"]
    if t == "choix":
        return choix_txt(e, x, L)
    if t == "commandes":
        return " ".join("/" + n for n in x)
    if t == "texte":
        return "`%s`" % x if x != "" else TXT[L]["empty"]
    return str(x)


IMG = {
    "en": {"fenetre": "gam-en-wiki-options-window", "liste": "gam-en-wiki-options-list", "fiches": "gam-en-wiki-options-sheets",
           "profils": "gam-en-wiki-options-profiles", "erreurs": "gam-en-wiki-options-errors"},
    "fr": {"fenetre": "gam-fr-2-options"},
}


def page_options(L):
    X = TXT[L]
    o = ["[%s](../%s/Options.md)" % ("🇫🇷 " + X["otherlink"] if L == "en" else "🇬🇧 " + X["otherlink"], "fr" if L == "en" else "en")]
    o = ["> 🌐 " + o[0] + " · [🏠 " + ("Home" if L == "en" else "Accueil") + "](../Home.md)", "", "# " + X["opts"], "", X["head"], ""]
    o.append("> 📍 " + ("Open them with the **Options** button of the window, `/gam options`, or the game's Esc menu › Options › AddOns (`/gam options game`)."
                         if L == "en" else
                         "Ouvre-les par le bouton **Options** de la fenêtre, `/gam options`, ou le menu Échap › Options › AddOns du jeu (`/gam options jeu`)."))
    o.append("")
    groupes = {g["id"]: g for g in opt["groupes"]}
    manque = []
    for ong in opt["onglets"]:
        o.append("## " + {"fenetre": "🪟", "liste": "📋", "fiches": "📜", "profils": "🎒", "erreurs": "🐞"}[ong["id"]] + " " + T[L]["opt.onglet." + ong["id"]])
        o.append("")
        img = IMG[L].get(ong["id"], IMG["en"][ong["id"]])
        o.append("![%s](../../../media/captures/%s.png)" % (T[L]["opt.onglet." + ong["id"]], img))
        o.append("")
        for gid in ong["groupes"]:
            g = groupes[gid]
            o.append("### " + T[L]["opt.groupe." + gid])
            o.append("")
            o.append("| %s | %s | %s | %s |" % (X["name"], X["what"], X["start"], X["adv"]))
            o.append("|---|---|---|---|")
            for e in g["elements"]:
                c = e.get("chemin")
                if c:
                    nom = T[L]["opt." + c].strip(" =")
                    if c not in DESC:
                        manque.append(c)
                        continue
                    d = DESC[c][0 if L == "en" else 1]
                    if e["type"] == "choix":
                        d += " **%s%s:** %s." % (X["sep"], " " if L == "fr" else "", ", ".join(choix_txt(e, v, L) for v in e["choix"]))
                    elif e["type"] == "nombre":
                        d += " (" + X["range"].format(a=e["min"], b=e["max"]) + ")"
                    dep = val_depart(e, c, L)
                else:
                    a = e["action"]
                    nom = "🔘 " + T[L]["opt.action." + a]
                    if a not in ACT:
                        manque.append(a)
                        continue
                    d = ACT[a][0 if L == "en" else 1]
                    dep = "(%s)" % X["btn"]
                o.append("| %s | %s | %s | %s |" % (esc(nom), esc(d), esc(dep), X["advyes"] if e.get("avance") else X["advno"]))
            o.append("")
    if manque:
        sys.exit("Descriptions manquantes : %s" % manque)
    return "\n".join(o)


def page_commandes(L):
    X = TXT[L]
    o = ["> 🌐 [%s](../%s/Commands.md)" % ("🇫🇷 " + X["otherlink"] if L == "en" else "🇬🇧 " + X["otherlink"], "fr" if L == "en" else "en") + " · [🏠 " + ("Home" if L == "en" else "Accueil") + "](../Home.md)", "",
         "# " + X["ctitle"], "", X["cintro"], "", X["cn"].format(n=len(reg["sous_commandes"])), "",
         "| %s | %s |" % X["ccol"], "|---|---|"]
    for s in reg["sous_commandes"]:
        n = T[L].get("sous.%s.nom" % s, s)
        d = T[L].get("sous.%s.desc" % s, "")
        if n == s or L == "en":
            cmd = "`/gam %s`" % n
        else:
            cmd = "`/gam %s`" % n
        o.append("| %s | %s |" % (cmd, esc(d)))
    o.append("")
    return "\n".join(o)


def main():
    for L in ("en", "fr"):
        (SORTIE / L).mkdir(parents=True, exist_ok=True)
        (SORTIE / L / "Options.md").write_text(page_options(L), encoding="utf-8")
        (SORTIE / L / "Commands.md").write_text(page_commandes(L), encoding="utf-8")
    print("Options.md et Commands.md écrits (en, fr).")


if __name__ == "__main__":
    main()
