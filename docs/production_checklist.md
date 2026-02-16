# Checklist de production : passer du MVP à un livrable diplôme/employeur

## 1) Architecture & pipeline

### 1.1 Point d’entrée unique
- Ajouter un CLI unique (`bin/pipeline`) avec les étapes :
  - `extract`
  - `clean`
  - `embed`
  - `cluster`
  - `topics`
  - `report`
- Chaque étape doit prendre des entrées/sorties explicites et être idempotente.

### 1.2 Couche de configuration
- Créer une configuration centralisée (`config.yml` + surcharge via ENV) :
  - chemins input/output,
  - paramètres des modèles,
  - nombre de threads,
  - `k` pour KMeans,
  - seuil de similarité.

### 1.3 Contrats de données
- Formaliser les schémas JSON :
  - `tickets.cleaned.jsonl`
  - `embeddings.json`
  - `clusters.json`
  - `cluster_topics.json`
  - `similar_tickets.json`

---

## 2) Qualité des données (must-have)

### 2.1 Module de nettoyage
Isoler un module dédié :
- HTML → texte brut,
- suppression des signatures/disclaimers,
- filtrage des auto-réponses Zendesk,
- normalisation des espaces/caractères invisibles/BOM,
- déduplication des commentaires identiques.

### 2.2 Validation
- Contrôles sur les champs vides/corrompus (`created_at`, `nice_id`, `comments`).
- Rapport qualité après nettoyage :
  - % de commentaires vides,
  - % d’auto-réponses,
  - % de bruit supprimé.

---

## 3) Analyse IA

**Principe clé à préserver : 2 modèles IA locaux distincts**
- Modèle d'embeddings local pour vectoriser (`mxbai-embed-large`).
- Modèle LLM local séparé pour nommer/résumer les topics (`llama3:instruct`).

### 3.1 Embeddings
- Passer à `mxbai-embed-large` comme modèle principal.
- Logger la latence et le taux de retry.
- Mettre en cache les embeddings via `ticket_id + hash(text)`.

### 3.2 Tickets similaires
- Ajouter la similarité cosinus :
  - top-5 similaires pour chaque ticket,
  - seuil « doublon probable » >= 0.80.

### 3.3 Qualité du clustering
- Ajouter sélection automatique de `k` (elbow/silhouette) + override manuel.
- Exposer les métriques de qualité du clustering dans le rapport.

### 3.4 Résumés de cluster
- Générer les résumés sur un échantillon de 5–20 commentaires représentatifs (et non 1 seul).
- Stocker `topic_title`, `topic_summary`, `sample_ticket_ids`.

---

## 4) Reporting & sorties métier

- Visualisations :
  - volume temporel,
  - pics/anomalies,
  - tags par semaine,
  - top clusters,
  - heatmap des tickets similaires.
- Exports métier :
  - CSV/JSON des problèmes prioritaires,
  - synthèse mensuelle (markdown/pdf).

---

## 5) Qualité d’ingénierie

### 5.1 Sécurité
- Ne jamais conserver email/token Zendesk en dur dans le code.
- Utiliser uniquement ENV + `.env.example`.

### 5.2 Tests
- Tests unitaires :
  - parser XML,
  - cleaner,
  - similarité,
  - IO clustering.
- Smoke test end-to-end sur un petit dataset de fixtures.

### 5.3 Observabilité
- Logs standardisés par étape + durée.
- `run_manifest.json` pour chaque exécution (versions, paramètres, sorties).

### 5.4 Reproductibilité
- `Gemfile` / lockfile.
- Seeds aléatoires fixés.
- `RUNBOOK.md` pour exécution locale et CI.

---

## 6) Livrables « prêts soutenance / prêts entreprise »

À préparer :
1. Schéma d’architecture du pipeline (1 page).
2. README avec quickstart.
3. Jeu de données de démonstration + exécution reproductible.
4. Métriques avant/après nettoyage + qualité du clustering.
5. 3–5 cas d’usage métier extraits des données.
6. Limites actuelles + roadmap à 3 mois.

---

## Plan conseillé sur 4 semaines

### Semaine 1
- Configuration + CLI + gestion sécurisée des ENV.
- Stabilisation extract/report.

### Semaine 2
- Pipeline de nettoyage complet + rapport qualité.
- Migration embeddings vers `mxbai-embed-large`.

### Semaine 3
- Similarité + déduplication + qualité clustering.
- Résumés de clusters améliorés.

### Semaine 4
- Finalisation dashboard/reporting.
- Documentation de soutenance + handover employeur.
