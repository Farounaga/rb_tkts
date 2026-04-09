# 06 - Documentation

## 6.1 Documentation technique

### Installation

1. Installer Ruby >= 3.3.10.
2. Installer les dependances: `bundle install`.
3. Copier `.env.example` vers `.env`.
4. Verifier l'environnement: `bundle exec ruby bin/check_env.rb`.

### Deploiement (mode local)

1. Renseigner les variables de configuration dans `.env`.
2. Verifier Ollama et les modeles necessaires.
3. Lancer le pipeline: `bundle exec ruby main.rb`.
4. Ouvrir le rapport: `output/visualisation.html`.

### Parametres techniques principaux

- `TICKETS_XML_PATH`
- `MAX_TICKETS`
- `RUN_EMBEDDINGS`
- `RUN_CLUSTERING`
- `RUN_CLUSTER_TOPICS`
- `RUN_CLUSTERING_METRICS`
- `RUN_SIMILARITY`
- `OLLAMA_BASE_URL`
- `OLLAMA_EMBED_MODEL`
- `OLLAMA_LLM_MODEL`
- `KMEANS_K`

### Documentation de reference

- README principal: `README.md`
- Flux d'execution: `docs/code_flow.md`
- Metriques: `docs/metrics_expliquees.md`
- Checklist production: `docs/production_checklist.md`

## 6.2 Documentation utilisateur

### Public cible

- Equipe support
- Responsable support
- Equipe produit/technique

### Guide d'utilisation rapide

1. Exporter les tickets au format XML depuis l'outil source.
2. Placer le fichier XML sur le poste local.
3. Renseigner `TICKETS_XML_PATH` dans `.env`.
4. Lancer l'analyse: `bundle exec ruby main.rb`.
5. Consulter le fichier `output/visualisation.html`.

### Interpretration des resultats

- **Clusters**: regroupements thematiques des tickets.
- **Topics**: intitules generes automatiquement pour chaque cluster.
- **Similarites**: voisins semantiques (doublons probables).
- **Silhouette/elbow**: indicateurs de qualite du clustering.

### Limites connues

- Qualite des resultats dependante de la qualite des tickets sources.
- Temps de calcul variable selon materiel et volume.
- MVP majoritairement en mode batch (pas encore API REST complete).

## 6.3 Maintenance documentaire

- Toute modification structurelle du pipeline doit mettre a jour:
  - `docs/bts_sio/03_conception.md`
  - `docs/bts_sio/04_realisation.md`
  - `docs/bts_sio/05_tests.md`
