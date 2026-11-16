"""Vérification complète de Mes Add-ons : syntaxe Lua (luac), .toc, données (JSON et Lua générés à jour),
textes FR/EN, clés de texte utilisées, chasse au « en dur », puis tests du banc d'essai.

  python -X utf8 outils/verifier.py            tout
  python -X utf8 outils/verifier.py --sans-tests   sans lancer le banc
Code de sortie 0 = tout est bon.
"""
import glob
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generer_donnees  # noqa: E402
from commun import chemin, config, lire_json  # noqa: E402

erreurs = []
infos = []


def ko(msg):
    erreurs.append(msg)


def lua_fichiers(dossier, sauf=("lua51",)):
    res = []
    for r, ds, fs in os.walk(dossier):
        ds[:] = [d for d in ds if d not in sauf]
        res += [os.path.join(r, f) for f in fs if f.endswith(".lua")]
    return sorted(res)


# ------------------------------------------------------------------ 1. syntaxe Lua
def verifier_syntaxe():
    cfg = config()
    luac = chemin(cfg["luac"])
    if not os.path.exists(luac):
        return ko("luac introuvable : " + cfg["luac"])
    fichiers = lua_fichiers(chemin(cfg["dossier_addon"])) + lua_fichiers(chemin("outils/banc"))
    for f in fichiers:
        r = subprocess.run([luac, "-p", f], capture_output=True, text=True)
        if r.returncode != 0:
            ko(f"syntaxe Lua : {os.path.relpath(f, chemin('.'))} : {r.stderr.strip()}")
    infos.append(f"syntaxe Lua : {len(fichiers)} fichiers vérifiés avec luac 5.1")


# ------------------------------------------------------------------ 2. .toc
def verifier_toc():
    cfg = config()
    dossier = chemin(cfg["dossier_addon"])
    toc = os.path.join(dossier, cfg["nom_addon"] + ".toc")
    if not os.path.exists(toc):
        return ko("toc absent : " + toc)
    champs, fichiers = {}, []
    for ligne in open(toc, encoding="utf-8"):
        ligne = ligne.strip()
        m = re.match(r"^##\s*([^:]+?)\s*:\s*(.*)$", ligne)
        if m:
            champs[m.group(1)] = m.group(2)
        elif ligne and not ligne.startswith("#"):
            fichiers.append(ligne.replace("\\", "/"))
    if champs.get("Interface") != cfg["interface"]:
        ko(f"toc : Interface doit valoir {cfg['interface']} (trouvé {champs.get('Interface')})")
    for obligatoire in ("Title", "Notes", "Version", "SavedVariables"):
        if obligatoire not in champs:
            ko("toc : champ manquant " + obligatoire)
    for f in fichiers:
        if not os.path.exists(os.path.join(dossier, f)):
            ko("toc : fichier listé mais absent : " + f)
    sur_disque = {os.path.relpath(p, dossier).replace("\\", "/") for p in lua_fichiers(dossier)}
    for f in sorted(sur_disque - set(fichiers)):
        ko("toc : fichier Lua présent mais non listé : " + f)
    tech = lire_json(cfg["dossier_donnees"] + "/reglages.json")["technique"]
    if tech["variable_compte"] not in champs.get("SavedVariables", "").split(", "):
        ko("toc : SavedVariables ne contient pas " + tech["variable_compte"])
    if tech["variable_perso"] not in champs.get("SavedVariablesPerCharacter", "").split(", "):
        ko("toc : SavedVariablesPerCharacter ne contient pas " + tech["variable_perso"])
    infos.append(f"toc : version {champs.get('Version')}, {len(fichiers)} fichiers listés, Interface {champs.get('Interface')}")


# ------------------------------------------------------------------ 3. données
def verifier_donnees():
    cfg = config()
    d = cfg["dossier_donnees"]
    for rel, texte in generer_donnees.sorties().items():
        p = chemin(rel)
        if not os.path.exists(p) or open(p, encoding="utf-8", newline="").read() != texte:
            ko("donnée générée périmée (lancer outils/generer_donnees.py) : " + rel)
    fiches = lire_json(d + "/fiches/fiches.json")["fiches"]
    cats = lire_json(d + "/fiches/categories.json")["categories"]
    doublons = lire_json(d + "/fiches/doublons.json")["doublons"]
    profils = lire_json(d + "/fiches/profils.json")["profils"]
    for nom, f in fiches.items():
        for c in f.get("categories", []):
            if c not in cats:
                ko(f"fiche {nom} : catégorie inconnue {c}")
        for lg in ("fr", "en"):
            if not f.get(lg, {}).get("resume"):
                ko(f"fiche {nom} : résumé {lg} vide")
        if f.get("type") == "module" and f.get("parent") not in fiches:
            ko(f"fiche {nom} : parent {f.get('parent')} sans fiche")
        for dbl in f.get("doublons", []):
            if dbl not in fiches:
                ko(f"fiche {nom} : doublon inconnu {dbl}")
    for dbl in doublons:
        for n in dbl["entre"]:
            if n not in fiches:
                ko(f"doublons.json : {n} sans fiche")
        if not dbl.get("fr") or not dbl.get("en"):
            ko("doublons.json : texte manquant pour " + "/".join(dbl["entre"]))
    for pid, p in profils.items():
        for a in p["addons"]:
            if a not in fiches:
                ko(f"profil {pid} : {a} sans fiche")
        if not p["nom"].get("fr") or not p["nom"].get("en"):
            ko(f"profil {pid} : nom FR/EN manquant")
    for cid, c in cats.items():
        if not c.get("fr") or not c.get("en"):
            ko(f"catégorie {cid} : nom FR/EN manquant")
    infos.append(f"données : {len(fiches)} fiches, {len(cats)} catégories, {len(doublons)} doublons, {len(profils)} profils")


# ------------------------------------------------------------------ 4. textes FR/EN
def verifier_textes():
    d = config()["dossier_donnees"]
    fr = lire_json(d + "/textes/frFR.json")["textes"]
    en = lire_json(d + "/textes/enUS.json")["textes"]
    for k in sorted(set(fr) ^ set(en)):
        ko("texte présent dans une seule langue : " + k)
    spec = re.compile(r"%[sdf]")
    for k in set(fr) & set(en):
        if spec.findall(fr[k]) != spec.findall(en[k]):
            ko(f"texte {k} : les %s/%d ne correspondent pas entre FR et EN")
        if not fr[k].strip() or not en[k].strip():
            ko("texte vide : " + k)
    regl = lire_json(d + "/reglages.json")
    for sc in regl["sous_commandes"]:
        for suffixe in ("nom", "desc"):
            if f"sous.{sc}.{suffixe}" not in fr:
                ko(f"sous-commande {sc} : texte sous.{sc}.{suffixe} manquant")
    for niv in regl["journal_niveaux"]:
        if "niveau." + niv not in fr:
            ko("niveau de journal sans texte : " + niv)
    infos.append(f"textes : {len(fr)} clés identiques en français et en anglais")
    return fr


# ------------------------------------------------------------------ 4 bis. l'anglais est complet (aucun reste de français)
ACCENTS_FR = re.compile(r"[àâäçéèêëîïôöùûüÿœæÀÂÇÉÈÊÎÔÙÛ]")


def reste_de_francais(texte, cfg):
    """Dit pourquoi un texte anglais ressemble à du français (accent, mot français), ou None."""
    for nom in cfg["noms_propres"]:
        texte = texte.replace(nom, " ")
    texte = re.sub(r"\|c[0-9a-fA-F]{8}|\|r|%[sdf]", " ", texte)
    if ACCENTS_FR.search(texte):
        return "accent français"
    mot = re.search(r"\b(" + "|".join(cfg["mots_francais"]) + r")\b", texte, re.I)
    return f"mot français « {mot.group(1)} »" if mot else None


def verifier_anglais():
    d = config()["dossier_donnees"]
    cfg = config()["anglais"]
    fr = lire_json(d + "/textes/frFR.json")["textes"]
    en = lire_json(d + "/textes/enUS.json")["textes"]
    n = 0
    for k, v in sorted(en.items()):
        n += 1
        pourquoi = reste_de_francais(v, cfg)
        if pourquoi:
            ko(f"anglais : texte {k} contient un reste de français ({pourquoi}) : {v[:70]!r}")
        mots = re.findall(r"[A-Za-z]{3,}", re.sub(r"%[sdf]", "", v))
        if fr.get(k) == v and len(mots) >= 2 and k not in cfg["identiques_ok"]:
            ko(f"anglais : texte {k} identique en français et en anglais (non traduit ?) : {v[:70]!r}")
    for nom, f in lire_json(d + "/fiches/fiches.json")["fiches"].items():
        for champ, v in f.get("en", {}).items():
            n += 1
            pourquoi = reste_de_francais(v, cfg)
            if pourquoi:
                ko(f"anglais : fiche {nom}, {champ} : {pourquoi} : {v[:60]!r}")
    for cid, c in lire_json(d + "/fiches/categories.json")["categories"].items():
        n += 1
        if reste_de_francais(c["en"], cfg):
            ko(f"anglais : catégorie {cid} : {c['en']!r}")
    for dbl in lire_json(d + "/fiches/doublons.json")["doublons"]:
        n += 1
        if reste_de_francais(dbl["en"], cfg):
            ko("anglais : doublons.json : " + dbl["en"][:60])
    for pid, p in lire_json(d + "/fiches/profils.json")["profils"].items():
        n += 1
        if reste_de_francais(p["nom"]["en"], cfg):
            ko(f"anglais : profil {pid} : {p['nom']['en']!r}")
    infos.append(f"anglais : {n} textes anglais relus, aucun reste de français (accents, mots courants, textes non traduits)")


def verifier_aide():
    """Antisèche et visite : chaque sous-commande est dans un groupe (une fois), chaque étape a ses textes et sa cible."""
    d = config()["dossier_donnees"]
    regl = lire_json(d + "/reglages.json")
    fr = lire_json(d + "/textes/frFR.json")["textes"]
    aide = regl["aide"]
    vus = {}
    for g in aide["groupes"]:
        if "aide.groupe." + g["id"] not in fr:
            ko("aide : groupe sans texte : " + g["id"])
        for sc in g["sous"]:
            vus[sc] = vus.get(sc, 0) + 1
    for sc in regl["sous_commandes"]:
        if vus.get(sc, 0) != 1:
            ko(f"aide : la sous-commande {sc} doit être dans un seul groupe de l'antisèche (trouvée {vus.get(sc, 0)} fois)")
    for sc in vus:
        if sc not in regl["sous_commandes"]:
            ko("aide : groupe qui cite une sous-commande inconnue : " + sc)
    cadre = open(chemin(config()["dossier_addon"] + "/Fenetre/Cadre.lua"), encoding="utf-8").read()
    for e in aide["visite"]:
        for suffixe in ("titre", "texte"):
            if f"visite.{e['id']}.{suffixe}" not in fr:
                ko(f"visite : texte manquant visite.{e['id']}.{suffixe}")
        if "F." + e["cible"] + " =" not in cadre:
            ko("visite : la cible " + e["cible"] + " n'existe pas dans Fenetre/Cadre.lua")
    for p in aide["portees"]:
        if "aideportee." + p not in fr:
            ko("aide : portée sans texte : " + p)
    infos.append(f"aide : {len(vus)} sous-commandes dans {len(aide['groupes'])} groupes, {len(aide['visite'])} étapes de visite complètes")


def feuilles(d, prefixe=""):
    res = []
    for k, v in d.items():
        chemin = prefixe + k
        if isinstance(v, dict) and v:
            res += feuilles(v, chemin + ".")
        else:
            res.append(chemin)
    return res


def verifier_options(textes):
    """Le schéma des options (donnees/options.json) couvre tous les réglages, chacun une fois, avec ses textes."""
    d = config()["dossier_donnees"]
    regl = lire_json(d + "/reglages.json")
    opt = lire_json(d + "/options.json")
    feuilles_defauts = set(feuilles(regl["defauts"]))
    vus = set()
    n = 0
    for g in opt["groupes"]:
        if "opt.groupe." + g["id"] not in textes:
            ko("options : groupe sans texte : " + g["id"])
        for el in g["elements"]:
            n += 1
            if el["type"] == "action":
                if "opt.action." + el["action"] not in textes:
                    ko("options : action sans texte : " + el["action"])
                continue
            c = el["chemin"]
            if c in vus:
                ko("options : réglage en double : " + c)
            vus.add(c)
            if c not in feuilles_defauts:
                ko("options : réglage inconnu : " + c)
            if "opt." + c not in textes:
                ko("options : réglage sans texte : " + c)
            for v in el.get("choix", []):
                if el["texte_choix"] % v not in textes:
                    ko(f"options : choix sans texte : {c} = {v}")
    for c in sorted(feuilles_defauts - vus - set(opt.get("exclus", {}))):
        ko("options : réglage absent des options (ni exclu) : " + c)
    infos.append(f"options : {n} éléments, tous les réglages couverts (ou exclus avec raison)")


# ------------------------------------------------------------------ 5. clés de texte utilisées par le code
def verifier_cles(textes):
    dossier = chemin(config()["dossier_addon"])
    motif = re.compile(r'(?:ns\.T|Journal\.ecrire)\(\s*(?:"[a-z]+"\s*,\s*)?"([a-z_]+(?:\.[a-z_]+)+)"')
    dyn = re.compile(r'"((?:sous|niveau|arg)\.[a-z_]*)"\s*\.\.')
    utilises = set()
    for f in lua_fichiers(dossier):
        if os.sep + "Donnees" + os.sep in f:
            continue
        src = open(f, encoding="utf-8").read()
        for m in motif.finditer(src):
            utilises.add(m.group(1))
        for m in re.finditer(r'mot_est\([^,]+,\s*"([a-z_.]+)"\)', src):
            utilises.add(m.group(1))
    for cle in sorted(utilises):
        if cle not in textes:
            ko("clé de texte utilisée mais absente des textes : " + cle)
    infos.append(f"clés de texte : {len(utilises)} clés citées dans le code, toutes présentes")


# ------------------------------------------------------------------ 6. chasse au « en dur »
def litteraux(src):
    """Chaînes Lua d'un fichier (hors commentaires), avec le numéro de ligne."""
    res, i, n, ligne = [], 0, len(src), 1
    while i < n:
        c = src[i]
        if c == "\n":
            ligne += 1
            i += 1
        elif src.startswith("--", i):
            while i < n and src[i] != "\n":
                i += 1
        elif c in "\"'":
            q, j, buf = c, i + 1, []
            while j < n and src[j] != q and src[j] != "\n":
                if src[j] == "\\":
                    buf.append(src[j:j + 2])
                    j += 2
                else:
                    buf.append(src[j])
                    j += 1
            res.append((ligne, "".join(buf)))
            i = j + 1
        else:
            i += 1
    return res


PHRASE = re.compile(r"[A-Za-zÀ-ÿ]{3,}[ ,;:'’]+[A-Za-zÀ-ÿ]{2,}")
ACCENT = re.compile(r"[À-ÿ]")
# Noms à ne jamais trouver dans l'add-on : lus dans outils/propre-local.txt (un par ligne), fichier gardé HORS du dépôt
# git pour que ces noms ne soient pas publiés ; sans lui, seuls les identifiants de personnage sont cherchés.
def _motif_propre():
    noms = [r"Player-\d"]
    f = os.path.join(os.path.dirname(os.path.abspath(__file__)), "propre-local.txt")
    if os.path.exists(f):
        noms += [re.escape(l.strip()) for l in open(f, encoding="utf-8") if l.strip() and not l.startswith("#")]
    return re.compile("|".join(noms))


PROPRE = _motif_propre()


def verifier_en_dur():
    dossier = chemin(config()["dossier_addon"])
    n = 0
    for f in lua_fichiers(dossier):
        rel = os.path.relpath(f, dossier)
        if rel.startswith("Donnees"):
            continue
        src = open(f, encoding="utf-8").read()
        for ligne, lit in litteraux(src):
            n += 1
            if PHRASE.search(lit) or ACCENT.search(lit) or PROPRE.search(lit):
                ko(f"texte en dur ? {rel}:{ligne} : {lit[:60]!r} (mettre dans donnees/textes)")
    # rien de propre à une personne (partage possible, S2.9) : ni dans le code (commentaires compris), ni dans les données
    # de départ ; seule la mention d'auteur du .toc est permise.
    fichiers = [f for f in lua_fichiers(dossier)] + glob.glob(os.path.join(dossier, "*.xml"))
    fichiers += [os.path.join(r, f) for r, _, fs in os.walk(chemin(config()["dossier_donnees"])) for f in fs
                 if f.endswith(".json") and os.sep + "origine" + os.sep not in os.path.join(r, f)]
    for f in sorted(fichiers):
        if PROPRE.search(open(f, encoding="utf-8").read()):
            ko("propre à une personne (partage impossible) : " + os.path.relpath(f, chemin(".")))
    toc = os.path.join(dossier, config()["nom_addon"] + ".toc")
    for ligne in open(toc, encoding="utf-8"):
        if PROPRE.search(ligne) and not ligne.startswith("## Author:"):
            ko("propre à une personne dans le .toc : " + ligne.strip())
    infos.append(f"en dur : {n} chaînes de code lues, aucune phrase ni identifiant personnel")


# ------------------------------------------------------------------ 7. tests du banc
def lancer_tests():
    cfg = config()
    lua = chemin(cfg["lua"])
    env = dict(os.environ, MAA_RACINE=chemin("."))
    total_ok = total = 0
    for t in sorted(glob.glob(chemin(cfg["dossier_tests"]) + "/test_*.lua")):
        r = subprocess.run([lua, t], capture_output=True, text=True, encoding="utf-8", env=env, cwd=chemin("."))
        sortie = r.stdout + r.stderr
        m = re.search(r"RESULTAT (\d+)/(\d+)", sortie)
        nom = os.path.basename(t)
        if r.returncode != 0 or not m:
            ko(f"tests du banc : {nom} en échec\n" + "\n".join("    " + x for x in sortie.splitlines() if "KO" in x or x.startswith("      ") or "RESULTAT" in x or not m))
        if m:
            total_ok += int(m.group(1))
            total += int(m.group(2))
    infos.append(f"banc d'essai : {total_ok}/{total} tests passent")


def main():
    verifier_syntaxe()
    verifier_toc()
    verifier_donnees()
    textes = verifier_textes()
    verifier_anglais()
    verifier_aide()
    verifier_options(textes)
    verifier_cles(textes)
    verifier_en_dur()
    if "--sans-tests" not in sys.argv:
        lancer_tests()
    for i in infos:
        print("ok  ", i)
    for e in erreurs:
        print("KO  ", e)
    print("VÉRIFICATION", "RÉUSSIE" if not erreurs else f"ÉCHOUÉE ({len(erreurs)} problème(s))")
    return 1 if erreurs else 0


if __name__ == "__main__":
    sys.exit(main())
