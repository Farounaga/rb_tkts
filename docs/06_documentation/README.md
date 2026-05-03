# 06 - Documentation

## Documentation technique

### Installation locale

Pre-requis:

- Ruby `>= 3.3.10`;
- Bundler;
- Ollama pour les embeddings et topics;
- modeles recommandes: `nomic-embed-text-v2-moe` et `llama3.2:1b-instruct`.

Etapes:

```bash
gem install bundler
bundle install
cp .env.example .env
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```

Sous PowerShell:

```powershell
Copy-Item .env.example .env
bundle exec ruby bin/check_env.rb
bundle exec ruby main.rb
```

### Configuration minimale pour une demonstration

```env
TICKETS_XML_PATH=sample_data/tickets_demo_50.xml
MAX_TICKETS=50
RUN_EXPORT_CSV=true
SKIP_OLLAMA_ON_ERROR=true
```

### Sorties generees

| Fichier | Description |
|---|---|
| `embeddings.json` | Vecteurs d'embeddings par ticket |
| `clusters.json` | Association ticket -> cluster |
| `cluster_topics.json` | Titre lisible de chaque cluster |
| `clustering_metrics.json` | Score silhouette et courbe elbow |
| `similar_tickets.json` | Top-k des tickets similaires |
| `output/tickets_summary.csv` | Export metier tabulaire |
| `output/visualisation.html` | Rapport HTML |

## Guide de deploiement Docker

Commande:

```bash
docker compose up --build
```

Acces:

- portail: `http://localhost:8080`;
- rapport HTML: `http://localhost:8080/reports/visualisation.html`;
- CSV: `http://localhost:8080/reports/tickets_summary.csv`;
- BaseX: `http://localhost:8984`.

Arret:

```bash
docker compose down
```

## Guide utilisateur

### Scenario 1 - Lancer une analyse simple

1. Copier `.env.example` vers `.env`.
2. Renseigner `TICKETS_XML_PATH`.
3. Pour une premiere verification, renseigner `MAX_TICKETS=50`.
4. Lancer `bundle exec ruby main.rb`.
5. Ouvrir `output/visualisation.html`.
6. Ouvrir `output/tickets_summary.csv` dans Excel ou LibreOffice.

### Scenario 2 - Analyser les clusters

1. Verifier que `RUN_EMBEDDINGS=true` et `RUN_CLUSTERING=true`.
2. Choisir `KMEANS_K` selon le nombre de themes souhaite.
3. Lancer le pipeline.
4. Consulter `clusters.json`, `cluster_topics.json` et le rapport HTML.
5. Ajuster `KMEANS_K` en utilisant `clustering_metrics.json`.

### Scenario 3 - Detecter les doublons probables

1. Verifier que `RUN_SIMILARITY=true`.
2. Regler `SIMILARITY_TOP_K` et `SIMILARITY_THRESHOLD`.
3. Lancer le pipeline.
4. Consulter `similar_tickets.json` ou les colonnes `top_similar_ticket`, `top_similarity`, `probable_duplicates_count` du CSV.

### Scenario 4 - Execution sans IA

Pour produire un rapport ou un CSV sans appel Ollama:

```env
RUN_EMBEDDINGS=false
RUN_CLUSTER_TOPICS=false
SKIP_OLLAMA_ON_ERROR=true
```

Le clustering et les similarites necessitent cependant un fichier `embeddings.json` deja present.

## Documentation d'exploitation

| Probleme | Cause probable | Solution |
|---|---|---|
| `cannot load such file -- httparty` | Gems non installees | Executer `bundle install` |
| Ollama introuvable | Service ou binaire absent | Installer Ollama ou desactiver autostart |
| Texte trop long pour le modele | Contexte du modele depasse | Baisser `EMBEDDING_MAX_CHARS` |
| Pas de clustering | `embeddings.json` absent | Activer `RUN_EMBEDDINGS` ou fournir le fichier |
| BaseX indisponible | Service Docker non lance | Relancer `docker compose up --build` ou desactiver `XML_DB_ENABLED` |

## Securite et donnees

- Ne pas commiter `.env` contenant des secrets.
- Utiliser `.env.example` comme modele public.
- Privilegier Ollama local pour eviter la fuite de donnees support.
- Masquer ou anonymiser les tickets reels lors d'une demonstration publique.

