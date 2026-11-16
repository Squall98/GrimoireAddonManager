# Tests de l'outil du journal : lecteur Lua (deux styles d'écriture), fichier jamais modifié, page fabriquée.
import hashlib, subprocess, sys, tempfile
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI.parent))
sys.path.insert(0, str(ICI))
import commun   # noqa: E402  (sérialiseur Lua du projet)
import journal  # noqa: E402

ERREURS = [
    {"id": 1, "addon": "RareScanner", "version": "1.60.1.7", "fichier": "Core.lua", "ligne": 212,
     "message": 'attempt to index a nil value (field "pin")\nsecond line', "pile": "Interface\\AddOns\\RareScanner\\Core.lua:212",
     "n": 14, "premiere": 1763200000, "derniere": 1763203600, "combat": True, "session": 2, "client": "1.60.1",
     "langue": "frFR", "gestionnaire": "0.7.0"},
    {"id": 2, "addon": "Questie", "version": "11.3", "fichier": "Tracker.lua", "ligne": 7, "message": "é à ç — <b>",
     "pile": "", "n": 1, "premiere": 1763201000, "derniere": 1763201000, "combat": False, "session": 2,
     "client": "1.60.1", "langue": "frFR", "gestionnaire": "0.7.0"},
]
ok = 0


def verifie(cond, quoi):
    global ok
    if not cond:
        print("ÉCHEC :", quoi); sys.exit(1)
    ok += 1


# 1. style du projet (clés nues)
texte = "MesAddonsDB = " + commun.lua({"erreurs_journal": {"liste": ERREURS, "suivant": 3}, "reglages": {"x": 1}}) + "\n"
sv = journal.LecteurLua(texte).affectations()
verifie(sv["MesAddonsDB"]["erreurs_journal"]["liste"] == ERREURS, "relecture du style projet")

# 2. style du jeu (["clé"] = valeur, commentaires de fin de table)
wow = ('MesAddonsDB = {\n["erreurs_journal"] = {\n["liste"] = {\n{\n["addon"] = "GTFO",\n["ligne"] = 3,\n'
       '["message"] = "a\\"b\\\\c\\233",\n["n"] = 2,\n["combat"] = false,\n}, -- [1]\n},\n["suivant"] = 2,\n},\n}\n'
       'MesAddonsPerso = nil\n')
sv = journal.LecteurLua(wow).affectations()
e = sv["MesAddonsDB"]["erreurs_journal"]["liste"][0]
verifie(e["addon"] == "GTFO" and e["n"] == 2 and e["combat"] is False, "style du jeu")
verifie(e["message"] == 'a"b\\c' + chr(233), "échappements")

# 3. fichier jamais modifié + page fabriquée
with tempfile.TemporaryDirectory() as d:
    f = Path(d) / "MesAddons.lua"
    f.write_text(texte, encoding="utf-8")
    avant = hashlib.sha256(f.read_bytes()).hexdigest()
    r = subprocess.run([sys.executable, str(ICI / "journal.py"), "--source", str(f), "--sortie", d, "--ne-pas-ouvrir"],
                       capture_output=True, text=True, encoding="utf-8")
    verifie(r.returncode == 0, "outil sans erreur : " + r.stdout + r.stderr)
    verifie(hashlib.sha256(f.read_bytes()).hexdigest() == avant, "fichier du jeu intact")
    pages = list(Path(d).glob("journal-erreurs-*.html"))
    verifie(len(pages) == 1, "une page fabriquée")
    p = pages[0].read_text(encoding="utf-8")
    verifie("RareScanner" in p and "Tracker.lua" in p and "__DONNEES__" not in p, "contenu de la page")
    verifie("<b>" not in p.split("const D =")[1].split(";\n")[0] or "\\u003c" in p or "<b>" in p, "données injectées")

print(f"{ok} vérifications réussies")
