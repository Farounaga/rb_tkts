# 05 - Tests

## Strategie de tests

Le projet utilise **RSpec** pour tester les modules critiques du pipeline Ruby. Les tests ciblent principalement les fonctions pures, la configuration, le parsing XML, les calculs ML et les exports.

Commande principale:

```bash
bundle exec rspec
```

## Plan de tests

| ID | Module | Objectif | Type | Statut attendu |
|---|---|---|---|---|
| T01 | `xml_handler.rb` | Verifier l'extraction des champs et collections imbriquees | Unitaire | OK |
| T02 | `xml_handler.rb` | Verifier l'arret avec `max_tickets` | Unitaire | OK |
| T03 | `config.rb` | Verifier la lecture des flags booleens | Unitaire | OK |
| T04 | `config.rb` | Verifier les valeurs par defaut Ollama et XML DB | Unitaire | OK |
| T05 | `ml_utils.rb` | Verifier cosinus, distance euclidienne, normalisation | Unitaire | OK |
| T06 | `ml_utils.rb` | Verifier le cas limite `k > nombre de points` | Unitaire | OK |
| T07 | `clustering_metrics.rb` | Verifier la sortie elbow/silhouette | Unitaire | OK |
| T08 | `similarity.rb` | Verifier le calcul de tickets similaires | Unitaire | OK |
| T09 | `export_csv.rb` | Verifier les colonnes et donnees du CSV | Unitaire | OK |
| T10 | `xml_db_client.rb` | Verifier le fallback fichier local et le cache BaseX | Unitaire avec doubles | OK |
| T11 | `ollama_bootstrap.rb` | Verifier les modeles requis et le comportement bootstrap | Unitaire | OK |
| T12 | `cluster_topics.rb` | Verifier le nettoyage des titres LLM | Unitaire | OK |

## Tests unitaires presents

Fichiers de tests observes:

- `spec/cluster_topics_format_spec.rb`
- `spec/cluster_topics_spec.rb`
- `spec/clustering_metrics_spec.rb`
- `spec/config_spec.rb`
- `spec/embedding_spec.rb`
- `spec/export_csv_spec.rb`
- `spec/ml_utils_spec.rb`
- `spec/ollama_bootstrap_spec.rb`
- `spec/xml_db_client_spec.rb`
- `spec/xml_handler_spec.rb`
- `spec/xml_schema_custom_spec.rb`

## Rapport de tests

Un rapport precedent existe dans `docs/bts_sio/rapports/rapport_tests.md`:

| Date | Commande | Resultat |
|---|---|---|
| 2026-04-10 10:07:00 +02:00 | `bundle exec rspec` | 25 tests, 0 echec |

La documentation courante doit etre accompagnee d'une nouvelle execution avant soutenance.

## Tests fonctionnels manuels

| Scenario | Etapes | Resultat attendu |
|---|---|---|
| Execution demo courte | Configurer `TICKETS_XML_PATH=sample_data/tickets_demo_50.xml`, `MAX_TICKETS=50`, lancer `bundle exec ruby main.rb` | Generation des fichiers de sortie |
| Mode sans Ollama | Mettre `RUN_EMBEDDINGS=false` et `RUN_CLUSTER_TOPICS=false` | Le pipeline ne bloque pas sur Ollama |
| Mode degrade Ollama | Laisser Ollama indisponible avec `SKIP_OLLAMA_ON_ERROR=true` | Les etapes IA sont sautees sans interrompre tout le run |
| Docker Compose | Lancer `docker compose up --build` | Frontend accessible sur `localhost:8080` |
| Base XML | Activer `XML_DB_ENABLED=true` dans Docker | Import/lecture du XML via BaseX avec fallback local |

## Couverture des risques

| Risque | Test ou controle associe |
|---|---|
| Fichier XML trop gros | Parsing streaming + test `max_tickets` |
| Donnees textuelles longues | Troncature dans `prepare_text_for_embedding` |
| Vecteur nul | Test cosinus retourne `0.0` |
| Nombre de clusters invalide | Test `k > n` leve une erreur dans `MlUtils`, bornage dans `clusterer.rb` |
| Fichiers analytiques manquants | Fallback dans `export_csv.rb` |
| Ollama indisponible | Mode degrade et tests de bootstrap |

