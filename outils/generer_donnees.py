"""Génère les fichiers de données Lua de l'add-on (addon/MesAddons/Donnees/*.lua) à partir des JSON de donnees/.

Les JSON sont la source ; les .lua sont générés, jamais édités à la main (l'en-tête le dit).
  python -X utf8 outils/generer_donnees.py            écrit les fichiers
  python -X utf8 outils/generer_donnees.py --verifier  code 1 si un fichier généré n'est pas à jour
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import chemin, config, lire_json, lua  # noqa: E402

ENTETE = "-- GÉNÉRÉ par outils/generer_donnees.py depuis %s : ne pas modifier à la main.\n"


def sorties():
    cfg = config()
    d = cfg["dossier_donnees"]
    dest = cfg["dossier_addon"] + "/Donnees/"
    res = {}
    for code in ("frFR", "enUS"):
        src = f"{d}/textes/{code}.json"
        t = lire_json(src)["textes"]
        res[dest + f"Textes_{code}.lua"] = (src, f'local _, ns = ...\nns.donnees.textes["{code}"] = {lua(t)}\n')
    r = lire_json(f"{d}/reglages.json")
    res[dest + "Reglages.lua"] = (f"{d}/reglages.json", f"local _, ns = ...\nns.donnees.reglages = {lua(r)}\n")
    res[dest + "Options.lua"] = (f"{d}/options.json",
                                 "local _, ns = ...\nns.donnees.options = %s\n" % lua(lire_json(f"{d}/options.json")))
    res[dest + "Fiches.lua"] = (f"{d}/fiches/fiches.json + doublons.json",
                                "local _, ns = ...\nns.donnees.fiches = %s\nns.donnees.doublons = %s\n" % (
                                    lua(lire_json(f"{d}/fiches/fiches.json")["fiches"]),
                                    lua(lire_json(f"{d}/fiches/doublons.json")["doublons"])))
    res[dest + "Categories.lua"] = (f"{d}/fiches/categories.json",
                                    "local _, ns = ...\nns.donnees.categories = %s\n" % lua(lire_json(f"{d}/fiches/categories.json")["categories"]))
    res[dest + "Profils.lua"] = (f"{d}/fiches/profils.json",
                                 "local _, ns = ...\nns.donnees.profils = %s\n" % lua(lire_json(f"{d}/fiches/profils.json")["profils"]))
    return {k: (ENTETE % src) + corps for k, (src, corps) in res.items()}


def main():
    verifier = "--verifier" in sys.argv
    perimes = []
    for rel, texte in sorties().items():
        p = chemin(rel)
        actuel = open(p, encoding="utf-8", newline="").read() if os.path.exists(p) else None
        if actuel == texte:
            continue
        perimes.append(rel)
        if not verifier:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8", newline="\n") as f:
                f.write(texte)
    if verifier:
        for rel in perimes:
            print("PÉRIMÉ :", rel)
        print("données à jour" if not perimes else f"{len(perimes)} fichier(s) à régénérer")
        return 1 if perimes else 0
    print(f"{len(sorties())} fichiers de données (" + str(len(perimes)) + " écrits)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
