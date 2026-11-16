"""Instantané des add-ons installés pour le banc d'essai : lit les vrais .toc du dossier AddOns du jeu
(chemin dans outils/config.json) et écrit outils/banc/addons_installes.lua. Lecture seule sur le jeu.

  python -X utf8 outils/banc/instantane_addons.py [dossier AddOns]
"""
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from commun import chemin, config, lua  # noqa: E402


def lire_toc(dossier):
    nom = os.path.basename(dossier)
    fichier = os.path.join(dossier, nom + ".toc")
    if not os.path.exists(fichier):
        autres = [f for f in os.listdir(dossier) if f.lower().endswith(".toc") and "_" not in f]
        if not autres:
            return None
        fichier = os.path.join(dossier, autres[0])
    champs, fichiers = {}, []
    with open(fichier, encoding="utf-8", errors="replace") as f:
        for ligne in f:
            ligne = ligne.strip().lstrip("﻿")
            m = re.match(r"^##\s*([^:]+?)\s*:\s*(.*)$", ligne)
            if m:
                champs[m.group(1)] = m.group(2)
            elif ligne and not ligne.startswith("#"):
                fichiers.append(ligne)
    return champs, fichiers


def liste(texte):
    return [x.strip() for x in re.split(r"[,\s]+", texte or "") if x.strip()]


def main():
    cfg = config()
    src = sys.argv[1] if len(sys.argv) > 1 else chemin(cfg["dossier_addons_jeu"])
    addons = []
    for nom in sorted(os.listdir(src), key=str.lower):
        d = os.path.join(src, nom)
        if not os.path.isdir(d) or nom.lower().startswith("blizzard_"):
            continue
        r = lire_toc(d)
        if not r:
            continue
        champs, fichiers = r
        deps = liste(champs.get("Dependencies") or champs.get("RequiredDeps"))
        addons.append({
            "nom": nom,
            "titre": champs.get("Title", nom),
            "notes": champs.get("Notes", ""),
            "dependances": deps,
            "facultatives": liste(champs.get("OptionalDeps")),
            "a_la_demande": champs.get("LoadOnDemand", "0") == "1",
            "metadonnees": champs,
        })
    sortie = chemin("outils/banc/addons_installes.lua")
    with open(sortie, "w", encoding="utf-8", newline="\n") as f:
        f.write("-- GÉNÉRÉ par outils/banc/instantane_addons.py (vrais .toc du jeu, lecture seule) : ne pas modifier à la main.\n")
        f.write("return " + lua(addons) + "\n")
    print(f"{len(addons)} add-ons -> outils/banc/addons_installes.lua")


if __name__ == "__main__":
    main()
