# 03 - Conception

## 3.1 Architecture applicative

Architecture actuelle: pipeline de traitement batch en Ruby.

```mermaid
flowchart TD
    A["main.rb"] --> B["xml_handler.rb"]
    B --> C["tickets en memoire"]
    C --> D["embedding.rb"]
    D --> E["embeddings.json"]
    E --> F["clusterer.rb"]
    F --> G["clusters.json"]
    F --> H["cluster_topics.rb"]
    H --> I["cluster_topics.json"]
    E --> J["clustering_metrics.rb"]
    J --> K["clustering_metrics.json"]
    E --> L["similarity.rb"]
    L --> M["similar_tickets.json"]
    C --> N["visualisation.rb"]
    N --> O["output/visualisation.html"]
```

Projection evolutive possible: exposition d'un service API REST pour consulter les resultats.

### Projection MVC + API REST (cible)

- **Modele**: acces aux entites `Ticket`, `Comment`, `Cluster`, `Similarity`.
- **Controleur**: endpoints REST (`/tickets`, `/clusters`, `/metrics`).
- **Vue**: dashboard web (ou front SPA) consommant l'API.
- **API REST**: format JSON, pagination des tickets, filtres par cluster/periode/statut.

## 3.2 MCD (Modele Conceptuel de Donnees)

Le MVP fonctionne principalement sur fichiers JSON, mais un modele relationnel de reference est defini pour la soutenance.

```mermaid
erDiagram
    TICKET ||--o{ COMMENT : "contient"
    TICKET ||--o| EMBEDDING : "possede"
    TICKET ||--o| CLUSTER_ASSIGNMENT : "appartient a"
    CLUSTER ||--o{ CLUSTER_ASSIGNMENT : "regroupe"
    CLUSTER ||--o| CLUSTER_TOPIC : "possede"
    TICKET ||--o{ TICKET_SIMILARITY : "source"
    TICKET ||--o{ TICKET_SIMILARITY : "cible"
```

## 3.3 MLD (Modele Logique de Donnees)

Tables retenues:
- `tickets(id, nice_id, subject, description, created_at, updated_at, status_id, priority_id, requester_id, raw_payload_json)`
- `comments(id, ticket_id, author_id, created_at, value, is_public)`
- `embeddings(ticket_id, vector_json, model_name, created_at)`
- `clusters(id, label, created_at)`
- `cluster_assignments(ticket_id, cluster_id, assigned_at)`
- `cluster_topics(cluster_id, topic_title, model_name, created_at)`
- `ticket_similarities(source_ticket_id, target_ticket_id, similarity_score, probable_duplicate, created_at)`

Le script SQL associe est fourni: `docs/bts_sio/sql/01_schema.sql`.

## 3.4 Diagramme de classes (niveau code)

```mermaid
classDiagram
    class AppConfig {
      +tickets_xml_path()
      +ollama_embed_model()
      +ollama_llm_model()
      +kmeans_k()
      +run_embeddings?()
      +run_clustering?()
    }

    class XmlHandler {
      +load_tickets_from_xml()
      +parse_xml_records()
      +parse_node_with_schema()
    }

    class Embedding {
      +get_embedding()
      +generate_embeddings_with_tickets()
    }

    class Clusterer {
      +run_clustering()
    }

    class ClusterTopics {
      +generate_cluster_topics()
      +request_cluster_topic()
    }

    class MlUtils {
      +standard_scale()
      +kmeans()
      +cosine()
      +silhouette()
    }

    class Similarity {
      +generate_similarity_report()
    }

    class Visualiser {
      +generate_html_report()
    }

    Clusterer --> MlUtils
    Clusterer --> ClusterTopics
    Similarity --> MlUtils
    Embedding --> AppConfig
    XmlHandler --> AppConfig
```

## 3.5 Diagramme de sequence (run complet)

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant M as main.rb
    participant X as xml_handler.rb
    participant E as embedding.rb
    participant C as clusterer.rb
    participant T as cluster_topics.rb
    participant S as similarity.rb
    participant V as visualisation.rb

    U->>M: bundle exec ruby main.rb
    M->>X: load_tickets_from_xml()
    X-->>M: tickets[]
    M->>E: generate_embeddings_with_tickets()
    E-->>M: embeddings.json
    M->>C: run_clustering()
    C->>T: generate_cluster_topics()
    T-->>C: cluster_topics.json
    C-->>M: clusters.json
    M->>S: generate_similarity_report()
    S-->>M: similar_tickets.json
    M->>V: generate_html_report()
    V-->>U: output/visualisation.html
```

## 3.6 Maquette (rapport HTML - vue cible)

Ecran de sortie souhaite:
1. Bandeau de synthese: nombre de tickets, nombre de clusters, taux de doublons probables.
2. Bloc "Top clusters": label cluster + volume + exemple de ticket.
3. Bloc "Tickets similaires": top-k par ticket.
4. Bloc "Metrices": silhouette + courbe elbow.
5. Bloc "Filtres": periode, cluster, statut.
