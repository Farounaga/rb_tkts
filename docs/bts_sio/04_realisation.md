# 04 - Realisation

## 4.1 Environnement de developpement

### Stack

- Langage: Ruby >= 3.3.10
- Gestion dependances: Bundler
- Parsing XML: Nokogiri
- Appels HTTP: HTTParty
- ML: Rumale + numo-narray
- Tests: RSpec

### Prerequis locaux

1. Ruby installe.
2. Ollama installe et accessible.
3. Modeles Ollama disponibles:
   - embeddings: `nomic-embed-text-v2-moe`
   - topics: `llama3.2:1b-instruct`

## 4.2 Arborescence utile

- `main.rb` - orchestration du pipeline.
- `config.rb` - chargement des variables d'environnement.
- `xml_handler.rb` - import XML streaming et mapping schema.
- `embedding.rb` - generation embeddings.
- `clusterer.rb` - KMeans + sortie clusters.
- `cluster_topics.rb` - generation de titres de clusters.
- `similarity.rb` - tickets similaires (cosinus).
- `clustering_metrics.rb` - elbow + silhouette.
- `visualisation.rb` - rapport HTML.
- `spec/` - tests unitaires.
- `docs/bts_sio/` - dossier d'examen BTS.

## 4.3 Procedure d'installation

```bash
bundle install
cp .env.example .env
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```

Sous PowerShell:

```powershell
bundle install
Copy-Item .env.example .env
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```

## 4.4 Lien vers depot Git

- Depot local: `E:\Programming\BTS_SIO\rb_tkts`
- Depot distant (a renseigner pour le jury): `<URL_GIT_A_COMPLETER>`

## 4.5 Base de donnees et scripts

Le MVP actuel ecrit surtout des fichiers JSON/HTML.  
Pour repondre au formalisme BTS, un schema SQL de reference est fourni:

- Schema: [`sql/01_schema.sql`](./sql/01_schema.sql)
- Jeu minimal de donnees: [`sql/02_seed_minimal.sql`](./sql/02_seed_minimal.sql)

Ces scripts permettent:
- de presenter une modelisation relationnelle propre,
- d'alimenter une future API REST ou un dashboard persistant.

## 4.6 Sorties de l'application

- `embeddings.json`
- `clusters.json`
- `cluster_topics.json`
- `clustering_metrics.json`
- `similar_tickets.json`
- `output/visualisation.html`

## 4.7 Reproductibilite

- Parametrage central via `.env`.
- KMeans avec seed fixe (`7`) pour stabiliser les resultats.
- Jeu de donnees de demonstration: `sample_data/tickets_demo_50.xml`.
