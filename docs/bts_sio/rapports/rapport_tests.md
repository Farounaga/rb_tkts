# Rapport de tests

## Contexte

Ce rapport synthese les executions de tests du projet pour les jalons BTS SIO.

## Campagne actuelle

- Date: 2026-04-09 21:07:29 +02:00
- Environnement: local
- Commande principale: `bundle exec rspec`

## Resultat

- Statut: non executable dans l'etat actuel du poste
- Nombre de tests: non mesure (execution interrompue avant demarrage de RSpec)
- Echecs: non mesure
- Remarques:
  - `bundle exec rspec` echoue avec `Bundler::GemNotFound` (gems manquantes).
  - `bundle install` echoue par timeout reseau vers `https://rubygems.org` (port 443).
  - La campagne est a relancer des que l'acces reseau a rubygems.org est stable.

## Actions

1. Retenter `bundle install`.
2. Relancer `bundle exec rspec`.
3. Mettre a jour ce rapport avec le nombre de tests executes et le resultat final.
