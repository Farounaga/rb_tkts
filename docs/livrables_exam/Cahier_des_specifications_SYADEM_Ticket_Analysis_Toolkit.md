# Cahier des specifications - SYADEM Ticket Analysis Toolkit

## 1. Presentation

Le projet est un outil Ruby permettant d'analyser un export XML de tickets support. Les resultats sont produits sous forme de fichiers JSON, CSV et HTML.

## 2. Specifications fonctionnelles

| ID | Fonction | Description | Priorite |
|---|---|---|---:|
| SF-01 | Import XML | Charger les tickets depuis un fichier XML local | Must |
| SF-02 | Base XML | Importer ou lire le XML depuis BaseX si active | Should |
| SF-03 | Extraction | Extraire les champs tickets, commentaires et champs personnalises | Must |
| SF-04 | Limite de traitement | Limiter le nombre de tickets avec `MAX_TICKETS` | Should |
| SF-05 | Embeddings | Generer un vecteur semantique pour chaque ticket | Must |
| SF-06 | Troncature texte | Reduire les textes trop longs avant appel modele | Should |
| SF-07 | Clustering | Regrouper les tickets avec KMeans | Must |
| SF-08 | Topics | Generer un titre court par cluster | Should |
| SF-09 | Metriques | Calculer elbow et silhouette | Should |
| SF-10 | Similarite | Produire le top-k des tickets les plus proches | Should |
| SF-11 | CSV | Exporter un fichier tabulaire pour utilisateurs metier | Must |
| SF-12 | HTML | Generer un rapport consultable dans un navigateur | Must |
| SF-13 | Frontend Docker | Exposer HTML et CSV via Nginx | Should |

## 3. Specifications non fonctionnelles

| ID | Exigence | Specification |
|---|---|---|
| SNF-01 | Confidentialite | Utiliser Ollama localement pour eviter l'envoi de donnees sensibles vers le cloud |
| SNF-02 | Performance memoire | Lire le XML en streaming |
| SNF-03 | Configuration | Centraliser les parametres dans `.env` et `config.rb` |
| SNF-04 | Robustesse | Continuer en mode degrade si Ollama est indisponible |
| SNF-05 | Reproductibilite | Fournir Docker Compose |
| SNF-06 | Maintenabilite | Separer les responsabilites par module Ruby |
| SNF-07 | Testabilite | Couvrir les modules critiques avec RSpec |

## 4. User stories

| ID | User story | Critere d'acceptation |
|---|---|---|
| US-01 | En tant qu'analyste support, je veux importer un export XML pour analyser un lot de tickets. | Le pipeline lit le fichier et affiche le nombre de tickets importes. |
| US-02 | En tant que responsable support, je veux visualiser les themes principaux. | `clusters.json` et `cluster_topics.json` sont produits. |
| US-03 | En tant que developpeur, je veux detecter les doublons probables. | `similar_tickets.json` marque `probable_duplicate`. |
| US-04 | En tant qu'utilisateur non technique, je veux un CSV lisible. | `tickets_summary.csv` contient les colonnes metier. |
| US-05 | En tant qu'administrateur, je veux un deploiement simple. | `docker compose up --build` lance les services. |

## 5. Regles de gestion

| ID | Regle |
|---|---|
| RG-01 | Les tickets sans `nice_id` ne sont pas envoyes dans la file d'embeddings. |
| RG-02 | Le texte d'embedding est la concatenation sujet + description + commentaires. |
| RG-03 | Le CSV ne stocke pas les vecteurs complets, seulement leur dimension. |
| RG-04 | Le seuil de doublon probable est configurable avec `SIMILARITY_THRESHOLD`. |
| RG-05 | Le choix de KMeans est controle par `KMEANS_K`, borne au nombre de vecteurs. |
| RG-06 | BaseX est optionnel; en cas d'echec, le fichier local est utilise. |

## 6. Entrees et sorties

| Type | Element |
|---|---|
| Entree principale | `tickets.xml` ou `sample_data/tickets_demo_50.xml` |
| Entree configuration | `.env`, `.env.example` |
| Sorties JSON | `embeddings.json`, `clusters.json`, `cluster_topics.json`, `clustering_metrics.json`, `similar_tickets.json` |
| Sorties utilisateur | `output/visualisation.html`, `output/tickets_summary.csv` |

## 7. Criteres d'acceptation globaux

- Installation des dependances avec `bundle install`.
- Diagnostic possible avec `bundle exec ruby bin/check_env.rb`.
- Tests RSpec executables.
- Rapport HTML et CSV generes.
- Documentation en francais fournie.

