# 09 - Guide d'utilisation (local + Docker)

## Objectif

Ce guide explique comment utiliser le projet de bout en bout:
- execution locale,
- execution Docker 3 services (app + BaseX + Ollama),
- verification des sorties,
- diagnostic des erreurs frequentes.

## 1) Architecture d'execution

Le pipeline principal:
1. lecture XML des tickets,
2. embeddings,
3. clustering,
4. metriques,
5. similarite,
6. export CSV,
7. rapport HTML.

En mode Docker:
- `app` lit les tickets via `xml-db` (BaseX REST),
- `app` appelle `ollama` pour embeddings/topics,
- `app` ecrit les livrables dans `output/`.

## 2) Prerequis

## 2.1 Local

- Ruby >= 3.3
- Bundler
- Ollama (si execution hors Docker)

## 2.2 Docker

- Docker Desktop ou Docker Engine
- Docker Compose v2

## 3) Configuration (.env)

Copie de base:

```bash
cp .env.example .env
```

Variables importantes:
- `TICKETS_XML_PATH`
- `RUN_EMBEDDINGS`
- `RUN_CLUSTERING`
- `RUN_CLUSTER_TOPICS`
- `RUN_CLUSTERING_METRICS`
- `RUN_SIMILARITY`
- `RUN_EXPORT_CSV`
- `CSV_EXPORT_OUTPUT`
- `EMBEDDING_MAX_CHARS`
- `SKIP_OLLAMA_ON_ERROR`

Variables base XML (optionnelles hors Docker):
- `XML_DB_ENABLED`
- `XML_DB_BASE_URL`
- `XML_DB_USER`
- `XML_DB_PASSWORD`
- `XML_DB_DATABASE`
- `XML_DB_RESOURCE`
- `XML_DB_IMPORT_ON_START`

## 4) Execution locale

## 4.1 Installation

```bash
bundle install
```

## 4.2 Lancement

```bash
bundle exec ruby main.rb
```

## 4.3 Verification rapide

Fichiers attendus:
- `output/visualisation.html`
- `output/tickets_summary.csv`

Selon les flags:
- `embeddings.json`
- `clusters.json`
- `cluster_topics.json`
- `clustering_metrics.json`
- `similar_tickets.json`

## 5) Execution Docker (3 conteneurs)

## 5.1 Lancement complet

```bash
docker compose up --build
```

Services demarres:
- `xml-db` (BaseX sur `localhost:8984`)
- `ollama` (API sur `localhost:11434`)
- `app` (pipeline Ruby)

## 5.2 Arret

```bash
docker compose down
```

## 5.3 Rebuild force

```bash
docker compose build --no-cache app
docker compose up
```

## 6) Utilisation de la base NoSQL XML (BaseX)

Le service `app` utilise:
- `XML_DB_BASE_URL=http://xml-db:8984`
- endpoint REST: `/rest/<database>/<resource>`

Exemple d'acces depuis la machine host:

```bash
curl -u admin:admin http://localhost:8984/rest/ticketsdb/tickets.xml
```

Si la ressource n'existe pas encore:
- `app` peut importer le XML local automatiquement si `XML_DB_IMPORT_ON_START=true`.

## 7) Utilisation d'Ollama en conteneur

Dans `docker-compose.yml`, `ollama`:
- demarre le serveur,
- pull automatiquement les modeles definis (`OLLAMA_EMBED_MODEL`, `OLLAMA_LLM_MODEL`).

Verification modele:

```bash
docker compose exec ollama ollama list
```

## 8) Tests

Execution de la suite:

```bash
bundle exec rspec
```

Execution verbeuse:

```bash
bundle exec rspec --format documentation
```

## 9) Erreurs frequentes et solutions

## 9.1 `input length exceeds the context length`

Cause:
- ticket trop long pour le contexte embedding.

Solution:
- reduire `EMBEDDING_MAX_CHARS` (ex: `8000`, puis `6000`).

## 9.2 WSL + Ollama sur Windows (`Errno::ENOENT`)

Cause:
- binaire `ollama` absent dans WSL.

Solution:

```env
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_AUTO_START=false
SKIP_OLLAMA_ON_ERROR=true
```

## 9.3 `Bundler::GemNotFound`

Solution:

```bash
bundle install
bundle exec rspec
```

## 9.4 Base XML indisponible

Comportement:
- fallback automatique vers fichier XML local.

A verifier:
- `XML_DB_ENABLED`
- `XML_DB_BASE_URL`
- credentials BaseX.

## 10) Scenario demo (soutenance)

1. Montrer la stack Docker:

```bash
docker compose up --build
```

2. Montrer les logs applicatifs:

```bash
docker compose logs -f app
```

3. Ouvrir les livrables:
- `output/tickets_summary.csv`
- `output/visualisation.html`

4. Lancer les tests:

```bash
bundle exec rspec
```

5. Expliquer les preuves de qualite:
- cas connus mathematiques,
- cas limites,
- mode degrade Ollama,
- export CSV metier configurable.
