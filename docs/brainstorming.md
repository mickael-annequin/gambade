# Brainstorming — Gambade 🐶

Décisions prises le 01/10/2026. Les idées sont classées par priorité. On pourra en ajouter au fil du projet.

## 🥇 MVP — première version utilisable en vraie balade
- Connexion (Devise) en version minimale : un seul compte créé à l'avance, inscription désactivée, « Se souvenir de moi » pour ne se connecter qu'une fois. Indispensable car l'app est en ligne : sans ça, n'importe qui pourrait voir mes trajets (et donc où j'habite).
- Profil simple du chien : nom, photo, race, âge.
- Balade en direct :
  - boutons Démarrer / Terminer ;
  - suivi GPS ;
  - chrono et kilomètres qui s'actualisent ;
  - indicateur de qualité du signal GPS ;
  - pas de carte en direct (écran plus lisible en marchant, économise la batterie) : le trajet s'affiche sur une carte Mapbox après la balade.
- Bouton « +1 chien » : compte un chien rencontré et enregistre le lieu de la rencontre.
- Boutons « Jeu » 🎾 et « Baignade » 💦 : un appui pour commencer, un autre pour arrêter. Chaque phase enregistre sa durée et son lieu. Les deux boutons sont indépendants et peuvent être actifs en même temps (ex. balle lancée dans l'eau).
- À la fin de la balade, possibilité (facultative) d'ajouter des détails sur chaque rencontre : nom du chien, race, comment ça s'est passé (😊 / 😐 / 😠), note libre.
- Protection anti-perte :
  - écran maintenu allumé (Wake Lock) ;
  - points GPS sauvegardés dans le téléphone au fur et à mesure ;
  - reprise possible d'une balade interrompue ;
  - points GPS trop imprécis ignorés.
- Liste des balades, avec la carte et les stats de chacune.
- Saisie ou correction manuelle d'une balade.
- Mise en ligne en HTTPS. Le GPS du navigateur ne fonctionne que sur un site sécurisé, et c'est indispensable pour tester en vraie balade.

## 🥈 V1 complète
- Photos importées après coup depuis la galerie, placées sur le trajet grâce à leur heure ou à leur position GPS (Cloudinary).
- Notes de balade : humeur, besoins (pipi/caca), commentaire libre.
- Carnet d'amis (accessible depuis « Mon chien ») : quand je complète une rencontre, je peux la lier à un ami connu ou ajouter le chien au carnet. Les amis sont classés du plus souvent croisé au moins souvent (« Filou · croisé 12 fois · dernière fois hier »).
- Statistiques par semaine et par mois (km, temps, rencontres), avec graphiques.
- Carte globale avec tous les trajets superposés.
- Météo enregistrée automatiquement.
- Mode sombre.
- App installable sur l'écran d'accueil (PWA).

## 🥉 V1+ — améliorations
- Objectifs et badges (ex. « 50 km ce mois-ci », « 100 chiens rencontrés »).
- Lieux favoris sur la carte : parc à chiens, point d'eau, zone à éviter…

## 🔮 Plus tard
- Photo des chiens rencontrés, ajoutée après coup dans les détails d'une rencontre.
- Toute nouvelle idée qui viendra en route.

## 📱 V2 — App Android
- Emballer l'app avec Capacitor pour avoir le GPS en arrière-plan (téléphone en poche, écran éteint).

## ❌ Écarté pour l'instant
- Partage des balades (lien public, image résumé) : les balades restent privées.
- Rappels et notifications.
- Prise de photo depuis l'app pendant la balade : on garde seulement l'import après coup.
- Mode hors-ligne complet : les balades se font en ville, où le réseau suffit.
