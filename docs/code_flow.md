# Schéma de fonctionnement du code

Ce document décrit le **flux d'exécution réel** du projet (pipeline principal + dépendances).

## 1) Vue d'ensemble (pipeline)

```mermaid
flowchart TD
    A[main.rb\nPoint d'entrée] --> B[config.rb\nCharge .env / ENV]
    A --> C[xml_handler.rb\nload_tickets_from_xml]
    C --> D[(tickets en mémoire)]

    A --> E{RUN_EMBEDDINGS\nou RUN_CLUSTERING ?}
    E -- oui --> F[ollama_bootstrap.rb\nensure_ready!]
    F --> F1{OLLAMA_AUTO_START=true\net OLLAMA_BASE_URL local ?}
    F1 -- oui --> F2[Check /api/tags]
    F2 --> F3[Start `ollama serve` si nécessaire]
    F3 --> F4[Pull modèles manquants]
    F1 -- non --> G[Continuer sans autostart]

    D --> H{RUN_EMBEDDINGS ?}
    H -- oui --> I[embedding.rb\ngenerate_embeddings_with_tickets]
    I --> I1[(embeddings.json)]
    H -- non --> J[Skip embeddings]

    I1 --> K{RUN_CLUSTERING ?}
    J --> K
    K -- oui --> L[clusterer.rb\nrun_clustering]
    L --> L1[(clusters.json)]
    L --> M[cluster_topics.rb\ngenerate_cluster_topics]
    M --> M1[(cluster_topics.json)]
    K -- non --> N[Skip clustering]

    L1 --> O{RUN_CLUSTERING_METRICS ?}
    O -- oui --> P[clustering_metrics.rb\nevaluate_clustering_metrics]
    P --> P1[(clustering_metrics.json)]
    O -- non --> Q[Skip metrics]

    L1 --> R{RUN_SIMILARITY ?}
    R -- oui --> S[similarity.rb\ngenerate_similarity_report]
    S --> S1[(similar_tickets.json)]
    R -- non --> T[Skip similarity]

    D --> U[visualisation.rb\nGenerate HTML report]
    U --> U1[(output/visualisation.html)]

    U1 --> V[ensure block main.rb]
    V --> W[ollama_bootstrap.rb\nshutdown_if_started!]
```

## 2) Dépendances principales

```mermaid
flowchart LR
    main[main.rb] --> cfg[config.rb]
    main --> xml[xml_handler.rb]
    main --> emb[embedding.rb]
    main --> clu[clusterer.rb]
    main --> topics[cluster_topics.rb]
    main --> sim[similarity.rb]
    main --> metrics[clustering_metrics.rb]
    main --> vis[visualisation.rb]
    main --> boot[ollama_bootstrap.rb]

    clu --> ml[ml_utils.rb]
    clu --> topics
    vis --> calc[calculs.rb]
```

## 3) Entrées / sorties

- Entrée principale:
  - `TICKETS_XML_PATH` → XML tickets.
- Sorties pipeline:
  - `embeddings.json`
  - `clusters.json`
  - `cluster_topics.json`
  - `clustering_metrics.json`
  - `similar_tickets.json`
  - `output/visualisation.html`

## 4) Notes d'architecture (actuel)

- Le XML est lu en streaming au démarrage (`main.rb`) avec une limite optionnelle `MAX_TICKETS`, via un schéma de mapping configurable dans `xml_handler.rb`, puis rechargé dans `clusterer.rb` pour la phase topics.
- Le bootstrap Ollama n'agit que si une étape Ollama est activée (`embeddings` ou `clustering`).
- Si `OLLAMA_MODELS` est défini, il a priorité pour le préchargement des modèles ; sinon le code se base sur `OLLAMA_EMBED_MODEL` / `OLLAMA_LLM_MODEL`.
- En fin de run, `main.rb` appelle `shutdown_if_started!` : le process Ollama est arrêté uniquement s'il a été lancé automatiquement par ce run.
