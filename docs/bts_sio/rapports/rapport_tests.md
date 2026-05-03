# Rapport de tests

## Contexte

Ce rapport synthese les executions de tests du projet pour les jalons BTS SIO.

## Campagne actuelle

- Date: 2026-04-10 10:07:00 +02:00
- Environnement: local
- Commande principale: `bundle exec rspec`

## Resultat

- Statut: OK
- Nombre de tests: 25
- Echecs: 0
- Remarques:
  - Ajout des specs unitaires `ml_utils_spec.rb`, `clustering_metrics_spec.rb`, `export_csv_spec.rb`.
  - Verification des cas limites de robustesse (vecteur nul, `k > n`).
  - Validation de l'export CSV et des nouveaux flags de configuration.

## Actions

1. Relancer `bundle exec rspec` avant chaque demo/soutenance.
2. Garder `RUN_EXPORT_CSV=true` pour produire le livrable non technique.
3. En cas de WSL + Ollama Windows, utiliser `OLLAMA_AUTO_START=false` et `SKIP_OLLAMA_ON_ERROR=true`.
