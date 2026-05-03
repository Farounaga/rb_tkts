# 01 - Contexte

## Presentation du projet

**SYADEM Ticket Analysis Toolkit** est un outil d'analyse des tickets de support issus de MesVaccins / Colibri. Le projet se presente comme un pipeline Ruby executable localement ou dans Docker.

Objectif principal: transformer un export XML volumineux de tickets en livrables exploitables par les equipes support et techniques:

- rapport HTML de visualisation;
- export CSV pour Excel ou LibreOffice;
- regroupement des tickets par themes;
- detection des tickets proches ou doublons probables;
- indicateurs de qualite du clustering.

## Probleme a resoudre

Les tickets de support contiennent beaucoup d'information textuelle: sujets, descriptions, commentaires, tags et champs metier. Une analyse manuelle est longue, peu reproductible et difficile a presenter aux equipes produit ou developpement.

Le projet repond donc a la question suivante:

> Comment produire rapidement une synthese fiable et locale des tickets support, sans envoyer de donnees sensibles vers un service cloud externe?

## Expression des besoins

| Acteur | Besoin |
|---|---|
| Analyste support | Importer un fichier XML et obtenir une vision globale des tickets |
| Responsable support | Identifier les themes recurrents, les pics d'activite et les doublons |
| Equipe developpement | Retrouver les causes racines et prioriser les corrections |
| Equipe produit | Comprendre les problemes frequents cote utilisateur |
| Jury BTS SIO | Evaluer une demarche complete: analyse, conception, realisation, tests, documentation |

## Cahier des charges synthetique

### Exigences fonctionnelles

| ID | Exigence | Statut dans le code |
|---|---|---|
| F01 | Charger un export XML de tickets | Realise avec `xml_handler.rb` |
| F02 | Lire le XML en streaming pour limiter la memoire | Realise avec `Nokogiri::XML::Reader` |
| F03 | Extraire les champs utiles des tickets, commentaires et champs personnalises | Realise avec schemas de mapping Ruby |
| F04 | Generer des embeddings localement | Realise avec `embedding.rb` et l'API Ollama `/api/embeddings` |
| F05 | Regrouper les tickets par similarite semantique | Realise avec KMeans dans `ml_utils.rb` et `clusterer.rb` |
| F06 | Generer un titre lisible par cluster | Realise avec `cluster_topics.rb` et Ollama `/api/generate` |
| F07 | Calculer des metriques de clustering | Realise avec elbow et silhouette dans `clustering_metrics.rb` |
| F08 | Detecter les tickets similaires | Realise avec similarite cosinus dans `similarity.rb` |
| F09 | Exporter un CSV metier | Realise avec `export_csv.rb` |
| F10 | Generer un rapport HTML | Realise avec `visualisation.rb` |
| F11 | Servir les livrables via un frontend | Realise avec Nginx dans `docker/frontend` |
| F12 | Stocker ou relire le XML via une base XML | Realise en option avec BaseX REST dans `xml_db_client.rb` |

### Exigences non fonctionnelles

| Exigence | Reponse du projet |
|---|---|
| Confidentialite | IA locale via Ollama, pas d'appel LLM cloud obligatoire |
| Reproductibilite | Configuration centralisee par `.env` et seed KMeans fixe |
| Maintenabilite | Modules Ruby separes par responsabilite |
| Robustesse | Mode degrade si Ollama est indisponible (`SKIP_OLLAMA_ON_ERROR=true`) |
| Testabilite | Tests RSpec sur configuration, XML, ML, export, BaseX et bootstrap Ollama |
| Deployabilite | Docker Compose avec `frontend`, `app-llm`, `xml-db` |

## User stories et backlog

| ID | User story | Priorite | Critere d'acceptation | Statut |
|---|---|---:|---|---|
| US-01 | En tant qu'analyste support, je veux importer un XML de tickets afin d'eviter une saisie manuelle. | Must | Le pipeline charge les tickets depuis `TICKETS_XML_PATH`. | Realise |
| US-02 | En tant qu'analyste, je veux limiter le nombre de tickets pour tester rapidement. | Should | `MAX_TICKETS` arrete le parsing apres la limite. | Realise |
| US-03 | En tant que responsable support, je veux obtenir des groupes thematiques de tickets. | Must | `clusters.json` associe chaque `nice_id` a un cluster. | Realise |
| US-04 | En tant que responsable support, je veux des titres de clusters comprehensibles. | Should | `cluster_topics.json` contient un titre court par cluster. | Realise |
| US-05 | En tant que developpeur, je veux reperer les tickets similaires. | Should | `similar_tickets.json` contient un top-k et un indicateur `probable_duplicate`. | Realise |
| US-06 | En tant que chef de projet, je veux justifier la qualite du clustering. | Should | `clustering_metrics.json` contient elbow et silhouette. | Realise |
| US-07 | En tant qu'utilisateur non technique, je veux ouvrir un rapport HTML. | Must | `output/visualisation.html` est genere et servi par Nginx en Docker. | Realise |
| US-08 | En tant qu'utilisateur metier, je veux manipuler les resultats dans un tableur. | Should | `output/tickets_summary.csv` est genere avec separateur `;`. | Realise |
| US-09 | En tant qu'administrateur, je veux executer le projet avec trois services Docker. | Should | `docker compose up --build` lance frontend, app-llm et BaseX. | Realise |
| US-10 | En tant qu'equipe produit, je veux filtrer les tickets dans une future interface interactive. | Could | API REST de consultation documentee comme evolution. | A planifier |

## Contraintes

- Donnees de support potentiellement sensibles.
- Execution de modeles IA dependante de la machine locale.
- Fichier XML volumineux (`tickets.xml` present dans le depot).
- Necessite de rendre le projet presentable pour l'epreuve BTS SIO SLAM.
- Pas d'API REST metier exposee actuellement: le pipeline produit des fichiers statiques et JSON.

