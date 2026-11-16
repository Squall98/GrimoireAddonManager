"""Repère les add-ons installés sans fiche (ou avec une fiche incomplète).
Usage : python sans-fiche.py [dossier AddOns]      (code de sortie 0 = rien à signaler)
Lit fiches.json, categories.json, profils.json à côté de lui. Ne modifie rien."""
import json, os, sys
ICI = os.path.dirname(os.path.abspath(__file__))
DEFAUT = r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns"
ADDONS = sys.argv[1] if len(sys.argv) > 1 else DEFAUT
charge = lambda n: json.load(open(os.path.join(ICI, n), encoding="utf-8"))
F, C, P = charge("fiches.json")["fiches"], charge("categories.json")["categories"], charge("profils.json")["profils"]
inst = sorted(d for d in os.listdir(ADDONS) if os.path.isdir(os.path.join(ADDONS, d)))
sans = [d for d in inst if d not in F]
inc = []
for d in inst:
    e = F.get(d)
    if not e: continue
    pb = []
    if not e.get("categories") or any(c not in C for c in e["categories"]): pb.append("catégorie")
    if not e.get("curseforge") and not e.get("note_lien"): pb.append("lien (ni adresse ni explication)")
    if e.get("utilite") not in ("indispensable", "confort", "gadget"): pb.append("utilité")
    for l in ("fr", "en"):
        if not (e.get(l) or {}).get("resume"): pb.append("fiche " + l.upper())
    if pb: inc.append((d, pb))
for k, p in P.items():
    for d in p["addons"]:
        if d not in inst: inc.append(("profil " + k, ["add-on absent : " + d]))
print(f"{len(inst)} add-ons installés, {len(F)} fiches.")
print("Sans fiche :", ", ".join(sans) if sans else "(aucun)")
print("Fiches incomplètes :", "; ".join(f"{d} [{', '.join(p)}]" for d, p in inc) if inc else "(aucune)")
sys.exit(1 if sans or inc else 0)
