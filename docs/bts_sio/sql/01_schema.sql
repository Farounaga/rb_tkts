-- Schema SQL de reference pour le dossier BTS SIO
-- Compatible PostgreSQL (adaptable facilement a SQLite/MySQL)

CREATE TABLE IF NOT EXISTS tickets (
  id BIGSERIAL PRIMARY KEY,
  nice_id VARCHAR(64) NOT NULL UNIQUE,
  subject TEXT,
  description TEXT,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  status_id VARCHAR(64),
  priority_id VARCHAR(64),
  requester_id VARCHAR(64),
  raw_payload_json JSONB,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS comments (
  id BIGSERIAL PRIMARY KEY,
  ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_id VARCHAR(64),
  created_at TIMESTAMP NULL,
  value TEXT,
  is_public BOOLEAN,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS embeddings (
  ticket_id BIGINT PRIMARY KEY REFERENCES tickets(id) ON DELETE CASCADE,
  model_name VARCHAR(128) NOT NULL,
  vector_json JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clusters (
  id BIGSERIAL PRIMARY KEY,
  label INTEGER NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cluster_assignments (
  ticket_id BIGINT PRIMARY KEY REFERENCES tickets(id) ON DELETE CASCADE,
  cluster_id BIGINT NOT NULL REFERENCES clusters(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cluster_topics (
  cluster_id BIGINT PRIMARY KEY REFERENCES clusters(id) ON DELETE CASCADE,
  topic_title TEXT,
  model_name VARCHAR(128),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ticket_similarities (
  source_ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  target_ticket_id BIGINT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  similarity_score DOUBLE PRECISION NOT NULL,
  probable_duplicate BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (source_ticket_id, target_ticket_id)
);

CREATE INDEX IF NOT EXISTS idx_comments_ticket_id ON comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_cluster_assignments_cluster_id ON cluster_assignments(cluster_id);
CREATE INDEX IF NOT EXISTS idx_ticket_similarities_source ON ticket_similarities(source_ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_similarities_target ON ticket_similarities(target_ticket_id);
