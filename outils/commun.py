"""Outils partagés de Mes Add-ons : chemins (lus dans outils/config.json), sérialisation Lua, hachage."""
import hashlib
import json
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def config():
    with open(os.path.join(RACINE, "outils", "config.json"), encoding="utf-8") as f:
        return json.load(f)


def chemin(rel):
    """Chemin absolu d'un chemin relatif à la racine du projet."""
    return os.path.normpath(os.path.join(RACINE, rel))


def lire_json(rel):
    with open(chemin(rel), encoding="utf-8") as f:
        return json.load(f)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for bloc in iter(lambda: f.read(65536), b""):
            h.update(bloc)
    return h.hexdigest()


_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _chaine(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r")
    return '"' + s + '"'


def lua(v, niveau=0):
    """Sérialise une valeur JSON en littéral Lua (clés triées, UTF-8)."""
    marge = "\t" * (niveau + 1)
    fin = "\t" * niveau
    if v is None:
        return "nil"
    if v is True:
        return "true"
    if v is False:
        return "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return _chaine(v)
    if isinstance(v, list):
        if not v:
            return "{}"
        return "{\n" + "".join(marge + lua(x, niveau + 1) + ",\n" for x in v) + fin + "}"
    if isinstance(v, dict):
        if not v:
            return "{}"
        out = []
        for k in sorted(v):
            cle = k if _IDENT.match(k) and k not in LUA_MOTS else "[" + _chaine(k) + "]"
            out.append(marge + cle + " = " + lua(v[k], niveau + 1) + ",\n")
        return "{\n" + "".join(out) + fin + "}"
    raise TypeError(type(v))


LUA_MOTS = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in",
            "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
