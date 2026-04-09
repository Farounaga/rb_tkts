# 01 - Contexte

## 1.1 Contexte du projet

Le projet **SYADEM Ticket Analysis Toolkit** vise a automatiser l'analyse des tickets de support (MesVaccins / Colibri) pour aider les equipes metier a:
- detecter les problemes recurrents,
- identifier des doublons de tickets,
- prioriser les actions correctives.

Le besoin est ne d'un volume croissant de tickets et d'une analyse manuelle trop couteuse en temps.

## 1.2 Problematique

Comment produire rapidement une vision exploitable des tickets support, sans dependre d'un service cloud externe, tout en gardant une execution reproductible en local?

## 1.3 Objectifs

- Importer et structurer un export XML de tickets.
- Vectoriser le contenu textuel des tickets (embeddings).
- Regrouper automatiquement les tickets par themes (clustering).
- Generer un rapport lisible pour les equipes support et techniques.
- Fournir un socle de documentation et de tests presentable pour l'epreuve BTS SIO.

## 1.4 Cahier des charges (synthese)

### Exigences fonctionnelles

- Charger un fichier XML de tickets.
- Extraire sujet, description, commentaires, metadonnees utiles.
- Generer des embeddings via Ollama en local.
- Realiser un clustering KMeans.
- Generer un titre de cluster (LLM local).
- Produire des metriques de qualite de clustering.
- Identifier les tickets similaires (cosinus top-k).
- Exporter un rapport HTML.

### Exigences non fonctionnelles

- Execution locale (confidentialite des donnees).
- Configuration centralisee via variables d'environnement.
- Reproductibilite des runs (seed fixe pour KMeans).
- Maintenabilite (code module + documentation technique).
- Testabilite (tests unitaires RSpec).

## 1.5 Expression des besoins (utilisateurs)

- **Support N1/N2**: connaitre les themes dominants et pics d'incidents.
- **Equipe produit**: identifier les chantiers prioritaires.
- **Equipe technique**: disposer de donnees structurees pour traiter les causes racines.
- **Encadrement**: obtenir une synthese claire en soutenance et en contexte professionnel.

## 1.6 User stories

1. En tant qu'analyste support, je veux importer un XML pour traiter un lot de tickets sans saisie manuelle.
2. En tant que responsable support, je veux voir des clusters thematiques pour identifier rapidement les sujets majeurs.
3. En tant que developpeur, je veux detecter des tickets similaires pour accelerer le traitement des doublons.
4. En tant que chef de projet, je veux des metriques de qualite pour justifier la pertinence des resultats.
5. En tant qu'examinateur BTS, je veux une documentation structuree de 01 a 07.

## 1.7 Backlog priorise (MVP puis evolution)

| ID | Besoin | Priorite | Statut |
|---|---|---|---|
| US-01 | Import XML streaming | Must | Realise |
| US-02 | Embeddings locaux Ollama | Must | Realise |
| US-03 | Clustering KMeans | Must | Realise |
| US-04 | Rapport HTML | Must | Realise |
| US-05 | Similarite cosinus top-k | Should | Realise |
| US-06 | Metriques elbow/silhouette | Should | Realise |
| US-07 | Dossier BTS complet 01-07 | Must | Realise |
| US-08 | API REST de consultation | Could | A planifier |
| US-09 | Deploiement CI/CD complet | Could | A planifier |

## 1.8 Contraintes

- Donnees potentiellement sensibles: privilegier le local.
- Contraintes materiel selon machine (CPU/RAM, eventuelle VRAM).
- Qualite heterogene des donnees source (XML tickets).
- Delais de projet lies au calendrier BTS SIO.
