"""Fabrique le changelog à partir de donnees/changelog.json (rien n'est écrit à la main dans les sorties).

  python -X utf8 outils/fabriquer_changelog.py             CHANGELOG.md (racine + dossier de l'add-on)
  python -X utf8 outils/fabriquer_changelog.py --notes X   affiche le texte d'une version (CurseForge, Release GitHub)
  python -X utf8 outils/fabriquer_changelog.py --verifier  échoue si la version du .toc n'a pas son entrée
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import RACINE, chemin, config  # noqa: E402

LANGUES = ["enUS", "frFR"]  # ordre d'affichage : anglais puis français, comme la fiche CurseForge


def donnees():
    return json.load(open(chemin("donnees/changelog.json"), encoding="utf-8"))


def version_toc():
    cfg = config()
    toc = open(chemin(cfg["dossier_addon"] + "/" + cfg["nom_addon"] + ".toc"), encoding="utf-8").read()
    m = re.search(r"^##\s*Version:\s*(\S+)", toc, re.M)
    return m.group(1) if m else "0"


def bloc_version(d, v, langue, niveau="##"):
    lignes = [f"{niveau} v{v['version']} ({v['date']})", ""]
    for cle, nom in d["rubriques"].items():
        if v.get(cle):
            lignes.append(f"**{nom[langue]}**")
            lignes += [f"- {e[langue]}" for e in v[cle]]
            lignes.append("")
    return lignes


def notes(d, numero):
    v = next((x for x in d["versions"] if x["version"] == numero), None)
    if not v:
        raise SystemExit(f"version {numero} absente de donnees/changelog.json")
    lignes = []
    for langue in LANGUES:
        lignes.append(f"### {d['titre'][langue]}")
        lignes.append("")
        lignes += bloc_version(d, v, langue)[2:]
    return "\n".join(lignes).rstrip() + "\n"


def complet(d):
    lignes = []
    for langue in LANGUES:
        lignes += [f"# {d['titre'][langue]}", "", d["intro"][langue], ""]
        for v in d["versions"]:
            lignes += bloc_version(d, v, langue)
        lignes += ["---", ""]
    return "\n".join(lignes[:-2]).rstrip() + "\n"


def main():
    args = sys.argv[1:]
    d = donnees()
    if "--verifier" in args:
        v = version_toc()
        if not any(x["version"] == v for x in d["versions"]):
            print(f"changelog : la version {v} du .toc n'a pas d'entrée dans donnees/changelog.json")
            return 1
        print(f"changelog : v{v} présente")
        return 0
    if "--notes" in args:
        sys.stdout.write(notes(d, args[args.index("--notes") + 1]))
        return 0
    texte = complet(d)
    for cible in ["CHANGELOG.md", config()["dossier_addon"] + "/CHANGELOG.md"]:
        open(os.path.join(RACINE, cible), "w", encoding="utf-8", newline="\n").write(texte)
        print("écrit :", cible)
    return 0


if __name__ == "__main__":
    sys.exit(main())
