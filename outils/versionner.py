"""Versions de Mes Add-ons dans un dépôt git LOCAL (rien n'est envoyé sur Internet : pas de remote, pas de push).

  python -X utf8 outils/versionner.py "message"        vérifie tout, puis enregistre une version (commit) et pose l'étiquette vX.Y.Z
  python -X utf8 outils/versionner.py --etat           ce qui a changé depuis la dernière version
  python -X utf8 outils/versionner.py --historique     les versions enregistrées

Le dépôt est à la racine du projet mais ne suit que addon/, outils/ et donnees/ (le reste est exclu dans .git/info/exclude).
"""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from commun import RACINE, chemin, config  # noqa: E402

SUIVI = ["addon", "outils", "donnees"]


def git(*args, check=True):
    r = subprocess.run(["git", "-C", RACINE, *args], capture_output=True, text=True, encoding="utf-8")
    if check and r.returncode != 0:
        raise SystemExit("git " + " ".join(args) + " : " + (r.stderr or r.stdout).strip())
    return r.stdout.strip()


def version_toc():
    cfg = config()
    toc = chemin(cfg["dossier_addon"] + "/" + cfg["nom_addon"] + ".toc")
    m = re.search(r"^##\s*Version:\s*(\S+)", open(toc, encoding="utf-8").read(), re.M)
    return m.group(1) if m else "0"


def main():
    args = sys.argv[1:]
    if not os.path.isdir(os.path.join(RACINE, ".git")):
        git("init", "-q")
        git("config", "user.name", "Mes Add-ons")
        git("config", "user.email", "mes-addons@localhost")
        with open(os.path.join(RACINE, ".git", "info", "exclude"), "a", encoding="utf-8") as f:
            f.write("# Mes Add-ons : seuls addon/, outils/ et donnees/ sont versionnés ici\n"
                    "outils/banc/lua51/\n__pycache__/\n*.pyc\n")
        print("dépôt git local créé (aucun remote).")
    if "--etat" in args:
        print(git("status", "--short", "--", *SUIVI) or "rien n'a changé")
        return 0
    if "--historique" in args:
        print(git("log", "--oneline", "--decorate", check=False) or "aucune version")
        return 0
    message = " ".join(a for a in args if not a.startswith("--"))
    if not message:
        print(__doc__)
        return 2
    verif = subprocess.run([sys.executable, "-X", "utf8", os.path.join(RACINE, "outils", "verifier.py")],
                           capture_output=True, text=True, encoding="utf-8")
    if verif.returncode != 0:
        print(verif.stdout)
        print("Vérification en échec : aucune version enregistrée.")
        return 1
    changelog = os.path.join(RACINE, "outils", "fabriquer_changelog.py")
    for etape in (["--verifier"], []):
        r = subprocess.run([sys.executable, "-X", "utf8", changelog, *etape], capture_output=True, text=True, encoding="utf-8")
        if r.returncode != 0:
            print(r.stdout + r.stderr)
            print("Ajoute la version dans donnees/changelog.json : aucune version enregistrée.")
            return 1
    git("add", "--", *SUIVI, "CHANGELOG.md")
    if not git("status", "--porcelain", "--", *SUIVI):
        print("rien à enregistrer.")
        return 0
    version = version_toc()
    git("commit", "-q", "-m", f"v{version} : {message}")
    etiquette = "v" + version
    if git("tag", "-l", etiquette):
        etiquette += "-" + git("rev-parse", "--short", "HEAD")
    git("tag", etiquette)
    print(f"version enregistrée : {etiquette} ({git('rev-parse', '--short', 'HEAD')})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
