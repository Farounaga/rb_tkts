# 05 - Tests

## 5.1 Strategie de test

Le projet applique 3 niveaux:
1. Tests unitaires Ruby (RSpec) pour la logique metier.
2. Tests d'integration legers sur le pipeline (lecture XML + sorties JSON).
3. Smoke test manuel pour verifier la generation du rapport HTML.

## 5.2 Plan de tests

| ID | Type | Objectif | Entree | Resultat attendu |
|---|---|---|---|---|
| T-01 | Unitaire | Verifier le mapping XML ticket | XML de test | Champs extraits conformes |
| T-02 | Unitaire | Verifier les options de config | Variables ENV mockees | Valeurs fallback correctes |
| T-03 | Unitaire | Verifier nettoyage de titre de cluster | Reponses LLM variees | Titre nettoye sans bruit |
| T-04 | Unitaire | Verifier bootstrap Ollama | Etat Ollama simule | Decision de demarrage correcte |
| T-05 | Integration | Run pipeline sur petit dataset | `sample_data/tickets_demo_50.xml` | Fichiers de sortie generes |
| T-06 | Fonctionnel | Consulter rapport HTML | `output/visualisation.html` | Rapport lisible et coherent |

## 5.3 Tests unitaires existants

Les specs presentes dans `spec/` couvrent notamment:
- `xml_handler_spec.rb`
- `xml_schema_custom_spec.rb`
- `config_spec.rb`
- `cluster_topics_spec.rb`
- `cluster_topics_format_spec.rb`
- `ollama_bootstrap_spec.rb`

## 5.4 Commandes de test

```bash
bundle exec rspec
```

Smoke test pipeline:

```bash
bundle exec ruby main.rb
```

## 5.5 Rapports de tests

- Rapport de synthese: [`rapports/rapport_tests.md`](./rapports/rapport_tests.md)
- Le rapport doit etre mis a jour a chaque jalon important (avant demo, avant soutenance, avant livraison).

## 5.6 Critere de validation BTS

- Les tests unitaires passent.
- Les sorties du pipeline sont generees sans erreur bloquante.
- La documentation des tests permet de rejouer la verification.
