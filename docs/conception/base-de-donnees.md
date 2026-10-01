# Schéma de la base de données — Gambade

Les noms des tables et des colonnes sont en anglais, comme le veut la convention Rails.
Une fois le projet créé, la référence à jour sera `db/schema.rb`. Ce document sert de plan de départ.

## Vue d'ensemble
```
users ──< dogs ──< walks ──< track_points   (points GPS)
            │            ├──< encounters >── friends   (V1)
            │            └──< activities     (jeu / baignade)
            └──< friends  (carnet d'amis, V1)

──<  =  « un … a plusieurs … »
ex. un chien a plusieurs balades, une balade a plusieurs rencontres
```

## Tables du MVP

### users : mon compte (colonnes créées par Devise)
| Colonne | Type | Exemple |
|---|---|---|
| email | texte | `toi@mail.com` |
| encrypted_password | texte | (mot de passe chiffré, jamais en clair) |

### dogs : mon chien
| Colonne | Type | Exemple |
|---|---|---|
| user_id | lien → users | |
| name | texte | `Rex` |
| breed | texte | `Border Collie` |
| birth_date | date | `2022-03-15` |
| *photo* | *Active Storage* | *(stockée sur Cloudinary, pas dans une colonne)* |

### walks : une balade
| Colonne | Type | Exemple |
|---|---|---|
| dog_id | lien → dogs | |
| started_at | date + heure | `2026-10-01 18:05` |
| duration_seconds | entier | `2100` (= 35 min) |
| distance_meters | entier | `2300` (= 2,3 km) |
| dogs_met_count | entier | `4` |
| tracked | vrai/faux | `true` = GPS, `false` = saisie manuelle |

### track_points : les points GPS du trajet (environ un toutes les 5 à 10 s)
| Colonne | Type | Exemple |
|---|---|---|
| walk_id | lien → walks | |
| latitude / longitude | décimal | `48.8566` / `2.3522` |
| accuracy | décimal | `8.5` (précision en mètres) |
| recorded_at | date + heure | |

### encounters : un chien rencontré
| Colonne | Type | Exemple |
|---|---|---|
| walk_id | lien → walks | |
| latitude / longitude | décimal | |
| met_at | date + heure | `18:12` |
| dog_name | texte, facultatif | `Filou` |
| breed | texte, facultatif | `Beagle` |
| mood | choix, facultatif | `joyful` 😊 / `neutral` 😐 / `tense` 😠 |
| note | texte long, facultatif | `Très joueur` |
| friend_id | lien → friends, facultatif | **ajouté en V1** |

### activities : une phase de jeu ou de baignade
| Colonne | Type | Exemple |
|---|---|---|
| walk_id | lien → walks | |
| kind | choix | `play` 🎾 / `swim` 💦 |
| started_at / ended_at | date + heure | `18:20` → `18:28` |
| latitude / longitude | décimal | lieu du début de la phase |

## Table prévue en V1

### friends : le carnet d'amis de mon chien
| Colonne | Type | Exemple |
|---|---|---|
| dog_id | lien → dogs | (mon chien) |
| name | texte | `Filou` |
| breed | texte, facultatif | `Beagle` |
| note | texte long, facultatif | `Habite près du parc` |

- Une rencontre peut être liée à un ami (`encounters.friend_id`) ; sinon elle garde ses propres `dog_name` et `breed`.
- Le nombre de rencontres avec un ami **n'est pas stocké** : il se calcule (`friend.encounters.count`). Ça permet de classer les amis du plus souvent croisé au moins souvent.
- `mood` et `note` restent sur la rencontre : un même ami peut être joueur un jour et grognon le lendemain.

## Choix expliqués
- **Distances en mètres et durées en secondes, en entiers** : plus précis, sans erreurs d'arrondi. On convertit en « 2,3 km » et « 35 min » seulement à l'affichage.
- **`dogs_met_count` sur la balade** : une balade manuelle a un nombre de chiens, mais pas de rencontres localisées. Pour une balade GPS, le compteur augmente à chaque « +1 chien ».
- **Jeu et baignade dans une seule table `activities`** : même fonctionnement, seul `kind` change. On évite de dupliquer le code.
- **Balades liées au chien, pas directement à l'utilisateur** : plus logique (« la balade de Rex »), et permettra d'ajouter un deuxième chien un jour.
- **Pas de colonnes pour le reste de la V1** (météo, notes, photos de balade) : on les ajoutera le moment venu, avec des migrations.
