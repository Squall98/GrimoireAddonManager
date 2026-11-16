# Journal des erreurs de Mes Add-ons -> page HTML.
# Lit le fichier de sauvegarde du jeu (WTF\Account\<compte>\SavedVariables\MesAddons.lua) SANS LE MODIFIER
# (ouverture en lecture seule, empreinte SHA256 contrôlée avant/après) et fabrique une page HTML lisible.
#
#   python journal.py                    cherche le(s) fichier(s) de sauvegarde et fabrique la page
#   python journal.py --source <fichier> lit ce fichier-là
#   python journal.py --sortie <dossier> écrit la page dans ce dossier
#   python journal.py --exemple          fabrique une page avec un journal d'exemple (sans le jeu)
#   python journal.py --ne-pas-ouvrir    n'ouvre pas la page à la fin
import argparse, datetime, hashlib, html, json, os, sys, webbrowser
from pathlib import Path

ICI = Path(__file__).resolve().parent
REGLAGES = json.loads((ICI / "reglages.json").read_text(encoding="utf-8"))
TEXTES = json.loads((ICI / "textes.json").read_text(encoding="utf-8"))


# ---------- lecture d'une table Lua de sauvegarde (sous-ensemble utilisé par WoW) ----------
class LecteurLua:
    def __init__(self, texte):
        self.t, self.i = texte, 0

    def blancs(self):
        t = self.t
        while self.i < len(t):
            c = t[self.i]
            if c in " \t\r\n":
                self.i += 1
            elif t.startswith("--", self.i):
                fin = t.find("\n", self.i)
                self.i = len(t) if fin < 0 else fin + 1
            else:
                break

    def valeur(self):
        self.blancs()
        t, c = self.t, self.t[self.i]
        if c == "{":
            return self.table()
        if c == '"' or c == "'":
            return self.chaine()
        for mot, v in (("true", True), ("false", False), ("nil", None)):
            if t.startswith(mot, self.i):
                self.i += len(mot)
                return v
        return self.nombre()

    def nombre(self):
        t, d = self.t, self.i
        while self.i < len(t) and t[self.i] in "+-0123456789.eExXabcdefABCDEF":
            self.i += 1
        brut = t[d:self.i]
        try:
            return int(brut, 0)
        except ValueError:
            return float(brut)

    def chaine(self):
        t, q = self.t, self.t[self.i]
        self.i += 1
        out = []
        while True:
            c = t[self.i]
            if c == q:
                self.i += 1
                return "".join(out)
            if c == "\\":
                self.i += 1
                e = t[self.i]
                if e.isdigit():
                    n = ""
                    while len(n) < 3 and t[self.i].isdigit():
                        n += t[self.i]; self.i += 1
                    out.append(chr(int(n)))
                    continue
                out.append({"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "\n": "\n"}.get(e, e))
                self.i += 1
                continue
            out.append(c)
            self.i += 1

    def table(self):
        self.i += 1
        d, n = {}, 1
        while True:
            self.blancs()
            if self.t[self.i] == "}":
                self.i += 1
                break
            if self.t[self.i] == "[":
                self.i += 1
                cle = self.valeur()
                self.blancs(); self.i += 1  # ]
                self.blancs(); self.i += 1  # =
                d[cle] = self.valeur()
            else:
                j = self.i
                while j < len(self.t) and (self.t[j].isalnum() or self.t[j] == "_"):
                    j += 1
                k = j
                while k < len(self.t) and self.t[k] in " \t\r\n":
                    k += 1
                if j > self.i and not self.t[self.i].isdigit() and self.t[k:k + 1] == "=" and self.t[k:k + 2] != "==" \
                        and self.t[self.i:j] not in ("true", "false", "nil"):
                    cle = self.t[self.i:j]
                    self.i = k + 1
                    d[cle] = self.valeur()
                else:
                    d[n] = self.valeur(); n += 1
            self.blancs()
            if self.t[self.i] in ",;":
                self.i += 1
        if d and all(isinstance(k, int) for k in d) and sorted(d) == list(range(1, len(d) + 1)):
            return [d[k] for k in range(1, len(d) + 1)]
        return d

    def affectations(self):
        res = {}
        while True:
            self.blancs()
            if self.i >= len(self.t):
                return res
            d = self.i
            while self.t[self.i] not in " =\t\r\n":
                self.i += 1
            nom = self.t[d:self.i]
            self.blancs(); self.i += 1  # =
            res[nom] = self.valeur()


def lire_sauvegarde(chemin):
    brut = chemin.read_bytes()  # lecture seule
    return LecteurLua(brut.decode("utf-8", errors="replace")).affectations(), hashlib.sha256(brut).hexdigest()


def trouver_sauvegardes():
    wtf = (ICI / REGLAGES["dossier_wtf"]).resolve()
    return sorted(wtf.glob("Account/*/SavedVariables/" + REGLAGES["fichier_sauvegarde"]))


# ---------- page ----------
def exemple():
    maintenant = int(datetime.datetime.now().timestamp())
    def e(i, addon, fichier, ligne, msg, n, decal, combat=False):
        return {"id": i, "addon": addon, "version": "1.0", "fichier": fichier, "ligne": ligne, "message": msg,
                "pile": f"[string \"@Interface/AddOns/{addon}/{fichier}\"]:{ligne}: in function <...>\n[C]: in function 'pcall'",
                "n": n, "premiere": maintenant - decal, "derniere": maintenant - decal // 3, "combat": combat,
                "session": 3, "client": "1.60.1", "langue": "frFR", "gestionnaire": "0.7.0"}
    return {"liste": [
        e(1, "RareScanner", "Core.lua", 212, "attempt to index a nil value (field 'pin')", 14, 3600),
        e(2, "RareScanner", "Map.lua", 88, "bad argument #1 to 'pairs' (table expected, got nil)", 2, 1800, True),
        e(3, "Questie", "Modules/Tracker.lua", 1043, "attempt to compare number with nil", 1, 600),
    ], "suivant": 4, "sessions": 3}


def fabriquer_page(journal, source, empreinte):
    erreurs = journal.get("liste", []) if isinstance(journal, dict) else []
    donnees = {"erreurs": erreurs, "source": str(source), "empreinte": empreinte,
               "genere": datetime.datetime.now().strftime(REGLAGES["format_date"]), "textes": TEXTES}
    modele = (ICI / "modele.html").read_text(encoding="utf-8")
    return modele.replace("__TITRE__", html.escape(TEXTES["titre"])).replace(
        "__DONNEES__", json.dumps(donnees, ensure_ascii=False).replace("</", "<\\/"))


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap =argparse.ArgumentParser(description=TEXTES["aide_outil"])
    ap.add_argument("--source"); ap.add_argument("--sortie"); ap.add_argument("--exemple", action="store_true")
    ap.add_argument("--ne-pas-ouvrir", action="store_true")
    a = ap.parse_args()
    sortie = Path(a.sortie) if a.sortie else (ICI / REGLAGES["dossier_sortie"])
    sortie.mkdir(parents=True, exist_ok=True)

    if a.exemple:
        sources = [("exemple", exemple(), "-")]
    else:
        chemins = [Path(a.source)] if a.source else trouver_sauvegardes()
        if not chemins:
            print(TEXTES["aucun_fichier"]); return 1
        sources = []
        for c in chemins:
            sv, avant = lire_sauvegarde(c)
            db = sv.get(REGLAGES["variable"], {}) or {}
            sources.append((c, db.get(REGLAGES["cle_journal"], {}) or {}, avant))
            apres = hashlib.sha256(c.read_bytes()).hexdigest()
            if apres != avant:
                print(TEXTES["fichier_change"].format(c)); return 2

    for src, journal, empreinte in sources:
        compte = src.parent.parent.name if isinstance(src, Path) else "exemple"
        page = sortie / REGLAGES["nom_page"].format(compte=compte)
        page.write_text(fabriquer_page(journal, src, empreinte), encoding="utf-8")
        n = len(journal.get("liste", [])) if isinstance(journal, dict) else 0
        print(TEXTES["page_faite"].format(page=page, n=n))
        if not a.ne_pas_ouvrir:
            webbrowser.open(page.as_uri())
    return 0


if __name__ == "__main__":
    sys.exit(main())
