# Documentation BTS SIO SLAM - SYADEM Ticket Analysis Toolkit

Ce dossier regroupe la documentation d'examen du projet **SYADEM Ticket Analysis Toolkit** (`rb_tkts`).

Le projet est un pipeline Ruby d'analyse de tickets support MesVaccins / Colibri. Il importe des tickets XML, produit des embeddings via Ollama en local, regroupe les tickets par themes avec KMeans, calcule des metriques de qualite, detecte des tickets similaires, exporte un CSV metier et genere un rapport HTML servi par un frontend Nginx.

## Structure

| Dossier | Contenu |
|---|---|
| `01_contexte` | Contexte, expression des besoins, cahier des charges, backlog |
| `02_analyse` | Cas d'utilisation, regles metier, choix technologiques |
| `03_conception` | MCD, MLD, classes, sequences, maquette, architecture |
| `04_realisation` | Environnement de developpement, depot Git, scripts BDD, Docker |
| `05_tests` | Plan de tests, tests unitaires, rapport de tests |
| `06_documentation` | Documentation technique, installation, deploiement, guide utilisateur |
| `07_bilan` | Bilan, competences BTS SIO SLAM, axes d'amelioration |
| `livrables_exam` | Fichiers separes au format livrables d'examen et versions Word |

## Sources verifiees dans le depot

- `README.md`
- `Gemfile` / `Gemfile.lock`
- `.env.example`
- `main.rb`
- `config.rb`
- `xml_handler.rb`
- `xml_db_client.rb`
- `embedding.rb`
- `clusterer.rb`
- `cluster_topics.rb`
- `ml_utils.rb`
- `clustering_metrics.rb`
- `similarity.rb`
- `export_csv.rb`
- `visualisation.rb`
- `ollama_bootstrap.rb`
- `docker-compose.yml`, `Dockerfile`, `docker/frontend/*`
- `spec/*`
- `docs/bts_sio/*`
- `docs/code_flow.md`

## Depot Git

Depot distant configure dans le projet:

```text
https://github.com/Farounaga/rb_tkts
```

