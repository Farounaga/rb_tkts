# Suivi de projet Trello - SYADEM Ticket Analysis Toolkit

## Objectif du suivi

Ce document presente un suivi de projet sous forme de tableau Kanban inspire de Trello. Il permet de montrer l'organisation du travail, les priorites et l'avancement du MVP pour l'epreuve BTS SIO SLAM.

## Tableau Kanban

| Colonne | Cartes |
|---|---|
| Idee / Backlog | API REST de consultation, dashboard interactif, anonymisation automatique, CI/CD GitHub Actions, persistance SQL |
| A faire | Finaliser documentation examen, verifier rendu Word, relancer tests RSpec avant soutenance |
| En cours | Consolidation des livrables `docs/` et `docs/livrables_exam/` |
| Termine | Parsing XML streaming, configuration `.env`, embeddings Ollama, KMeans, topics LLM, similarite cosinus, export CSV, rapport HTML, Docker Compose, tests unitaires |
| Bloque / Risques | Performance Ollama selon machine, qualite variable des tickets, absence d'API REST actuelle |

## Backlog detaille

| ID | Tache | Priorite | Statut | Preuve dans le depot |
|---|---|---:|---|---|
| T-01 | Creer le parsing XML des tickets | Must | Termine | `xml_handler.rb`, `spec/xml_handler_spec.rb` |
| T-02 | Centraliser la configuration | Must | Termine | `config.rb`, `.env.example` |
| T-03 | Ajouter les embeddings locaux | Must | Termine | `embedding.rb` |
| T-04 | Ajouter le bootstrap Ollama | Should | Termine | `ollama_bootstrap.rb`, specs associees |
| T-05 | Implementer KMeans | Must | Termine | `ml_utils.rb`, `clusterer.rb` |
| T-06 | Ajouter les titres de clusters | Should | Termine | `cluster_topics.rb` |
| T-07 | Ajouter la similarite cosinus | Should | Termine | `similarity.rb` |
| T-08 | Ajouter les metriques elbow/silhouette | Should | Termine | `clustering_metrics.rb` |
| T-09 | Exporter un CSV metier | Should | Termine | `export_csv.rb`, `output/tickets_summary.csv` |
| T-10 | Generer le rapport HTML | Must | Termine | `visualisation.rb`, `output/visualisation.html` |
| T-11 | Ajouter Docker Compose | Should | Termine | `docker-compose.yml`, `Dockerfile` |
| T-12 | Ajouter BaseX XML DB | Could | Termine | `xml_db_client.rb`, service `xml-db` |
| T-13 | Ajouter une API REST | Could | A planifier | Evolution cible documentee |
| T-14 | Ajouter CI GitHub Actions | Could | A planifier | Non present dans le depot |

## Jalons

| Jalon | Objectif | Livrables |
|---|---|---|
| J1 - Analyse | Comprendre les tickets et les besoins support | User stories, regles metier |
| J2 - MVP pipeline | Produire une analyse locale exploitable | JSON, CSV, HTML |
| J3 - Qualite | Securiser les calculs et les cas limites | Specs RSpec |
| J4 - Deploiement | Rendre l'execution reproductible | Dockerfile, Docker Compose |
| J5 - Dossier examen | Formaliser le projet BTS SIO SLAM | Documentation 01 a 07 et livrables Word |

## Risques et actions

| Risque | Impact | Action de maitrise |
|---|---|---|
| Ollama non disponible | Embeddings/topics impossibles | `SKIP_OLLAMA_ON_ERROR=true`, mode degrade |
| XML volumineux | Memoire saturee | Parsing streaming avec Nokogiri Reader |
| Clustering peu lisible | Mauvaise interpretation metier | Topics LLM courts + metriques elbow/silhouette |
| Donnees sensibles | Risque de fuite | Execution locale et anonymisation conseillee |
| Environnement non reproductible | Demo instable | Docker Compose et `.env.example` |

