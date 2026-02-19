# ollama_bootstrap.rb
require 'json'
require 'net/http'
require 'uri'
require_relative 'config'

module OllamaBootstrap
  module_function

  LOCAL_OLLAMA_HOSTS = ['localhost', '127.0.0.1', '::1'].freeze

  def ensure_ready!(need_llm: true, need_embeddings: true)
    return unless AppConfig.ollama_auto_start?

    uri = URI.parse(AppConfig.ollama_base_url)
    unless LOCAL_OLLAMA_HOSTS.include?(uri.host)
      puts "ℹ️ OLLAMA_BASE_URL pointe vers un serveur distant (#{AppConfig.ollama_base_url}), autostart local ignoré."
      return
    end

    start_server_if_needed(uri)
    pull_missing_models(uri, required_models(need_llm: need_llm, need_embeddings: need_embeddings))
  end

  def required_models(need_llm:, need_embeddings:)
    explicit = AppConfig.ollama_models
    return explicit unless explicit.empty?

    models = []
    models << AppConfig.ollama_embed_model if need_embeddings
    models << AppConfig.ollama_llm_model if need_llm
    models.uniq
  end

  def start_server_if_needed(uri)
    return if server_up?(uri)

    puts '🚀 Ollama non détecté, démarrage automatique de `ollama serve`...'
    spawn('ollama', 'serve', out: $stdout, err: $stderr)

    deadline = Time.now + AppConfig.ollama_start_timeout
    until Time.now > deadline
      return if server_up?(uri)

      sleep 1
    end

    raise 'Impossible de démarrer Ollama automatiquement. Lancez `ollama serve` manuellement.'
  end

  def pull_missing_models(uri, models)
    available = installed_model_names(uri)

    models.each do |model|
      next if available.include?(model)

      puts "📥 Modèle Ollama manquant, téléchargement: #{model}"
      success = system('ollama', 'pull', model)
      raise "Échec du téléchargement du modèle #{model}" unless success
    end
  end

  def installed_model_names(uri)
    data = get_json(uri, '/api/tags')
    Array(data['models']).map { |m| m['name'] }.compact
  rescue StandardError => e
    warn "⚠️ Impossible de lister les modèles installés via API Ollama: #{e.message}"
    []
  end

  def server_up?(uri)
    response = http_get(uri, '/api/tags')
    response.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end

  def get_json(uri, path)
    response = http_get(uri, path)
    raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def http_get(uri, path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = AppConfig.ollama_open_timeout
    http.read_timeout = AppConfig.ollama_read_timeout

    request = Net::HTTP::Get.new(path)
    http.request(request)
  end
end
