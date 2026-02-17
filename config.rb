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

  def tickets_xml_path
    ENV.fetch('TICKETS_XML_PATH', '../mesvaccinshelp-20250211/tickets.xml')
  end

  def embeddings_output
    ENV.fetch('EMBEDDINGS_OUTPUT', 'embeddings.json')
  end

  def clusters_output
    ENV.fetch('CLUSTERS_OUTPUT', 'clusters.json')
  end

  def cluster_topics_output
    ENV.fetch('CLUSTER_TOPICS_OUTPUT', 'cluster_topics.json')
  end

  def similar_tickets_output
    ENV.fetch('SIMILAR_TICKETS_OUTPUT', 'similar_tickets.json')
  end

  def clustering_metrics_output
    ENV.fetch('CLUSTERING_METRICS_OUTPUT', 'clustering_metrics.json')
  end

  def html_report_output
    ENV.fetch('HTML_REPORT_OUTPUT', 'output/visualisation.html')
  end

  # IMPORTANT : modèle local pour vectorisation
  def ollama_embed_model
    ENV.fetch('OLLAMA_EMBED_MODEL', 'mxbai-embed-large')
  end

  # IMPORTANT : modèle local pour nommage/résumé des topics
  def ollama_llm_model
    ENV.fetch('OLLAMA_LLM_MODEL', 'llama3:instruct')
  end

  def ollama_base_url
    ENV.fetch('OLLAMA_BASE_URL', 'http://localhost:11434')
  end

  def kmeans_k
    ENV.fetch('KMEANS_K', '10').to_i
  end

  def embedding_threads
    ENV.fetch('EMBEDDING_THREADS', '4').to_i
  end

  def ollama_open_timeout
    ENV.fetch('OLLAMA_OPEN_TIMEOUT', '5').to_i
  end

  def ollama_read_timeout
    ENV.fetch('OLLAMA_READ_TIMEOUT', '180').to_i
  end

  def ollama_retry_base_delay
    ENV.fetch('OLLAMA_RETRY_BASE_DELAY', '0.5').to_f
  end



  def topic_open_timeout
    ENV.fetch('TOPIC_OPEN_TIMEOUT', ENV.fetch('OLLAMA_OPEN_TIMEOUT', '5')).to_i
  end

  def topic_read_timeout
    ENV.fetch('TOPIC_READ_TIMEOUT', ENV.fetch('OLLAMA_READ_TIMEOUT', '180')).to_i
  end

  def topic_max_retries
    ENV.fetch('TOPIC_MAX_RETRIES', '3').to_i
  end

  def topic_retry_base_delay
    ENV.fetch('TOPIC_RETRY_BASE_DELAY', ENV.fetch('OLLAMA_RETRY_BASE_DELAY', '0.5')).to_f
  end

  def max_tickets
    value = ENV.fetch('MAX_TICKETS', '').to_s.strip
    return nil if value.empty?

    limit = value.to_i
    return nil if limit <= 0

    limit
  end

  def run_embeddings?
    ENV.fetch('RUN_EMBEDDINGS', 'true') == 'true'
  end

  def run_clustering?
    ENV.fetch('RUN_CLUSTERING', 'true') == 'true'
  end

  def run_similarity?
    ENV.fetch('RUN_SIMILARITY', 'true') == 'true'
  end

  def run_clustering_metrics?
    ENV.fetch('RUN_CLUSTERING_METRICS', 'true') == 'true'
  end

  def similarity_top_k
    ENV.fetch('SIMILARITY_TOP_K', '5').to_i
  end

  def similarity_threshold
    ENV.fetch('SIMILARITY_THRESHOLD', '0.80').to_f
  end
end
