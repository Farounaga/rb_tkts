# config.rb
require 'json'

begin
  require 'dotenv'
  Dotenv.load(File.join(__dir__, '.env'))
rescue LoadError
  env_path = File.join(__dir__, '.env')
  if File.exist?(env_path)
    File.foreach(env_path) do |line|
      next if line.strip.empty? || line.lstrip.start_with?('#')
      key, value = line.split('=', 2)
      next unless key && value
      ENV[key.strip] ||= value.strip
    end
  end
end

module AppConfig
  module_function
  # Convention: toute la configuration applicative passe par ce module.
  # Objectif: centraliser les defaults et éviter les lectures ENV dispersées.

  def tickets_xml_path
    fetch_string('TICKETS_XML_PATH', '../mesvaccinshelp-20250211/tickets.xml')
  end

  def embeddings_output
    fetch_string('EMBEDDINGS_OUTPUT', 'embeddings.json')
  end

  def clusters_output
    fetch_string('CLUSTERS_OUTPUT', 'clusters.json')
  end

  def cluster_topics_output
    fetch_string('CLUSTER_TOPICS_OUTPUT', 'cluster_topics.json')
  end

  def similar_tickets_output
    fetch_string('SIMILAR_TICKETS_OUTPUT', 'similar_tickets.json')
  end

  def clustering_metrics_output
    fetch_string('CLUSTERING_METRICS_OUTPUT', 'clustering_metrics.json')
  end

  def html_report_output
    fetch_string('HTML_REPORT_OUTPUT', 'output/visualisation.html')
  end

  def csv_export_output
    fetch_string('CSV_EXPORT_OUTPUT', 'output/tickets_summary.csv')
  end

  def xml_db_enabled?
    fetch_bool('XML_DB_ENABLED', false)
  end

  def xml_db_base_url
    fetch_string('XML_DB_BASE_URL', 'http://xml-db:8984')
  end

  def xml_db_user
    fetch_string('XML_DB_USER', 'admin')
  end

  def xml_db_password
    fetch_string('XML_DB_PASSWORD', 'admin')
  end

  def xml_db_database
    fetch_string('XML_DB_DATABASE', 'ticketsdb')
  end

  def xml_db_resource
    fetch_string('XML_DB_RESOURCE', 'tickets.xml')
  end

  def xml_db_import_on_start?
    fetch_bool('XML_DB_IMPORT_ON_START', true)
  end

  def xml_db_local_cache
    fetch_string('XML_DB_LOCAL_CACHE', 'tmp/tickets_from_xml_db.xml')
  end

  # IMPORTANT : modèle local pour vectorisation
  def ollama_embed_model
    fetch_string('OLLAMA_EMBED_MODEL', 'nomic-embed-text-v2-moe')
  end

  # IMPORTANT : modèle local pour nommage/résumé des topics
  def ollama_llm_model
    fetch_string('OLLAMA_LLM_MODEL', 'llama3.2:1b-instruct')
  end

  def ollama_base_url
    fetch_string('OLLAMA_BASE_URL', 'http://localhost:11434')
  end


  def ollama_models
    fetch_string('OLLAMA_MODELS', '')
       .split(',')
       .map(&:strip)
       .reject(&:empty?)
       .uniq
  end

  def ollama_auto_start?
    fetch_bool('OLLAMA_AUTO_START', true)
  end

  def ollama_start_timeout
    fetch_int('OLLAMA_START_TIMEOUT', 30)
  end


  def ollama_auto_stop?
    fetch_bool('OLLAMA_AUTO_STOP', true)
  end

  def ollama_stop_timeout
    fetch_int('OLLAMA_STOP_TIMEOUT', 10)
  end

  # Si true: on ne casse pas tout le pipeline si Ollama est indisponible.
  def skip_ollama_on_error?
    fetch_bool('SKIP_OLLAMA_ON_ERROR', true)
  end

  def kmeans_k
    fetch_int('KMEANS_K', 10)
  end

  def embedding_threads
    fetch_int('EMBEDDING_THREADS', 4)
  end

  # Limite de taille texte envoyée à l'API embeddings (protection contexte modèle).
  def embedding_max_chars
    fetch_int('EMBEDDING_MAX_CHARS', 12_000)
  end

  def ollama_open_timeout
    fetch_int('OLLAMA_OPEN_TIMEOUT', 5)
  end

  def ollama_read_timeout
    fetch_int('OLLAMA_READ_TIMEOUT', 180)
  end

  def ollama_retry_base_delay
    fetch_float('OLLAMA_RETRY_BASE_DELAY', 0.5)
  end



  def topic_open_timeout
    fetch_int('TOPIC_OPEN_TIMEOUT', ollama_open_timeout)
  end

  def topic_read_timeout
    fetch_int('TOPIC_READ_TIMEOUT', ollama_read_timeout)
  end

  def topic_max_retries
    fetch_int('TOPIC_MAX_RETRIES', 3)
  end

  def topic_retry_base_delay
    fetch_float('TOPIC_RETRY_BASE_DELAY', ollama_retry_base_delay)
  end


  def topic_num_predict
    fetch_int('TOPIC_NUM_PREDICT', 32)
  end

  def topic_temperature
    fetch_float('TOPIC_TEMPERATURE', 0.2)
  end

  def max_tickets
    value = fetch_string('MAX_TICKETS', '').strip
    return nil if value.empty?

    limit = value.to_i
    return nil if limit <= 0

    limit
  end

  def run_embeddings?
    fetch_bool('RUN_EMBEDDINGS', true)
  end

  def run_clustering?
    fetch_bool('RUN_CLUSTERING', true)
  end


  def run_cluster_topics?
    fetch_bool('RUN_CLUSTER_TOPICS', true)
  end

  def run_similarity?
    fetch_bool('RUN_SIMILARITY', true)
  end

  def run_clustering_metrics?
    fetch_bool('RUN_CLUSTERING_METRICS', true)
  end

  def run_export_csv?
    fetch_bool('RUN_EXPORT_CSV', true)
  end

  def similarity_top_k
    fetch_int('SIMILARITY_TOP_K', 5)
  end

  def similarity_threshold
    fetch_float('SIMILARITY_THRESHOLD', 0.80)
  end

  def fetch_string(key, default)
    # Lecture brute de chaîne (utilisé pour chemins, URLs, noms de modèles).
    ENV.fetch(key, default)
  end

  def fetch_bool(key, default)
    # Booléen explicite via "true"/"false" pour rester prévisible en production.
    ENV.fetch(key, default ? 'true' : 'false') == 'true'
  end

  def fetch_int(key, default)
    # Conversion stricte en entier avec fallback déterministe.
    ENV.fetch(key, default.to_s).to_i
  end

  def fetch_float(key, default)
    # Conversion stricte en float (timeouts, seuils de similarité, etc.).
    ENV.fetch(key, default.to_s).to_f
  end
end
