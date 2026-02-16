# Métriques expliquées simplement

## 1) Elbow (méthode du coude)
- On teste plusieurs valeurs de `k` pour KMeans (ex: 2 à 12).
- Pour chaque `k`, on calcule l'inertie (distance interne des points aux centres).
- Le « coude » de la courbe donne une valeur de `k` raisonnable.

## 2) Silhouette score
- Mesure la séparation des clusters (entre -1 et 1).
- Proche de 1 = clusters bien séparés.
- Proche de 0 = clusters qui se chevauchent.
- Négatif = clustering souvent mauvais.

## 3) Similarité cosinus
- Compare deux embeddings de tickets.
- Plus le score est proche de 1, plus les tickets se ressemblent.
- Seuil pratique pour doublons probables: `0.80`.

## Sorties générées
- `clustering_metrics.json` : elbow + silhouette.
- `similar_tickets.json` : top-k tickets similaires pour chaque ticket.
