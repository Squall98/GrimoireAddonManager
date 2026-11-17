Actions rapides (étape B3-02) : activer seul, avec ses modules, essai d'une session, dépannage et retour, périmés, menu du bouton de minicarte, résumé, raccourcis.

# Actions

| Fichier | Rôle |
|---|---|
| `Modele.lua` | la logique : activer seul, activer complet (dépendances + modules utiles), essai (marque, fin à la connexion), dépannage et retour (état gardé dans le compte), périmés (CVar), compteur, résumé d'une ligne ; tout passe par `ns.Liste` (un seul pas d'Annuler) |
| `Commande.lua` | sous-commandes activer / desactiver / seul / essai / depannage / retour / recharger / perimes / annuler / resume (français et anglais) |
| `Connexion.lua` | à la connexion : fin des essais, résumé dans le chat (réglable), noms des raccourcis, fonction globale appelée par `Bindings.xml` |
| `Rapide.lua` | petit menu du clic droit sur le bouton de minicarte : recharger, liste des profils, dépannage, périmés, ouvrir |

`..\Bindings.xml` : les trois raccourcis clavier (fenêtre, profils, recharger). Réglages : `acces.*` et `actions.*` ; valeurs fixes : `donnees/reglages.json › actions`, `interface.rapide`.
