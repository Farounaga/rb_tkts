-- Jeu minimal de donnees de demonstration

INSERT INTO tickets (nice_id, subject, description, status_id, priority_id, requester_id)
VALUES
  ('TKT-1001', 'Erreur de connexion', 'Impossible de se connecter a l application', 'open', 'high', 'REQ-1'),
  ('TKT-1002', 'Carnet non partageable', 'Le partage du carnet echoue', 'open', 'medium', 'REQ-2')
ON CONFLICT (nice_id) DO NOTHING;

INSERT INTO comments (ticket_id, author_id, value, is_public)
SELECT id, 'USR-10', 'Message de test pour le ticket TKT-1001', TRUE
FROM tickets
WHERE nice_id = 'TKT-1001'
ON CONFLICT DO NOTHING;

INSERT INTO comments (ticket_id, author_id, value, is_public)
SELECT id, 'USR-11', 'Message de test pour le ticket TKT-1002', TRUE
FROM tickets
WHERE nice_id = 'TKT-1002'
ON CONFLICT DO NOTHING;

INSERT INTO clusters (label)
VALUES (0), (1)
ON CONFLICT (label) DO NOTHING;

INSERT INTO cluster_assignments (ticket_id, cluster_id)
SELECT t.id, c.id
FROM tickets t
JOIN clusters c ON (t.nice_id = 'TKT-1001' AND c.label = 0) OR (t.nice_id = 'TKT-1002' AND c.label = 1)
ON CONFLICT (ticket_id) DO NOTHING;

INSERT INTO cluster_topics (cluster_id, topic_title, model_name)
SELECT c.id, 'Problemes de connexion', 'llama3.2:1b-instruct'
FROM clusters c
WHERE c.label = 0
ON CONFLICT (cluster_id) DO NOTHING;

INSERT INTO cluster_topics (cluster_id, topic_title, model_name)
SELECT c.id, 'Partage de carnet impossible', 'llama3.2:1b-instruct'
FROM clusters c
WHERE c.label = 1
ON CONFLICT (cluster_id) DO NOTHING;
