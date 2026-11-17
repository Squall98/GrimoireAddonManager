-- Espace commun de l'add-on : tous les fichiers reçoivent le même (nom, ns).
local nom, ns = ...
ns.nom = nom
ns.donnees = ns.donnees or { textes = {} }
