# Parcours utilisateur et écrans — Gambade (MVP)

## Parcours

**A. Première utilisation** (une seule fois)
Connexion avec mon compte (créé à l'avance, pas d'inscription publique) → création du profil de mon chien → accueil

**B. Une balade** (parcours principal)
Accueil → « Démarrer une balade » → balade en cours (chrono, km, « +1 chien ») → « Terminer » → résumé de la balade (détails des rencontres, facultatif) → accueil

**C. Consulter l'historique**
Accueil → liste des balades → détail d'une balade → modifier ou supprimer

**D. Reprise après interruption**
Je rouvre l'app pendant une balade → message « Balade en cours, reprendre ? » → retour sur la balade en cours

## Écrans du MVP (8)
1. **Connexion** : page fournie par Devise, juste habillée. Pas d'inscription publique, « Se souvenir de moi » activé : vue une seule fois par appareil
2. **Accueil** : gros bouton « Démarrer une balade », résumé de la dernière balade et petites stats
3. **Balade en cours** : indicateur GPS, chrono, km, compteur de chiens, bouton « +1 chien », boutons « Jeu » et « Baignade » (début/fin, utilisables en même temps) et bouton « Terminer ». Pas de carte en direct.
4. **Résumé de fin de balade** : carte du trajet avec les rencontres, stats, ajout facultatif de détails sur chaque rencontre, bouton « Enregistrer »
5. **Liste des balades** : de la plus récente à la plus ancienne (date, km, durée, chiens)
6. **Détail d'une balade** : carte, rencontres, stats, boutons Modifier et Supprimer
7. **Formulaire de balade** : un seul écran pour la création manuelle et pour la modification
8. **Profil du chien** : affichage et modification (nom, photo, race, âge)

## Navigation
Une barre en bas de l'écran avec 3 onglets : 🏠 Accueil · 📋 Balades · 🐶 Mon chien.
Elle est masquée pendant une balade en cours, pour éviter les fausses manipulations.
