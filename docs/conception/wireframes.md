# Wireframes — Gambade (MVP)

Croquis simples : seulement l'organisation des éléments, sans couleurs ni design.
La liste des écrans est dans [parcours.md](parcours.md).

## Écran 2 : Accueil
```
┌─────────────────────────────┐
│ Gambade             [photo] │  ← photo du chien
│ Salut ! Prêt pour une       │
│ balade avec Rex ?           │
│                             │
│  ┌───────────────────────┐  │
│  │                       │  │
│  │   ▶ DÉMARRER UNE      │  │  ← très gros bouton,
│  │      BALADE           │  │    facile avec le pouce
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│ Cette semaine               │
│ ┌───────┐┌───────┐┌───────┐ │
│ │ 12,4  ││ 3h20  ││  9    │ │
│ │  km   ││ temps ││ chiens│ │
│ └───────┘└───────┘└───────┘ │
│                             │
│ Dernière balade             │
│ ┌─────────────────────────┐ │
│ │ [mini carte]  Hier 18h  │ │  ← touche → détail
│ │               2,3 km    │ │
│ │               35 min    │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│  🏠 Accueil  📋 Balades  🐶  │
└─────────────────────────────┘
```

## Écran 3 : Balade en cours
Pas de carte en direct : l'écran reste simple et lisible en marchant, et économise la batterie.
```
┌─────────────────────────────┐
│ ● GPS ok        avec Rex 🐶 │  ← vert / orange / rouge
│                             │
│          00:24:15           │
│            durée            │
│           1,8 km            │
│          distance           │
│                             │
│  ┌───────────────────────┐  │
│  │    🐕 +1 CHIEN  (4)   │  │  ← le plus gros bouton
│  └───────────────────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │ 🎾 JEU   │ │💦 BAIGNADE│  │  ← appui = début,
│  └──────────┘ └──────────┘  │    nouvel appui = fin
│                             │
│  ┌───────────────────────┐  │
│  │      ■ TERMINER       │  │  ← avec confirmation
│  └───────────────────────┘  │
└─────────────────────────────┘
   (pas de barre de navigation)

Pendant une phase, le bouton change (ici : jeu en cours) :
│  ┌──────────┐ ┌──────────┐  │
│  │🎾 03:12  │ │💦 BAIGNADE│  │  ← il clignote et affiche
│  │ ■ Arrêter│ │          │  │    la durée en cours
│  └──────────┘ └──────────┘  │
```
- Jeu et baignade sont **indépendants** : les deux peuvent être actifs en même temps (ex. lancer la balle dans l'eau).
- Chaque phase enregistre son début, sa fin et son lieu.
- « Terminer » arrête automatiquement les phases en cours.

## Écran 4 : Résumé de fin de balade
Les détails des rencontres sont facultatifs : on peut enregistrer sans rien remplir.
```
┌─────────────────────────────┐
│ Bravo ! Balade terminée 🎉  │
│                             │
│ ┌─────────────────────────┐ │
│ │  [CARTE DU TRAJET]      │ │  ← trajet + rencontres
│ │   ~~①~~🎾~~②~💦~③~~④     │ │    + jeu / baignade
│ └─────────────────────────┘ │
│                             │
│  35 min   2,3 km   4 chiens │
│  🎾 12 min de jeu           │
│  💦 1 baignade (8 min)      │
│                             │
│ Rencontres (facultatif)     │
│ ┌─────────────────────────┐ │
│ │ ① 18h12  + détails      │ │  ← touche → formulaire
│ │ ② 18h20  Filou, Beagle ✓│ │    de rencontre
│ │ ③ 18h31  + détails      │ │
│ │ ④ 18h40  + détails      │ │
│ └─────────────────────────┘ │
│                             │
│  ┌───────────────────────┐  │
│  │     ✓ ENREGISTRER     │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```
Détails possibles pour une rencontre (tous facultatifs) : nom du chien, race, comment ça s'est passé (😊 joueurs / 😐 neutre / 😠 tendu), note libre.

## Écran 5 : Liste des balades
```
┌─────────────────────────────┐
│ Mes balades     [+ Ajouter] │  ← saisie manuelle
│                             │
│ Octobre 2026                │  ← regroupées par mois
│ ┌─────────────────────────┐ │
│ │ [mini  ]  Aujourd'hui   │ │
│ │ [carte ]  18h05         │ │
│ │           2,3 km · 35min│ │
│ │           🐕 4 🎾 💦     │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ [mini  ]  Hier          │ │
│ │ [carte ]  08h30         │ │
│ │           1,1 km · 18min│ │
│ │           🐕 1          │ │
│ └─────────────────────────┘ │
│ Septembre 2026              │
│ ┌─────────────────────────┐ │
│ │ ...                     │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│  🏠 Accueil  📋 Balades  🐶  │
└─────────────────────────────┘
```

## Écran 6 : Détail d'une balade
```
┌─────────────────────────────┐
│ ← Retour            ✏️  🗑️  │  ← modifier / supprimer
│                             │     (confirmation)
│ Mardi 1er octobre · 18h05   │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │  [CARTE DU TRAJET]      │ │  ← on peut zoomer,
│ │   ~~①~~🎾~~②~💦~③~~④     │ │    toucher un point
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│  35 min   2,3 km   4 chiens │
│  🎾 12 min de jeu           │
│  💦 1 baignade (8 min)      │
│                             │
│ Rencontres                  │
│ ┌─────────────────────────┐ │
│ │ ① 18h12  + détails      │ │  ← on peut encore
│ │ ② 18h20  Filou, Beagle 😊│ │    compléter après coup
│ │ ③ 18h31  + détails      │ │
│ │ ④ 18h40  Rocky 😠       │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│  🏠 Accueil  📋 Balades  🐶  │
└─────────────────────────────┘
```
Une balade saisie à la main n'a pas de trajet GPS : son détail affiche les stats, sans carte.

## Écran 7 : Formulaire de balade (ajout manuel ou modification)
```
┌─────────────────────────────┐
│ ← Annuler   Nouvelle balade │  ← ou « Modifier la balade »
│                             │
│ Date                        │
│ [ 01/10/2026          📅 ]  │
│ Heure de départ             │
│ [ 18:05               🕐 ]  │
│ Durée (minutes)             │
│ [ 35                     ]  │
│ Distance (km)               │
│ [ 2,3                    ]  │
│ Chiens rencontrés           │
│ [ −  ]     4     [  + ]     │  ← boutons, pas de clavier
│                             │
│  ┌───────────────────────┐  │
│  │     ✓ ENREGISTRER     │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```
Ce formulaire ne gère pas le jeu ni la baignade : ceux-là viennent uniquement des balades suivies en direct.

## Écran 8 : Profil du chien
```
┌─────────────────────────────┐
│ Mon chien          [✏️ Modif]│
│                             │
│        ┌─────────┐          │
│        │ [PHOTO] │          │
│        └─────────┘          │
│           Rex               │
│     Border Collie · 4 ans   │  ← âge calculé depuis
│                             │    la date de naissance
│ Depuis le début             │
│ ┌───────┐┌───────┐┌───────┐ │
│ │ 152   ││ 48    ││ 87    │ │
│ │  km   ││balades││ chiens│ │
│ └───────┘└───────┘└───────┘ │
│                             │
│        [ Se déconnecter ]   │
├─────────────────────────────┤
│  🏠 Accueil  📋 Balades  🐶  │
└─────────────────────────────┘
```
En mode modification : photo, nom, race, date de naissance. On stocke la date de naissance plutôt que l'âge, pour que l'âge se mette à jour tout seul.

## Écran 1 : Connexion
Vu une seule fois par appareil, grâce à « Se souvenir de moi ». Pas d'inscription publique : le compte unique est créé une fois pour toutes.
```
┌─────────────────────────────┐
│                             │
│         [ LOGO ]            │
│         Gambade             │
│                             │
│ Email                       │
│ [                        ]  │
│ Mot de passe                │
│ [                        ]  │
│ [✓] Se souvenir de moi      │  ← coché par défaut
│                             │
│  ┌───────────────────────┐  │
│  │     SE CONNECTER      │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```
