# Note de cadrage - SYADEM Ticket Analysis Toolkit

## 1. Contexte

Les equipes support MesVaccins / Colibri traitent des tickets contenant du texte libre, des commentaires, des tags et des metadonnees. Le volume rend l'analyse manuelle longue et difficile a reproduire.

Le projet **SYADEM Ticket Analysis Toolkit** vise a automatiser cette analyse en local, afin de produire une synthese exploitable sans envoyer les donnees vers un service IA externe.

## 2. Objectifs

| Objectif | Description |
|---|---|
| Importer | Charger des tickets depuis un export XML |
| Structurer | Extraire sujet, description, commentaires et champs utiles |
| Analyser | Regrouper les tickets par similarite semantique |
| Expliquer | Produire des titres courts de clusters |
| Mesurer | Calculer silhouette et elbow pour evaluer le clustering |
| Exporter | Fournir un CSV metier et un rapport HTML |
| Deployer | Permettre une execution locale ou Docker |

## 3. Perimetre

### Inclus

- Parsing XML streaming avec schema de mapping.
- Generation d'embeddings via Ollama.
- Clustering KMeans.
- Generation optionnelle des titres de clusters.
- Similarite cosinus et doublons probables.
- Rapport HTML et export CSV.
- BaseX optionnel pour stocker/relire le XML.
- Tests unitaires RSpec.
- Docker Compose.

### Exclu du MVP

- API REST metier en production.
- Authentification utilisateur.
- Interface interactive complete.
- Persistance relationnelle automatique.
- CI/CD complete.

## 4. Parties prenantes

| Partie prenante | Attente |
|---|---|
| Support | Reduire le temps d'analyse des tickets |
| Produit | Identifier les themes recurrents |
| Developpement | Prioriser les corrections techniques |
| Administrateur | Executer le projet de maniere reproductible |
| Jury BTS SIO | Evaluer l'analyse, la conception, la realisation et les tests |

## 5. Contraintes

- Donnees potentiellement sensibles.
- Besoin d'une IA locale.
- Dependances a Ruby, Bundler, Ollama et Docker.
- Performance variable selon la machine.
- Necessite de documenter clairement pour l'examen.

## 6. Indicateurs de succes

| Indicateur | Cible |
|---|---|
| Execution locale | `bundle exec ruby main.rb` fonctionne |
| Tests | `bundle exec rspec` sans echec |
| Rapport | `output/visualisation.html` genere |
| CSV | `output/tickets_summary.csv` exploitable |
| Docker | `docker compose up --build` expose les livrables |
| Documentation | Dossier BTS SIO complet en francais |

## 7. Competences BTS SIO SLAM

Le projet mobilise les competences suivantes:

- analyse et formalisation du besoin;
- conception de donnees et architecture applicative;
- developpement de composants applicatifs;
- tests unitaires et validation;
- deploiement et documentation;
- prise en compte de la securite et de la confidentialite.

