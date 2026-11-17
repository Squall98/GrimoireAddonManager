"""Installe Mes Add-ons dans le dossier AddOns du jeu : copie vérifiée au SHA256, ancienne version rangée dans _archives.

  python -X utf8 outils/installer.py --simuler            montre ce qui serait fait, ne touche à rien
  python -X utf8 outils/installer.py                      vérifie l'add-on (outils/verifier.py) puis installe
  python -X utf8 outils/installer.py --vers DOSSIER       installe dans un autre dossier AddOns (essais)

Règles : seul le dossier GrimoireAddonManager est touché (aucun autre add-on) ; rien n'est supprimé : l'ancienne version
est déplacée dans _archives/installations/GrimoireAddonManager-<date>_<heure> ; la copie est comparée fichier par fichier
(nombre, octets, SHA256) et, en cas d'écart, l'ancienne version est remise en place.
"""
import datetime
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import RACINE, chemin, config, sha256  # noqa: E402


def empreintes(dossier):
    res = {}
    for r, _, fs in os.walk(dossier):
        for f in fs:
            p = os.path.join(r, f)
            res[os.path.relpath(p, dossier).replace("\\", "/")] = (os.path.getsize(p), sha256(p))
    return res


def comparer(a, b):
    """Liste des écarts entre deux dossiers (vide = identiques)."""
    ea, eb = empreintes(a), empreintes(b)
    ecarts = [f"absent de la copie : {k}" for k in ea if k not in eb]
    ecarts += [f"en trop dans la copie : {k}" for k in eb if k not in ea]
    ecarts += [f"différent : {k}" for k in ea if k in eb and ea[k] != eb[k]]
    return ecarts, len(ea), sum(v[0] for v in ea.values())


def main():
    args = sys.argv[1:]
    cfg = config()
    simuler = "--simuler" in args
    dest_addons = chemin(cfg["dossier_addons_jeu"])
    if "--vers" in args:
        dest_addons = os.path.abspath(args[args.index("--vers") + 1])
    source = chemin(cfg["dossier_addon"])
    nom = cfg["nom_addon"]
    cible = os.path.join(dest_addons, nom)
    horodatage = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
    archive = chemin(cfg["dossier_archives_installation"] + "/" + nom + "-" + horodatage)

    if not os.path.isdir(dest_addons):
        print("dossier AddOns introuvable :", dest_addons)
        return 2
    print("source  :", source)
    print("cible   :", cible, "(existe déjà)" if os.path.exists(cible) else "(nouvelle)")
    if os.path.exists(cible):
        print("archive :", archive)
    if simuler:
        print("simulation : rien n'a été modifié.")
        return 0

    verif = subprocess.run([sys.executable, "-X", "utf8", os.path.join(RACINE, "outils", "verifier.py")],
                           capture_output=True, text=True, encoding="utf-8")
    if verif.returncode != 0:
        print(verif.stdout)
        print("Vérification en échec : rien n'est installé.")
        return 1

    # 1. copie de travail dans le projet, vérifiée
    prepa = chemin("essais/installation/" + horodatage + "/" + nom)
    shutil.copytree(source, prepa)
    ecarts, n, octets = comparer(source, prepa)
    if ecarts:
        print("copie de travail différente :", *ecarts, sep="\n  ")
        return 1

    # 2. ancienne version mise de côté (déplacée, jamais supprimée)
    ancienne = False
    if os.path.exists(cible):
        os.makedirs(os.path.dirname(archive), exist_ok=True)
        shutil.move(cible, archive)
        ancienne = True

    # 3. installation + vérification SHA256 contre la source
    shutil.copytree(prepa, cible)
    ecarts, n, octets = comparer(source, cible)
    if ecarts:
        print("ÉCART après installation :", *ecarts, sep="\n  ")
        if ancienne:
            shutil.move(cible, chemin("essais/installation/" + horodatage + "/rate"))
            shutil.move(archive, cible)
            print("ancienne version remise en place.")
        return 1
    print(f"installé : {n} fichiers, {octets} octets, SHA256 identique à la source.")
    if ancienne:
        print("ancienne version rangée dans", archive)
    return 0


if __name__ == "__main__":
    sys.exit(main())
