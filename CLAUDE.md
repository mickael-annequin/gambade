# Gambade 🐶

## Le projet
Application « compagnon de balade » pour mon chien. Pendant une balade, l'app enregistre :
- le trajet GPS (affiché sur une carte),
- la distance (km) et la durée,
- le nombre de chiens rencontrés,
- des photos géolocalisées liées à la balade.
Elle garde aussi un historique et des statistiques des balades.

- **Utilisateur** : moi seul pour l'instant (une connexion est quand même prévue, car l'app sera en ligne).
- **Objectifs** : apprendre à construire un vrai projet de A à Z + projet portfolio.
- **Interface** : en français. **Code** (variables, classes, commits) : en anglais.
- **Support** : site web pensé d'abord pour le mobile (téléphone Android), installable en PWA.
- **Budget** : gratuit (offres gratuites des services). Passer à un service payant seulement si c'est vraiment nécessaire, et après en avoir discuté.

## Versions prévues
- **V1 — PWA (Rails 8)** : suivi GPS via l'API de géolocalisation du navigateur. Limite connue : le navigateur ne suit la position que si la page reste ouverte. Pour compenser :
  - garder l'écran allumé pendant la balade avec l'API *Screen Wake Lock* ;
  - sauvegarder les points GPS au fur et à mesure dans le navigateur (localStorage/IndexedDB), pour ne rien perdre si la page se ferme, et pouvoir reprendre la balade ;
  - ignorer les points GPS trop imprécis ;
  - permettre de saisir ou corriger une balade à la main.
- **V2 — App Android native avec Capacitor** : on emballe l'app web dans une app Android pour avoir le **GPS en arrière-plan** (téléphone en poche, écran éteint) grâce à un plugin Capacitor en JavaScript. Choisi plutôt que Hotwire Native, parce que cette fonction native s'écrit en JS et ne demande ni Swift ni Kotlin. Build et installation depuis Windows (Android Studio), gratuitement.
- Le code V1 doit faciliter la V2 : toute la logique de suivi GPS est isolée dans un seul contrôleur Stimulus, pour pouvoir remplacer la source de position plus tard.

## Stack technique
| Besoin | Choix | Pourquoi |
|---|---|---|
| Framework | Ruby on Rails 8 | Enseigné au Wagon, PWA intégrée |
| Base de données | PostgreSQL | Enseigné au Wagon |
| Front | HTML/ERB, CSS (SCSS), Bootstrap | Enseigné au Wagon |
| JavaScript | Stimulus (+ Turbo) | Standard Rails / Wagon |
| Connexion | Devise | Enseigné au Wagon |
| Carte | Mapbox GL JS (offre gratuite) | Enseigné au Wagon |
| Photos | Active Storage + Cloudinary (offre gratuite) | Enseigné au Wagon |
| App mobile (V2) | Capacitor + Android Studio | GPS en arrière-plan en JS |
| Hébergement | À choisir au moment de la mise en ligne (offre gratuite) | Heroku n'a plus d'offre gratuite |

Environnement de dev : Windows + VS Code (extension WSL), avec **WSL2 Ubuntu 24.04** (utilisateur `mika`). Installé : Ruby 3.4.11 (rbenv), Rails 8.1.4, PostgreSQL 16, Node 24 LTS (nvm). Projet dans `~/code/mickael-annequin/gambade`. Les commandes Rails se lancent dans le terminal Ubuntu.

## Structure des dossiers (Rails standard)
```
gambade/
├── app/
│   ├── models/                  # Les données (balades, points GPS, photos…)
│   ├── controllers/             # La logique des pages
│   ├── views/                   # Les pages HTML (ERB)
│   │   └── pwa/                 # Manifest et service worker de la PWA
│   ├── javascript/controllers/  # Contrôleurs Stimulus (suivi GPS, carte…)
│   └── assets/stylesheets/      # Le CSS
├── config/
│   ├── routes.rb                # Les URLs de l'app
│   └── credentials.yml.enc      # Clés API chiffrées (Mapbox, Cloudinary…)
├── db/
│   ├── migrate/                 # Historique des modifications de la base
│   └── schema.rb                # Référence : état actuel de la base
├── docs/                        # Roadmap et notes du projet
├── test/                        # Les tests
└── mobile/                      # Projet Capacitor (V2 seulement)
```
- **Ne jamais mettre de clé API en dur dans le code** : toujours passer par `config/credentials.yml.enc` (ou un `.env` ignoré par Git).
- Pour connaître la structure de la base, se référer à `db/schema.rb` (généré automatiquement, ne pas le modifier à la main).

## Conventions de code
- Conventions Rails : modèles au singulier (`Walk`), tables et contrôleurs au pluriel (`walks`, `WalksController`), routes REST (`resources`).
- Ruby : 2 espaces d'indentation, `snake_case` pour les méthodes et variables, `CamelCase` pour les classes.
- JavaScript : `camelCase`, un contrôleur Stimulus par fonctionnalité.
- CSS : un fichier par composant dans `stylesheets/components/`, comme au Wagon.
- Noms dans le code en anglais, textes affichés en français.
- Code simple et lisible avant tout : pas d'abstraction prématurée. Commenter seulement ce qui n'est pas évident.
- Git : petits commits fréquents, messages courts en anglais au présent (ex. `Add walk tracking page`).
- Ne jamais committer de secrets (mots de passe, clés API) : voir la règle sur les credentials plus haut.

## Règles de travail avec Claude
- **Toujours répondre en français.**
- Je suis débutant (Prepwork du Wagon fait, bootcamp en cours) : expliquer simplement ce que tu fais et pourquoi, sans jargon inutile.
- Je construis en « vibe coding », mais je veux apprendre au passage : explique les notions nouvelles quand elles apparaissent.
- Avancer **par petites étapes**, une chose à la fois.
- **Demander mon accord avant** : toute grosse modification, l'ajout d'une dépendance (gem, package npm) et toute commande qui installe quelque chose.
- Privilégier les technologies du Wagon (HTML/CSS, JavaScript, Rails, PostgreSQL). Si une autre est vraiment plus adaptée, expliquer pourquoi avant de la proposer.
- À la fin de chaque étape : dire **comment tester le résultat moi-même** (commande à lancer, page à ouvrir, ce que je dois voir).
- Je suis sur Windows avec VS Code : donner les commandes adaptées (terminal Ubuntu/WSL pour Rails).
- Les commandes avec `sudo` (mot de passe), c'est moi qui les lance ; Claude vérifie le résultat ensuite.
- Dans un bloc de commandes à copier-coller, ne jamais mettre de ligne après `exec bash` (elle serait perdue) : `exec bash` seul, dans son propre bloc.
