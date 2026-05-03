# Plan de projet agile - SYADEM Ticket Analysis Toolkit

## Methode

Le projet est organise selon une demarche agile legere, adaptee a un contexte BTS SIO SLAM: backlog priorise, increments fonctionnels, tests et documentation continue.

## Roles

| Role agile | Correspondance projet |
|---|---|
| Product Owner | Responsable du besoin support / utilisateur final |
| Scrum Master | Etudiant pilote du projet |
| Developpeur | Etudiant SLAM en charge du code Ruby, tests et documentation |
| Utilisateur metier | Equipe support et responsable support |

## Backlog produit

| ID | Epic | User story | Priorite | Statut |
|---|---|---|---:|---|
| E1 | Import | Importer les tickets XML | Must | Termine |
| E1 | Import | Limiter le volume en demo | Should | Termine |
| E2 | IA locale | Generer embeddings avec Ollama | Must | Termine |
| E2 | IA locale | Generer topics de clusters | Should | Termine |
| E3 | Analyse | Clustering KMeans | Must | Termine |
| E3 | Analyse | Similarites et doublons | Should | Termine |
| E3 | Analyse | Metriques elbow/silhouette | Should | Termine |
| E4 | Restitution | Rapport HTML | Must | Termine |
| E4 | Restitution | Export CSV | Must | Termine |
| E5 | Deploiement | Docker Compose trois services | Should | Termine |
| E6 | Evolution | API REST et dashboard interactif | Could | A planifier |

## Sprints proposes

| Sprint | Objectif | Taches principales | Livrable |
|---|---|---|---|
| Sprint 1 | Socle import | Parsing XML, mapping champs, configuration | Tickets charges en memoire |
| Sprint 2 | Analyse IA | Embeddings, KMeans, topics | JSON analytiques |
| Sprint 3 | Exploitation | Similarite, metriques, CSV, HTML | Rapport et export |
| Sprint 4 | Qualite | Tests RSpec, mode degrade, Docker | Projet reproductible |
| Sprint 5 | Documentation | Dossier BTS SIO, livrables Word | Documentation d'examen |

## Definition of Done

Une fonctionnalite est consideree terminee si:

- elle est presente dans le code;
- elle est configurable si necessaire;
- elle ne casse pas les tests existants;
- elle produit un fichier ou un comportement verifiable;
- elle est documentee dans le README ou les livrables BTS.

## Gestion des risques

| Risque | Probabilite | Impact | Reponse |
|---|---:|---:|---|
| Ollama lent ou indisponible | Moyenne | Fort | Mode degrade, modeles legers, timeouts configurables |
| XML volumineux | Forte | Moyen | Parsing streaming |
| Resultats IA difficiles a interpreter | Moyenne | Moyen | Topics courts, CSV, metriques |
| Environnement Docker instable | Faible | Moyen | Documentation de deploiement |
| Donnees sensibles | Moyenne | Fort | Execution locale, anonymisation conseillee |

## Revue et retrospective

Points positifs:

- progression par increments verifiables;
- separation claire des modules;
- livrables metier et techniques;
- tests unitaires utiles pour la soutenance.

Ameliorations:

- automatiser les tests en CI;
- ajouter une API REST;
- enrichir l'interface utilisateur;
- historiser les runs dans une base.

