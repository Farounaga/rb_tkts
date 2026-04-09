# 07 - Bilan

## 7.1 Resultats obtenus

Le projet fournit un pipeline fonctionnel de bout en bout:
- import XML en streaming,
- generation d'embeddings locaux,
- clustering automatique,
- etiquetage de clusters par LLM local,
- mesure de qualite (elbow, silhouette),
- detection de similarites entre tickets,
- restitution via rapport HTML.

Le dossier documentaire BTS 01-07 est structure et exploitable pour la soutenance.

## 7.2 Apports

- Gain de temps d'analyse pour les equipes support.
- Meilleure visibilite sur les themes recurrents.
- Base technique claire pour evoluer vers une solution plus industrialisee.
- Demonstration d'une demarche complete SIO: besoin -> analyse -> conception -> realisation -> tests -> doc -> bilan.

## 7.3 Limites actuelles

- Pas encore de persistence relationnelle active en production (scripts fournis mais non integres au runtime).
- Pas d'API REST exposee pour consultation distante.
- Couverture de tests perfectible sur certains flux de bout en bout.
- Dashboard HTML perfectible en ergonomie et filtres metier.

## 7.4 Axes d'amelioration futurs

### Court terme

- Ajouter un nettoyage de texte plus pousse (signatures, bruit, auto-reponses).
- Etendre les tests d'integration sur jeux de donnees plus larges.
- Ajouter un rapport de run (manifest) horodate.

### Moyen terme

- Integrer une base de donnees relationnelle (PostgreSQL/SQLite) avec scripts migres.
- Exposer une API REST pour requeter clusters, metriques et similarites.
- Ajouter une interface web interactive (filtres dynamiques).

### Long terme

- CI/CD complet avec verification automatique des tests.
- Detection d'anomalies temporelles.
- Automatisation de syntheses mensuelles pour le pilotage support/produit.
