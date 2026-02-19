# SYADEM Ticket Analysis Toolkit

Outil d’analyse des tickets de support (MesVaccins / Colibri) :
- import et structuration des tickets XML,
- génération d’embeddings via Ollama en local,
- clustering thématique,
- génération de sujets de clusters,
- rapport HTML avec statistiques.

## État actuel

Le projet couvre déjà les briques principales d’un MVP :
1. Import XML des tickets.
2. Vectorisation des textes (embeddings).
3. Clustering KMeans.
4. Dashboard HTML de base.

Pour un niveau « diplôme + livraison employeur », il faut encore renforcer l’architecture, la qualité des données, la reproductibilité et la sécurité.

## Ce qu’il faut faire pour passer en mode production

Plan détaillé : [`docs/production_checklist.md`](docs/production_checklist.md).

Priorités principales :
- **P0 (obligatoire)** :
  - externaliser chemins/tokens/modèles dans la config (ENV/YAML),
  - supprimer tout secret du code,
  - ajouter lockfile + commandes de lancement,
  - formaliser le pipeline (extract → clean → embed → cluster → report).
- **P1 (important)** :
  - ajouter une vraie couche de normalisation du texte (HTML, signatures/disclaimers, auto-réponses),
  - ajouter la recherche de tickets similaires (cosinus + top-k),
  - ajouter tests unitaires + smoke tests.
- **P2 (souhaitable)** :
  - détection d’anomalies et rapports mensuels automatiques,
  - couche API (FastAPI/Rack) pour le dashboard futur.

## Prérequis minimaux

- Ruby >= 3.3.10 (voir `Gemfile`)
- Ollama (local) — si vous ne connaissez pas: https://ollama.com/
- Modèles :
  - embeddings : `mxbai-embed-large` (ou `bge-m3` en compatibilité)
  - résumé : `llama3:instruct`

## Sécurité

- Ne stockez jamais de token API dans le code ni dans git.
- Utilisez `.env` (voir `.env.example`).

## Comprendre le fonctionnement du code

- Schéma d'exécution et dépendances: [`docs/code_flow.md`](docs/code_flow.md)

## Structure actuelle

- `xml_handler.rb` — parsing XML streaming + schéma configurable (mapping de champs/collections).
- `embedding.rb` — génération des embeddings.
- `clusterer.rb` — clustering KMeans.
- `cluster_topics.rb` — thèmes LLM par cluster.
- `visualisation.rb` — génération du rapport HTML.
- `calculs.rb` — API Zendesk + agrégations de tags.

## Valeur pour le métier

- Réduction du temps d’analyse manuelle.
- Détection plus rapide des problèmes récurrents et pics d’activité.
- Meilleure priorisation pour les équipes support et développement.

## IA locale (point clé du projet)

Le projet s'appuie sur **deux modèles locaux Ollama** :
- **Modèle d'embeddings** (`OLLAMA_EMBED_MODEL`, recommandé: `mxbai-embed-large`) pour la vectorisation sémantique des tickets.
- **Modèle LLM de topics** (`OLLAMA_LLM_MODEL`, recommandé: `llama3:instruct`) pour générer des titres de clusters compréhensibles par les équipes métier.

Cette séparation est volontaire :
- modèle A = précision des similarités/clustering,
- modèle B = lisibilité et interprétation métier des thèmes.

## Exécution rapide

1. Copier `.env.example` en `.env` et renseigner les variables nécessaires.
2. Lancer : `bundle exec ruby main.rb`

Le chargement XML est fait en **streaming** (Reader Nokogiri), donc le fichier complet n'est plus chargé d'un coup en mémoire.
Le parser est aussi **piloté par schéma** (mapping Ruby), ce qui facilite l'adaptation à d'autres structures XML.

Le bootstrap Ollama automatique s’active **uniquement** si :
- `OLLAMA_AUTO_START=true`
- et `OLLAMA_BASE_URL` pointe vers un host local (`localhost`, `127.0.0.1`, `::1`)
- et au moins une étape Ollama est active (`RUN_EMBEDDINGS=true` ou `RUN_CLUSTERING=true`).

Comportement des modèles :
- Si `OLLAMA_MODELS` est défini, cette liste est utilisée pour les `ollama pull` automatiques.
- Sinon, le code utilise `OLLAMA_EMBED_MODEL` et/ou `OLLAMA_LLM_MODEL` selon les étapes activées.

Arrêt automatique en fin de run :
- Si le script a lui-même lancé `ollama serve`, il l'arrête à la fin (`OLLAMA_AUTO_STOP=true`).
- Si Ollama tournait déjà avant le run, le script ne l'arrête pas.

Variables utiles :
- `OLLAMA_AUTO_START=true|false` (défaut : `true`)
- `OLLAMA_MODELS=model1,model2` (optionnel)
- `OLLAMA_START_TIMEOUT=30`
- `OLLAMA_AUTO_STOP=true|false` (défaut : `true`)
- `OLLAMA_STOP_TIMEOUT=10`
- `RUN_EMBEDDINGS=true|false`
- `RUN_CLUSTERING=true|false`
- `EMBEDDING_THREADS=4`
- `MAX_TICKETS=300` (optionnel, limite la lecture XML dès le parsing streaming, utile pour gros exports)
- `OLLAMA_READ_TIMEOUT=180`
- `OLLAMA_OPEN_TIMEOUT=5`
- `OLLAMA_RETRY_BASE_DELAY=0.5`
- `TOPIC_OPEN_TIMEOUT=5`
- `TOPIC_READ_TIMEOUT=180`
- `TOPIC_MAX_RETRIES=3`
- `TOPIC_RETRY_BASE_DELAY=0.5`


## Qualité de clustering et similarité

Le MVP inclut désormais des sorties mesurables :
- `clustering_metrics.json` :
  - courbe elbow (inertie selon `k`),
  - score silhouette pour `KMEANS_K`.
- `similar_tickets.json` : top-k tickets les plus proches par similarité cosinus,
  avec marquage `probable_duplicate` au-dessus d'un seuil configurable.

Variables associées (ENV) :
- `RUN_CLUSTERING_METRICS=true|false`
- `RUN_SIMILARITY=true|false`
- `SIMILARITY_TOP_K` (défaut 5)
- `SIMILARITY_THRESHOLD` (défaut 0.80)


Explication pédagogique des métriques : `docs/metrics_expliquees.md`.


## Installation (Windows / macOS / Linux)

1. Installer Ruby (>= 3.3.10).  
2. Installer Bundler si nécessaire :
   ```bash
   gem install bundler
   ```
3. Installer les dépendances du projet :
   ```bash
   bundle install
   ```
4. Copier le fichier d'environnement :
   ```bash
   cp .env.example .env
   ```
   Sous PowerShell :
   ```powershell
   Copy-Item .env.example .env
   ```
5. Optionnel (si vous désactivez l'autostart ou si vous utilisez un serveur Ollama distant) : vérifier Ollama + modèles :
   ```bash
   ollama pull mxbai-embed-large
   ollama pull llama3:instruct
   ollama serve
   ```
6. Lancer le projet :
   ```bash
   bundle exec ruby main.rb
   ```

Optionnel (diagnostic rapide):
```bash
bundle exec ruby bin/check_env.rb
```

### Erreur fréquente : `cannot load such file -- httparty`

Cette erreur signifie que les gems Ruby ne sont pas installées dans l'environnement courant.
Résolution :
```bash
gem install bundler
bundle install
bundle exec ruby main.rb
```

### Note Windows Ruby 3.4

Le projet utilise des dépendances natives pour la partie ML (`numo-narray`, `rumale`).
Si `bundle install` échoue sur Windows, vérifiez d'abord les toolchains Ruby/MSYS2,
l'accès réseau à rubygems.org, puis relancez:

```powershell
bundle config set force_ruby_platform true
bundle install
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```
