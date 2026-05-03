# 07 - Bilan

## Bilan fonctionnel

Le projet fournit un MVP operationnel pour analyser des tickets support:

- import XML streaming;
- embeddings locaux avec Ollama;
- clustering KMeans;
- generation de titres de clusters;
- metriques elbow et silhouette;
- detection de tickets similaires;
- export CSV;
- rapport HTML;
- deploiement Docker avec frontend, app Ruby/Ollama et BaseX.

## Competences BTS SIO SLAM mises en avant

| Competence | Illustration dans le projet |
|---|---|
| Analyser les besoins | Cahier des charges, user stories, backlog et regles metier |
| Concevoir une solution applicative | MCD, MLD, diagrammes de classes et sequences |
| Realiser une application | Modules Ruby, pipeline, exports, frontend statique |
| Gérer les donnees | Parsing XML, BaseX, schema SQL de reference, fichiers JSON/CSV |
| Tester et valider | Suite RSpec, tests sur cas limites, plan de tests |
| Deployer | Dockerfile, Docker Compose, services separes |
| Documenter | Guides installation, utilisateur, technique et livrables examen |
| Travailler en mode projet | Backlog, priorisation MVP/evolutions, suivi type Trello |

## Points forts

- Donnees support traitees localement, sans dependance obligatoire a un LLM cloud.
- Pipeline configurable par variables d'environnement.
- Lecture XML en streaming adaptee aux gros exports.
- Tests unitaires presents sur les composants importants.
- Sorties lisibles par differents publics: JSON pour technique, CSV pour metier, HTML pour consultation.
- Docker Compose facilite la demonstration en architecture multi-services.

## Limites actuelles

- Pas encore d'API REST metier exposee aux utilisateurs.
- Pas de base relationnelle alimentee automatiquement par le pipeline.
- Interface frontend limitee a un portail statique et au rapport HTML genere.
- Clustering depend du choix manuel de `KMEANS_K`.
- Absence de CI/CD complete dans le depot.
- Les donnees reelles doivent etre anonymisees pour une presentation publique.

## Axes d'amelioration futurs

| Priorite | Amelioration | Benefice |
|---|---|---|
| P1 | Ajouter une API REST pour consulter tickets, clusters, metriques | Ouvrir le projet a un vrai dashboard interactif |
| P1 | Persister les resultats dans PostgreSQL ou SQLite | Historiser les analyses et comparer les runs |
| P1 | Ajouter une interface de filtrage par date, statut, cluster et tag | Faciliter l'analyse support |
| P1 | Ajouter une anonymisation automatique des donnees sensibles | Securiser les demos et exports |
| P2 | Automatiser le choix de `KMEANS_K` avec elbow/silhouette | Ameliorer la qualite des clusters |
| P2 | Ajouter une CI GitHub Actions avec `bundle exec rspec` | Garantir la non-regression |
| P2 | Ajouter des tests d'integration Docker | Valider frontend, app-llm et BaseX ensemble |
| P3 | Ajouter des rapports mensuels automatiques | Industrialiser l'usage support |
| P3 | Ajouter une recherche semantique interactive | Retrouver rapidement les tickets proches |

## Conclusion

Le projet est coherent avec une demarche BTS SIO SLAM: il part d'un besoin metier, propose une architecture technique justifiee, manipule des donnees reelles sous contrainte de confidentialite, inclut des tests et produit des livrables exploitables.

La prochaine etape naturelle serait de transformer le pipeline batch en application complete avec API REST, persistance et interface interactive.

