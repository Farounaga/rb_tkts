# 03 - Conception

## Architecture applicative actuelle

Le projet fonctionne comme une architecture batch modulaire:

- entree: fichier XML local ou XML recupere depuis BaseX REST;
- traitement: scripts Ruby;
- IA locale: Ollama pour embeddings et titres;
- sorties: JSON, CSV et HTML;
- diffusion: frontend Nginx statique en Docker.

```mermaid
flowchart TD
    user["Utilisateur"] --> main["main.rb"]
    main --> config["config.rb / .env"]
    main --> xdb{"XML_DB_ENABLED ?"}
    xdb -- oui --> basex["BaseX REST xml-db"]
    xdb -- non --> xmlfile["tickets.xml local"]
    basex --> xmlhandler["xml_handler.rb"]
    xmlfile --> xmlhandler
    xmlhandler --> tickets["Tickets en memoire"]
    tickets --> emb["embedding.rb"]
    emb --> ollama1["Ollama /api/embeddings"]
    emb --> embeddings["embeddings.json"]
    embeddings --> clusterer["clusterer.rb"]
    clusterer --> ml["ml_utils.rb"]
    clusterer --> clusters["clusters.json"]
    clusterer --> topics["cluster_topics.rb"]
    topics --> ollama2["Ollama /api/generate"]
    topics --> topicsjson["cluster_topics.json"]
    embeddings --> metrics["clustering_metrics.rb"]
    metrics --> metricsjson["clustering_metrics.json"]
    embeddings --> similarity["similarity.rb"]
    similarity --> similarjson["similar_tickets.json"]
    tickets --> csv["export_csv.rb"]
    csv --> csvout["output/tickets_summary.csv"]
    tickets --> html["visualisation.rb"]
    html --> report["output/visualisation.html"]
    report --> nginx["frontend Nginx"]
    csvout --> nginx
```

## Architecture MVC / API REST

L'application actuelle n'est pas une application MVC classique. Pour l'analyse BTS SIO SLAM, on peut la positionner ainsi:

| Couche | Element actuel | Evolution possible |
|---|---|---|
| Modele | Structures Ruby Hash issues du XML, fichiers JSON, schema SQL de reference | Classes `Ticket`, `Comment`, `Cluster`, persistance SQL |
| Vue | `visualisation.rb` genere du HTML, `docker/frontend/index.html` liste les livrables | Dashboard interactif |
| Controleur | `main.rb` orchestre le pipeline | API REST avec routes `/tickets`, `/clusters`, `/metrics` |
| Service | `embedding.rb`, `clusterer.rb`, `similarity.rb`, `export_csv.rb` | Services applicatifs reutilisables par API |

Projection REST cible:

```mermaid
flowchart LR
    front["Dashboard web"] --> api["API REST"]
    api --> tickets["GET /tickets"]
    api --> clusters["GET /clusters"]
    api --> metrics["GET /metrics"]
    api --> similar["GET /tickets/:id/similar"]
    api --> db["Base relationnelle ou documents JSON"]
```

## MCD

Le MCD complet est fourni dans [mcd.mmd](mcd.mmd).

```mermaid
erDiagram
    TICKET ||--o{ COMMENTAIRE : contient
    TICKET ||--o{ ENTREE_CHAMP_TICKET : possede
    TICKET ||--o| EMBEDDING : est_vectorise_par
    TICKET ||--o| AFFECTATION_CLUSTER : est_classe_dans
    CLUSTER ||--o{ AFFECTATION_CLUSTER : regroupe
    CLUSTER ||--o| TOPIC_CLUSTER : est_decrit_par
    TICKET ||--o{ SIMILARITE_TICKET : source
    TICKET ||--o{ SIMILARITE_TICKET : cible
```

## MLD

Le MLD complet est fourni dans [mld.mmd](mld.mmd). Un script SQL de reference existe deja dans `docs/bts_sio/sql/01_schema.sql`.

Tables de reference:

- `tickets`
- `comments`
- `embeddings`
- `clusters`
- `cluster_assignments`
- `cluster_topics`
- `ticket_similarities`

## Diagramme de classes

```mermaid
classDiagram
    class AppConfig {
      +tickets_xml_path()
      +xml_db_enabled?()
      +ollama_embed_model()
      +ollama_llm_model()
      +kmeans_k()
      +run_embeddings?()
      +run_clustering?()
      +similarity_threshold()
    }

    class XmlDbClient {
      +resolve_tickets_xml_path(local_fallback_path)
      +fetch_xml_from_db(output_path)
      +upload_xml_to_db(input_path)
      +rest_resource_url()
    }

    class XmlHandler {
      +load_tickets_from_xml(file_path)
      +parse_xml_records(file_path)
      +parse_node_with_schema(node, schema)
      +map_fields(node, field_mapping)
    }

    class EmbeddingService {
      +prepare_text_for_embedding(text)
      +get_embedding(text)
      +generate_embeddings_with_tickets(documents, tickets)
    }

    class ClusterService {
      +run_clustering(input_file, output_file, k)
    }

    class ClusterTopicService {
      +generate_cluster_topics(clusters, tickets)
      +request_cluster_topic(prompt)
      +clean_topic_title(raw)
    }

    class MlUtils {
      +standard_scale(vectors)
      +kmeans(vectors, k)
      +cosine(a, b)
      +silhouette(vectors, labels)
    }

    class SimilarityService {
      +generate_similarity_report(input_file, output_file)
    }

    class ExportCsvService {
      +export_tickets_summary_csv(tickets)
    }

    class Visualiser {
      +generate_html_report(tickets, output_path)
    }

    AppConfig <.. XmlDbClient
    AppConfig <.. EmbeddingService
    AppConfig <.. ClusterService
    AppConfig <.. SimilarityService
    XmlDbClient --> XmlHandler
    ClusterService --> MlUtils
    ClusterService --> ClusterTopicService
    SimilarityService --> MlUtils
    Visualiser --> ExportCsvService
```

## Diagramme de sequence - execution complete

```mermaid
sequenceDiagram
    actor U as Utilisateur
    participant M as main.rb
    participant Cfg as AppConfig
    participant XDB as XmlDbClient
    participant XML as xml_handler.rb
    participant O as OllamaBootstrap
    participant E as embedding.rb
    participant K as clusterer.rb
    participant T as cluster_topics.rb
    participant S as similarity.rb
    participant CSV as export_csv.rb
    participant V as visualisation.rb

    U->>M: bundle exec ruby main.rb
    M->>Cfg: lire .env et flags
    M->>XDB: resolve_tickets_xml_path()
    XDB-->>M: chemin XML local/cache
    M->>XML: load_tickets_from_xml()
    XML-->>M: tickets[]
    M->>O: ensure_ready! si IA necessaire
    M->>E: generate_embeddings_with_tickets()
    E-->>M: embeddings.json
    M->>K: run_clustering()
    K->>T: generate_cluster_topics()
    T-->>K: cluster_topics.json
    K-->>M: clusters.json
    M->>S: generate_similarity_report()
    S-->>M: similar_tickets.json
    M->>CSV: export_tickets_summary_csv()
    CSV-->>M: tickets_summary.csv
    M->>V: generate_html_report()
    V-->>U: visualisation.html
```

## Diagramme de sequence - mode degrade Ollama

```mermaid
sequenceDiagram
    participant M as main.rb
    participant O as OllamaBootstrap
    participant E as embedding.rb
    participant K as clusterer.rb
    participant V as visualisation.rb

    M->>O: ensure_ready!()
    O-->>M: erreur ou false
    alt SKIP_OLLAMA_ON_ERROR=true
        M->>M: desactive embeddings et topics
        M-->>E: skip RUN_EMBEDDINGS
        M-->>K: clustering seulement si embeddings.json existe
        M->>V: genere rapport HTML
    else SKIP_OLLAMA_ON_ERROR=false
        M-->>M: leve l'erreur
    end
```

## Maquette fonctionnelle

Le frontend Docker (`docker/frontend/index.html`) est un portail statique listant les livrables:

- lien vers `/reports/visualisation.html`;
- lien vers `/reports/tickets_summary.csv`.

Le rapport HTML genere par `visualisation.rb` contient des sections de synthese, graphiques et tableaux. Les sorties attendues sont:

| Zone | Objectif |
|---|---|
| Synthese | Nombre de tickets, activite, indicateurs globaux |
| Graphiques | Evolution quotidienne, cumul, tags principaux |
| Analyse themes | Clusters et topics lorsqu'ils sont disponibles |
| Similarite | Identification de tickets proches ou doublons |
| Export | Consultation HTML et exploitation CSV |

