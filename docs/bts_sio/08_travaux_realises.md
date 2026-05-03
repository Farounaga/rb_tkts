# 08 - Travaux realises (exam)

## Objectif du document

Ce document de synthese decrit, de maniere detaillee, les travaux realises pour:
1. **Tests unitaires et fiabilite**.
2. **Evolution fonctionnelle export CSV**.

Il explique aussi:
- la chronologie des actions,
- les problemes rencontres,
- les decisions techniques et leurs motivations,
- la verification finale (tests + execution).

Ce support est pense pour la soutenance BTS: il sert a justifier les choix, la methode et le resultat.

## 1) Exigences initiales a couvrir

### 1.1 Exigences fonctionnelles

- Mettre en place des tests unitaires automatises pour les modules de calcul et d'analyse.
- Verifier des traitements mathematiques sur des cas connus et verifiables.
- Ajouter au moins un cas limite pour la robustesse.
- Securiser les evolutions futures via une base de tests.
- Ajouter un export des resultats au format CSV pour utilisateurs non techniques.
- Integrer cet export au pipeline existant.
- Permettre activation/desactivation de l'export via configuration.
- Utiliser uniquement les bibliotheques standard Ruby pour le CSV.

### 1.2 Exigences transverses

- Identifier et supprimer du code redondant/obsolete (refactoring incomplet).
- Ameliorer lisibilite, coherence et maintenabilite.
- Harmoniser la gestion de configuration.
- Conserver le comportement fonctionnel global du pipeline.
- Ajouter des commentaires en francais sur les zones importantes.

## 2) Chronologie detaillee des actions

## 2.1 Etape A - Audit initial du code

Analyse des fichiers principaux:
- `main.rb` (orchestration),
- `config.rb` (configuration),
- `clusterer.rb` (clustering),
- `clustering_metrics.rb`,
- `similarity.rb`,
- `ollama_bootstrap.rb`,
- `spec/` (tests existants),
- documentation `docs/`.

Constats majeurs:
- Le pipeline est deja structure, mais l'export CSV n'existe pas.
- La partie tests couvre XML/config/topics/bootstrap, pas assez la partie mathematique.
- `clusterer.rb` contenait un refactoring incomplet (double chemin MlUtils + Rumale).
- La gestion des flags ENV etait fonctionnelle mais peu harmonisee.

## 2.2 Etape B - Refactoring de fiabilisation (sans changer l'intention metier)

### B1. Nettoyage `clusterer.rb`

Probleme:
- code redondant, duplicate `require`,
- deux implementations KMeans dans un meme flux,
- risque de confusion et de regression.

Action:
- suppression du chemin obsolete,
- conservation d'un chemin unique base sur `MlUtils`:
  - standardisation (`MlUtils.standard_scale`),
  - clustering (`MlUtils.kmeans`),
  - generation optionnelle de topics.

Effet:
- lisibilite nettement meilleure,
- maintenance plus simple,
- comportement metier conserve (sortie `clusters.json` + topics optionnels).

### B2. Harmonisation de configuration (`config.rb`)

Action:
- introduction de helpers communs:
  - `fetch_string`,
  - `fetch_bool`,
  - `fetch_int`,
  - `fetch_float`.

Ajouts de flags:
- `RUN_EXPORT_CSV`,
- `CSV_EXPORT_OUTPUT`,
- `SKIP_OLLAMA_ON_ERROR`.

Effet:
- suppression de duplication de parsing ENV,
- configuration plus previsible,
- meilleure maintenabilite.

## 2.3 Etape C - Ajout de l'export CSV

### C1. Creation de `export_csv.rb`

Objectif:
- produire un fichier CSV unique, lisible par public non technique, en sortie de pipeline.

Contraintes respectees:
- uniquement bibliotheques standard Ruby:
  - `csv`,
  - `json`,
  - `fileutils`.

Donnees agragees:
- tickets (id, sujet, date, statut, tags, nb commentaires),
- cluster (`clusters.json`),
- topic de cluster (`cluster_topics.json`),
- similarite (`similar_tickets.json`),
- metriques globales (`clustering_metrics.json`),
- dimension des embeddings (`embeddings.json`).

### C2. Integration dans `main.rb`

Action:
- ajout `require_relative 'export_csv'`,
- ajout d'une etape finale:
  - executee si `RUN_EXPORT_CSV=true`,
  - ignoree sinon.

Effet:
- export integre au flux existant sans casser le reste.

## 2.4 Etape D - Robustesse Ollama (cas WSL/Windows)

Contexte reel rencontre:
- execution en WSL,
- Ollama accessible cote Windows via HTTP,
- mais binaire `ollama` absent dans WSL.

Erreur observee avant correction:
- `Errno::ENOENT` dans autostart (`spawn 'ollama'`).

Actions:
- adaptation de `OllamaBootstrap.ensure_ready!` pour renvoyer un statut pret/non pret,
- ajout d'une exception explicite `UnavailableError`,
- gestion en mode degrade dans `main.rb`:
  - si `SKIP_OLLAMA_ON_ERROR=true`, on skip embeddings/topics plutot que casser le run.

Effet:
- pipeline resilient en environnement hybride,
- meilleur comportement en exploitation.

## 2.5 Etape E - Renforcement des tests

Nouveaux tests ajoutes:
- `spec/ml_utils_spec.rb`
- `spec/clustering_metrics_spec.rb`
- `spec/export_csv_spec.rb`

Tests existants completes:
- `spec/config_spec.rb`
- `spec/ollama_bootstrap_spec.rb`

Cas mathematiques verifiables:
- cosinus identique = `1.0`,
- cosinus orthogonal = `0.0`,
- distance 3-4-5 = `5.0`,
- centrage standard scale.

Cas limites:
- vecteur nul pour cosinus,
- `k > n` sur KMeans.

## 2.6 Etape F - Documentation

Fichiers documentaires mis a jour:
- `README.md`,
- `docs/code_flow.md`,
- `docs/bts_sio/02_analyse.md`,
- `docs/bts_sio/04_realisation.md`,
- `docs/bts_sio/05_tests.md`,
- `docs/bts_sio/rapports/rapport_tests.md`.

Ajout de ce present document:
- `docs/bts_sio/08_travaux_realises.md`.

## 3) Mapping exigences -> realisation

| Exigence | Realisation | Fichiers |
|---|---|---|
| Tests unitaires calcul/analyse | Ajout specs mathematiques et metriques | `spec/ml_utils_spec.rb`, `spec/clustering_metrics_spec.rb` |
| Cas connus/verifiables | Cas cosinus/euclidienne/standardisation | `spec/ml_utils_spec.rb` |
| Cas limite robustesse | Vecteur nul + `k > n` | `spec/ml_utils_spec.rb` |
| Securiser evolutions | Suite RSpec completee | `spec/*` |
| Export CSV non technique | Module d'export unique | `export_csv.rb` |
| Integrer au pipeline | Appel dans l'orchestration | `main.rb` |
| Activer/desactiver export | Flags ENV dedies | `config.rb`, `.env.example` |
| Bibliotheques standard Ruby | Utilisation `csv/json/fileutils` | `export_csv.rb` |
| Supprimer redondances obsolete | Nettoyage clusterer | `clusterer.rb` |
| Harmoniser config | Helpers centralises | `config.rb` |
| Conserver pipeline | Flux maintenu + garde-fous | `main.rb`, `ollama_bootstrap.rb` |
| Commentaires FR dans code | Commentaires ajoutés aux points critiques | `main.rb`, `config.rb`, `clusterer.rb`, `export_csv.rb`, `ollama_bootstrap.rb` |

## 4) Problemes rencontres et resolution

## 4.1 Refactoring incomplet dans clustering

Symptomes:
- logique double, plus difficile a comprendre.

Risque:
- maintenance compliquée,
- difficultes de validation lors des evolutions.

Resolution:
- garder un seul chemin MlUtils,
- retirer l'ancien chemin obsolete.

## 4.2 Erreur Bundler (gems natives indisponibles)

Symptome:
- `Bundler::GemNotFound` sur dependances ML natives (`rumale`, `numo-narray`).

Analyse:
- ces gems n'etaient plus necessaires apres nettoyage du flux clustering.

Resolution:
- suppression des dependances inutiles dans `Gemfile`,
- regeneration lockfile locale,
- ajustement `bin/check_env.rb`.

## 4.3 Cas WSL + Ollama sur Windows

Symptome:
- autostart impossible (`ollama` introuvable cote WSL).

Resolution:
- mode degrade configurable (`SKIP_OLLAMA_ON_ERROR`),
- etapes Ollama skipables sans casser tout le traitement.

Configuration recommandee:

```env
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_AUTO_START=false
SKIP_OLLAMA_ON_ERROR=true
```

## 4.4 Tickets trop longs pour embeddings (context length exceeded)

Symptome:
- logs Ollama: `llm embedding error: the input length exceeds the context length`,
- retour HTTP 500 sur `/api/embeddings`.

Cause:
- certains tickets concatennent beaucoup de contenu (description + nombreux commentaires),
- longueur effective trop grande pour le contexte du modele d'embeddings.

Resolution:
- ajout d'une preparation de texte avant embedding (`prepare_text_for_embedding`),
- troncature automatique configurable via `EMBEDDING_MAX_CHARS`,
- strategie de troncature "debut + fin" pour garder le contexte initial et les infos recentes,
- en retry, reduction progressive de la taille texte.

Parametre associe:

```env
EMBEDDING_MAX_CHARS=12000
```

Si l'erreur persiste:
- reduire a `8000` puis `6000`.

## 5) Motivations techniques (pourquoi ces choix)

1. **Fiabilite operationnelle**
- Un incident local (service Ollama indisponible) ne doit pas rendre le pipeline inutilisable.

2. **Maintenabilite**
- Moins de chemins techniques concurrents,
- configuration centralisee,
- tests explicites sur les calculs critiques.

3. **Lisibilite soutenance**
- code plus lineaire,
- commentaires en francais sur decisions clefs,
- documentation coherent avec le code reel.

4. **Compatibilite metier**
- CSV lisible et exploitable dans Excel/LibreOffice,
- pas de dependance externe pour l'export.

## 6) Verification finale

## 6.1 Verification automatique

Commande executee:

```bash
bundle exec rspec
```

Resultat obtenu:
- `25 examples`
- `0 failures`

## 6.2 Verification syntaxique

Verifications executees:
- `ruby -c main.rb`
- `ruby -c export_csv.rb`
- `ruby -c clusterer.rb`
- `ruby -c ollama_bootstrap.rb`
- `ruby -c config.rb`

Resultat:
- `Syntax OK` sur chaque fichier.

## 6.3 Verification fonctionnelle ciblée

Scenarios verifies:
- run avec export CSV actif,
- run avec Ollama indisponible + mode degrade actif,
- generation effective de `output/tickets_summary.csv`.

## 7) Liste detaillee des fichiers modifies/ajoutes

## 7.1 Fichiers modifies

- `.env.example`
- `Gemfile`
- `Gemfile.lock`
- `README.md`
- `bin/check_env.rb`
- `clusterer.rb`
- `config.rb`
- `docs/bts_sio/02_analyse.md`
- `docs/bts_sio/04_realisation.md`
- `docs/bts_sio/05_tests.md`
- `docs/bts_sio/README.md`
- `docs/bts_sio/rapports/rapport_tests.md`
- `docs/code_flow.md`
- `main.rb`
- `ollama_bootstrap.rb`
- `spec/config_spec.rb`
- `spec/ollama_bootstrap_spec.rb`

## 7.2 Fichiers ajoutes

- `export_csv.rb`
- `spec/ml_utils_spec.rb`
- `spec/clustering_metrics_spec.rb`
- `spec/export_csv_spec.rb`
- `docs/bts_sio/08_travaux_realises.md`

## 8) Consignes de reproduction (jury / relecture)

1. Installer les dependances:

```bash
bundle install
```

2. Configurer l'environnement:
- copier `.env.example` vers `.env`,
- ajuster au besoin:
  - `RUN_EXPORT_CSV=true`,
  - `CSV_EXPORT_OUTPUT=output/tickets_summary.csv`,
  - en WSL: `OLLAMA_AUTO_START=false` et `SKIP_OLLAMA_ON_ERROR=true`.

3. Lancer les tests:

```bash
bundle exec rspec
```

4. Lancer le pipeline:

```bash
bundle exec ruby main.rb
```

5. Verifier les sorties:
- `output/visualisation.html`
- `output/tickets_summary.csv`

## 9) Conclusion

Les deux objectifs principaux ont ete realises:
- fiabilite amelioree via tests unitaires cibles et cas limites,
- export CSV complet integre au pipeline et configurable.

En parallele, la base technique a ete assainie (refactoring, configuration, documentation) tout en conservant le comportement fonctionnel attendu du projet.

## 10) Containerisation Docker (3 services)

Objectif:
- isoler les composants,
- garantir une execution reproductible,
- separer clairement l'application, la base XML NoSQL et le service LLM.

Services ajoutes:
- `xml-db` (BaseX, REST XML),
- `ollama` (serveur + pull des modeles),
- `app` (pipeline Ruby).

Fichiers ajoutes:
- `docker-compose.yml`
- `Dockerfile`
- `.dockerignore`
- `xml_db_client.rb` (pont applicatif vers BaseX REST).

Flux principal:
1. `app` tente de lire le XML depuis `xml-db`.
2. Si absent, `app` peut importer le XML local en base (`XML_DB_IMPORT_ON_START=true`).
3. `app` relit le XML depuis la base et execute le pipeline.
4. `app` appelle `ollama` pour embeddings/topics.

Motivation:
- separation des responsabilites,
- meilleure demonstration technique pour soutenance,
- preparation a un deploiement plus proche production.
