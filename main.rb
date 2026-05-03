# main.rb
require_relative 'config'
require_relative 'xml_handler'
require_relative 'xml_db_client'
require_relative 'embedding'
require_relative 'clusterer'
require_relative 'clustering_metrics'
require_relative 'similarity'
require_relative 'export_csv'
require_relative 'visualisation'
require_relative 'ollama_bootstrap'

begin
  # Étape 1: extraction XML (source unique des tickets pour le run).
  raw_file_path = AppConfig.tickets_xml_path
  local_file_path = File.expand_path(raw_file_path, __dir__)
  file_path = XmlDbClient.resolve_tickets_xml_path(local_file_path)
  puts "📂 Chargement XML: TICKETS_XML_PATH=#{raw_file_path}"
  puts "📍 Chemin résolu: #{file_path}"
  if AppConfig.max_tickets
    puts "🧪 Mode streaming XML + limite active : MAX_TICKETS=#{AppConfig.max_tickets}"
  end

  tickets = load_tickets_from_xml(file_path, max_tickets: AppConfig.max_tickets)
  puts "Importé #{tickets.size} tickets depuis #{file_path}"

  first_ticket = tickets.first
  if first_ticket && first_ticket[:comments].any?
    puts "\nPremier ticket------------------------------"
    puts "ID : #{first_ticket[:nice_id]}"
    puts "ID de l'auteur : #{first_ticket[:comments].first[:author_id]}"
    puts "Sujet : #{first_ticket[:subject]}"
    puts "Commentaire : #{first_ticket[:comments].first[:value].to_s[0..400]}..."
    puts "Créé le : #{first_ticket[:comments].first[:created_at]}"
    puts "Entrées de champ : #{first_ticket[:ticket_field_entries].size}"
  end

  # Étape 2: construction du texte consolidé par ticket (embedding-ready).
  documents = tickets.map do |ticket|
    parts = []
    parts << ticket[:subject].to_s
    parts << ticket[:description].to_s
    parts << ticket[:comments].map { |c| c[:value].to_s }.join(' ')
    parts.join(' ').strip
  end

  puts "🧠 Modèle local d'embeddings : #{AppConfig.ollama_embed_model}"
  puts "🧾 Modèle local de topics : #{AppConfig.ollama_llm_model}"

  # Flags effectifs pour ce run (peuvent être ajustés en mode dégradé).
  should_run_embeddings = AppConfig.run_embeddings?
  should_run_clustering = AppConfig.run_clustering?
  should_run_cluster_topics = AppConfig.run_cluster_topics?
  should_run_clustering_metrics = AppConfig.run_clustering_metrics?
  should_run_similarity = AppConfig.run_similarity?
  should_run_export_csv = AppConfig.run_export_csv?

  # Les étapes dépendantes d'Ollama doivent pouvoir être désactivées sans casser le pipeline.
  needs_ollama = should_run_embeddings || (should_run_clustering && should_run_cluster_topics)
  if needs_ollama
    begin
      ready = OllamaBootstrap.ensure_ready!(need_llm: should_run_cluster_topics, need_embeddings: should_run_embeddings)
      unless ready
        raise OllamaBootstrap::UnavailableError, 'Serveur Ollama non joignable.'
      end
    rescue StandardError => e
      if AppConfig.skip_ollama_on_error?
        warn "⚠️ Ollama indisponible: #{e.message}"
        warn '⏭️ Les étapes embeddings + topics de clusters sont désactivées pour ce run.'
        should_run_embeddings = false
        should_run_cluster_topics = false
      else
        raise
      end
    end
  end

  # Étape 3: embeddings (dépend d'Ollama).
  if should_run_embeddings
    puts "🧠 Génération des embeddings pour #{documents.size} tickets (threads=#{AppConfig.embedding_threads}, read_timeout=#{AppConfig.ollama_read_timeout}s)..."
    generate_embeddings_with_tickets(documents, tickets)
  else
    puts '⏭️ Étape embeddings désactivée (RUN_EMBEDDINGS=false)'
  end

  # Étape 4: clustering (nécessite embeddings.json).
  if should_run_clustering
    unless File.exist?(AppConfig.embeddings_output)
      warn "⏭️ Clustering ignoré: fichier embeddings introuvable (#{AppConfig.embeddings_output})"
    else
      puts '🧮 Lancement du clustering...'
      run_clustering(run_topics: should_run_cluster_topics)
    end
  else
    puts '⏭️ Étape clustering désactivée (RUN_CLUSTERING=false)'
  end

  # Étape 5: métriques qualité (elbow + silhouette).
  if should_run_clustering_metrics
    unless File.exist?(AppConfig.embeddings_output)
      warn "⏭️ Métriques clustering ignorées: embeddings introuvables (#{AppConfig.embeddings_output})"
    else
      puts '📏 Calcul des métriques de qualité du clustering (elbow + silhouette)...'
      evaluate_clustering_metrics
    end
  else
    puts '⏭️ Métriques clustering désactivées (RUN_CLUSTERING_METRICS=false)'
  end

  # Étape 6: similarité cosinus pour détecter les doublons probables.
  if should_run_similarity
    unless File.exist?(AppConfig.embeddings_output)
      warn "⏭️ Similarité ignorée: embeddings introuvables (#{AppConfig.embeddings_output})"
    else
      puts '🔎 Calcul des tickets similaires (cosinus)...'
      generate_similarity_report
    end
  else
    puts '⏭️ Similarité désactivée (RUN_SIMILARITY=false)'
  end

  # Étape 7: livrable CSV final pour les utilisateurs non techniques.
  if should_run_export_csv
    puts '🧾 Export CSV récapitulatif...'
    export_tickets_summary_csv(tickets)
  else
    puts '⏭️ Export CSV désactivé (RUN_EXPORT_CSV=false)'
  end

  Visualiser.generate_html_report(tickets, AppConfig.html_report_output)
ensure
  OllamaBootstrap.shutdown_if_started!
end
