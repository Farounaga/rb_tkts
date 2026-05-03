# SYADEM Ticket Analysis Toolkit

Outil d’analyse des tickets de support (MesVaccins / Colibri) :
- import et structuration des tickets XML,
- génération d’embeddings via Ollama en local,
- clustering thématique,
- génération de sujets de clusters,
- rapport HTML avec statistiques.

## Dossier BTS SIO (documentation complète)

Le README reste un point d'entrée technique.  
La documentation d'examen structurée (01 à 07) est disponible ici :

- [`docs/bts_sio/README.md`](docs/bts_sio/README.md)
- Guide d'utilisation direct: [`docs/bts_sio/09_guide_utilisation.md`](docs/bts_sio/09_guide_utilisation.md)

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
  - embeddings : `nomic-embed-text-v2-moe`
  - résumé (rapide/recommandé) : `llama3.2:1b-instruct`

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
- `export_csv.rb` — export CSV récapitulatif pour usage non technique.
- `visualisation.rb` — génération du rapport HTML.
- `calculs.rb` — API Zendesk + agrégations de tags.

## Mises à jour réalisées (examens BTS)

- Renforcement des tests unitaires sur les modules de calcul/analyse (`MlUtils`, métriques de clustering).
- Ajout de cas limites de robustesse (vecteur nul, `k` invalide).
- Suppression de code redondant/obsolète dans `clusterer.rb` (refactoring incomplet nettoyé).
- Harmonisation de la configuration via helpers (`fetch_bool`, `fetch_int`, `fetch_float`) dans `config.rb`.
- Ajout d’un export CSV complet (`output/tickets_summary.csv`) intégré au pipeline.
- Ajout d’un mode dégradé: si Ollama est indisponible, les étapes dépendantes sont skipées sans casser tout le run (`SKIP_OLLAMA_ON_ERROR=true`).

## Valeur pour le métier

- Réduction du temps d’analyse manuelle.
- Détection plus rapide des problèmes récurrents et pics d’activité.
- Meilleure priorisation pour les équipes support et développement.

## IA locale (point clé du projet)

Le projet s'appuie sur **deux modèles locaux Ollama** :
- **Modèle d'embeddings** (`OLLAMA_EMBED_MODEL`, recommandé: `nomic-embed-text-v2-moe`) pour la vectorisation sémantique des tickets.
- **Modèle LLM de topics** (`OLLAMA_LLM_MODEL`, recommandé: `llama3.2:1b-instruct`) pour générer des titres de clusters compréhensibles par les équipes métier.

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
- `SKIP_OLLAMA_ON_ERROR=true|false` (défaut : `true`)
- `XML_DB_ENABLED=true|false` (défaut : `false`)
- `XML_DB_BASE_URL=http://xml-db:8984`
- `XML_DB_DATABASE=ticketsdb`
- `XML_DB_RESOURCE=tickets.xml`
- `XML_DB_IMPORT_ON_START=true|false`
- `RUN_EMBEDDINGS=true|false`
- `RUN_CLUSTERING=true|false`
- `RUN_CLUSTER_TOPICS=true|false` (désactive uniquement la génération LLM des titres de clusters)
- `EMBEDDING_THREADS=4`
- `EMBEDDING_MAX_CHARS=12000` (tronque les tickets trop longs avant embeddings)
- `MAX_TICKETS=300` (optionnel, limite la lecture XML dès le parsing streaming, utile pour gros exports)
- `OLLAMA_READ_TIMEOUT=180`
- `OLLAMA_OPEN_TIMEOUT=5`
- `OLLAMA_RETRY_BASE_DELAY=0.5`
- `TOPIC_OPEN_TIMEOUT=5`
- `TOPIC_READ_TIMEOUT=180`
- `TOPIC_MAX_RETRIES=3`
- `TOPIC_RETRY_BASE_DELAY=0.5`
- `TOPIC_NUM_PREDICT=32`
- `TOPIC_TEMPERATURE=0.2`
- `RUN_EXPORT_CSV=true|false` (défaut : `true`)
- `CSV_EXPORT_OUTPUT=output/tickets_summary.csv`

Si vous voyez l'erreur Ollama `input length exceeds the context length`,
baissez `EMBEDDING_MAX_CHARS` (ex: `8000` ou `6000`) puis relancez.


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
- `RUN_EXPORT_CSV=true|false`
- `CSV_EXPORT_OUTPUT=output/tickets_summary.csv`


Explication pédagogique des métriques : `docs/metrics_expliquees.md`.


## Comment est choisi le nombre de clusters (K)

Actuellement, le clustering utilise une valeur **fixe** `KMEANS_K` (ENV), donc ce n'est pas auto-ajusté dans `run_clustering`.

Pourquoi pas automatique par défaut :
- stabilité des résultats d'un run à l'autre (plus simple pour comparer),
- contrôle métier (certaines équipes veulent un nombre de thèmes cible),
- éviter qu'un choix auto change fortement selon l'échantillon.

Le projet calcule quand même des indicateurs d'aide (`clustering_metrics.json`) :
- courbe elbow (inertie selon k),
- silhouette pour le `KMEANS_K` choisi.

Workflow conseillé :
1. Lancer avec `RUN_CLUSTERING_METRICS=true`.
2. Regarder la courbe elbow + silhouette.
3. Ajuster `KMEANS_K` dans `.env` puis relancer.


### Modèles recommandés (rapides)

Pour la génération de titres de clusters, éviter les modèles de raisonnement type `deepseek-r1` (souvent plus lents et parfois verbeux, ex: sortie `<think>`).

Recommandations pratiques :
- `OLLAMA_LLM_MODEL=llama3.2:1b-instruct` (très rapide, idéal 4GB VRAM)
- `OLLAMA_LLM_MODEL=qwen2.5:3b-instruct` (souvent rapide et propre pour titres courts)
- `OLLAMA_EMBED_MODEL=nomic-embed-text-v2-moe` (rapide et adapté machines modestes)

Réglages conseillés pour accélérer les topics :
- `TOPIC_NUM_PREDICT=32`
- `TOPIC_TEMPERATURE=0.2`
- augmenter `TOPIC_READ_TIMEOUT` si machine lente (ex: 240)




### Mode statistiques sans LLM

Pour parser le XML et produire les sorties analytiques sans appel LLM:
- `RUN_EMBEDDINGS=false` (si `embeddings.json` existe déjà),
- `RUN_CLUSTER_TOPICS=false` (pas de génération de titres via LLM),
- garder `RUN_CLUSTERING_METRICS=true` / `RUN_SIMILARITY=true` selon besoin.

Exemple minimal:
```env
RUN_EMBEDDINGS=false
RUN_CLUSTERING=true
RUN_CLUSTER_TOPICS=false
RUN_CLUSTERING_METRICS=true
RUN_SIMILARITY=true
RUN_EXPORT_CSV=true
```

### Cas WSL + Ollama sur Windows

Si le code tourne dans WSL et que Ollama tourne côté Windows:

```env
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_AUTO_START=false
SKIP_OLLAMA_ON_ERROR=true
```

Le pipeline ne tombe plus en erreur si `ollama` n’est pas installé dans WSL.



### Jeu de données de démonstration (50 tickets)

Un fichier fictif est fourni pour tester rapidement sans données réelles :
- `sample_data/tickets_demo_50.xml`

Pour l'utiliser, dans `.env` :
```env
TICKETS_XML_PATH=sample_data/tickets_demo_50.xml
MAX_TICKETS=50
```
Puis lancer normalement :
```bash
bundle exec ruby main.rb
```


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
   ollama pull nomic-embed-text-v2-moe
   ollama pull llama3.2:1b-instruct
   ollama serve
   ```
6. Lancer le projet :
   ```bash
   bundle exec ruby main.rb
   ```

## Déploiement Docker (3 conteneurs)

Le projet peut tourner avec 3 services:
1. `frontend` (Nginx) = interface web statique (rapport HTML + CSV).
2. `app-llm` = pipeline Ruby + runtime Ollama dans le même conteneur.
3. `xml-db` (BaseX) = base NoSQL XML.

Communication inter-conteneurs:
- `app-llm` -> `xml-db` via `http://xml-db:8984/rest/...`
- `frontend` lit les fichiers générés depuis un volume partagé (`reports_data`).

Lancement:

```bash
docker compose up --build
```

Accès frontend:
- `http://localhost:18080`
- rapport: `http://localhost:18080/reports/visualisation.html`

Fichiers livrables:
- `/reports/visualisation.html` (frontend)
- `/reports/tickets_summary.csv` (frontend)

Variables clés Docker:
- `XML_DB_ENABLED=true` (activé dans compose pour le service `app-llm`)
- `XML_DB_BASE_URL=http://xml-db:8984`
- `OLLAMA_BASE_URL=http://127.0.0.1:11434`
- `OLLAMA_AUTO_START=true` (Ollama est démarré dans le conteneur `app-llm`)

Arrêt:

```bash
docker compose down
```

Déploiement sur 3 VMs (mode examen): `docs/vm_deployment_guide.md`
Guide FR/RU (1 ПК и 3 ПК): `docs/deployment_modes_guide_ru.md`

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

Si `bundle install` échoue sur Windows, vérifiez d'abord les toolchains Ruby/MSYS2,
l'accès réseau à rubygems.org, puis relancez:

```powershell
bundle config set force_ruby_platform true
bundle install
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```
