# Roadmap — Gambade 🐶

On coche chaque étape (`- [x]`) quand elle est terminée et testée.
Le détail des fonctionnalités est dans [brainstorming.md](brainstorming.md).

## Phase 0 — Préparer l'environnement
- [x] **Installer les outils** : WSL2 + Ubuntu 24.04, Git + clé SSH GitHub, rbenv + Ruby 3.4.11, Rails 8.1.4, PostgreSQL 16, nvm + Node 24 LTS, extension WSL de VS Code.
  - Installation faite avant le bootcamp. Le jour 1, ajuster si besoin selon les consignes du Wagon (ils utiliseront Cursor, qui fonctionne de la même façon avec WSL).
  - *Test :* `ruby -v`, `rails -v`, `git --version`, `psql --version` et `node -v` répondent dans le terminal Ubuntu.

## Phase 0.5 — Conception ✏️
> Cette phase peut se faire **tout de suite**, sans attendre l'installation de l'environnement : on travaille sur papier et dans `docs/`, sans code.

- [x] **Parcours utilisateur et liste des écrans** ([conception/parcours.md](conception/parcours.md)) : ce que je fais dans l'app, dans quel ordre, et les écrans nécessaires au MVP. *Test :* je peux raconter une balade complète écran par écran.
- [x] **Wireframes de chaque écran du MVP** ([conception/wireframes.md](conception/wireframes.md)) : des croquis simples (emplacement des éléments, sans couleurs). *Test :* chaque écran de la liste a son wireframe.
- [x] **Identité visuelle simple** ([conception/identite.md](conception/identite.md)) : couleurs, police, ambiance, et éventuellement un logo. *Test :* une palette et une police choisies et notées dans `docs/`.
- [x] **Schéma de la base de données** ([conception/base-de-donnees.md](conception/base-de-donnees.md)) : les tables, leurs colonnes et leurs liens. *Test :* chaque info affichée dans les wireframes a sa place dans le schéma.

## Phase 1 — MVP 🥇
- [x] **Créer le projet** : `rails new gambade` avec PostgreSQL, y déplacer `CLAUDE.md` et `docs/`, puis Git et GitHub. *Test :* une page d'accueil s'affiche sur `localhost:3000`.
- [x] **Mise en ligne** sur Render (appli) + Neon (base PostgreSQL), offres gratuites : https://gambade.onrender.com. *Test :* le site s'ouvre en HTTPS sur mon téléphone.
- [x] **Connexion** avec Devise (inscription désactivée, compte unique, « Se souvenir de moi »). *Test :* se connecter, fermer le navigateur, revenir sans avoir à se reconnecter ; vérifier qu'on ne peut pas créer de compte.
- [ ] **Profil du chien** : modèle `Dog` et photo stockée sur Cloudinary. *Test :* créer et modifier la fiche de mon chien, avec sa photo.
- [ ] **Balades saisies à la main** : modèle `Walk` et pages pour créer, lire, modifier et supprimer une balade. *Test :* créer, modifier et supprimer une balade.
- [ ] **Carte Mapbox** sur la page d'une balade. *Test :* la carte s'affiche centrée sur ma ville.
- [ ] **Suivi GPS en direct** (contrôleur Stimulus) : Démarrer et Terminer, chrono, km, indicateur GPS, points enregistrés en base (pas de carte pendant la balade). *Test :* un tour du pâté de maisons, puis retrouver le trajet sur la carte de la balade.
- [ ] **Protection anti-perte** : écran maintenu allumé, points sauvegardés dans le téléphone, reprise d'une balade interrompue, points imprécis ignorés. *Test :* fermer l'app en pleine balade, la rouvrir et reprendre.
- [ ] **Bouton « +1 chien »** avec le lieu de la rencontre. *Test :* les rencontres apparaissent sur la carte de la balade.
- [ ] **Boutons « Jeu » et « Baignade »** (début/fin, utilisables en même temps). *Test :* faire une phase de chaque, dont une en même temps, et retrouver leurs durées et leurs lieux.
- [ ] **Résumé de fin de balade** avec ajout facultatif de détails sur chaque rencontre (nom, race, ressenti, note). *Test :* compléter une rencontre et retrouver ses détails.
- [ ] **Liste des balades**, chacune avec sa carte et ses stats. *Test :* une vraie balade complète avec mon chien. 🎉 **MVP terminé !**

## Phase 2 — V1 complète 🥈
- [ ] Notes de balade (humeur, besoins, commentaire)
- [ ] Carnet d'amis : table `friends`, lien rencontre → ami, classement des amis les plus croisés (dans « Mon chien »)
- [ ] Import de photos placées sur le trajet
- [ ] Statistiques par semaine/mois avec graphiques
- [ ] Carte globale de tous les trajets
- [ ] Météo automatique
- [ ] Mode sombre
- [ ] PWA installable sur l'écran d'accueil

## Phase 3 — V1+ 🥉
- [ ] Objectifs et badges
- [ ] Lieux favoris

## Phase 4 — V2 📱
- [ ] App Android avec Capacitor et GPS en arrière-plan

## Plus tard 🔮
- Photo des chiens rencontrés
- Nouvelles idées
