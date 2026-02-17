require 'json'
require 'net/http'
require 'uri'
require_relative 'config'

def format_topic_seconds(seconds)
  total = seconds.to_i
  minutes = total / 60
  secs = total % 60
  minutes.positive? ? format('%02dm %02ds', minutes, secs) : format('%02ds', secs)
end

def request_cluster_topic(prompt, model:, base_url:, open_timeout:, read_timeout:, max_retries:, retry_base_delay:)
  url = URI("#{base_url}/api/generate")
  attempts = 0

  while attempts < max_retries
    attempts += 1

    begin
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      request = Net::HTTP::Post.new(url.request_uri, { 'Content-Type' => 'application/json' })
      request.body = { model: model, prompt: prompt, stream: false }.to_json

      response = http.request(request)
      return response if response.code == '200'

      raise "HTTP #{response.code}" if attempts >= max_retries

      delay = retry_base_delay * (2**(attempts - 1))
      puts "⚠️ Topic HTTP #{response.code}, tentative #{attempts}/#{max_retries} (pause #{format('%.1f', delay)}s)"
      sleep delay
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      raise if attempts >= max_retries

      delay = retry_base_delay * (2**(attempts - 1))
      puts "⚠️ Timeout topic: #{e.class} - tentative #{attempts}/#{max_retries} (pause #{format('%.1f', delay)}s)"
      sleep delay
    end
  end
end

# Génère des titres de topics de clusters via LLM local (Ollama)
# IMPORTANT : modèle local pour topics = OLLAMA_LLM_MODEL (ex: llama3:instruct)
def generate_cluster_topics(clusters, tickets, output_path: AppConfig.cluster_topics_output, sample_size: 10, comments_per_cluster: 5, model: AppConfig.ollama_llm_model, base_url: AppConfig.ollama_base_url, open_timeout: AppConfig.topic_open_timeout, read_timeout: AppConfig.topic_read_timeout, max_retries: AppConfig.topic_max_retries, retry_base_delay: AppConfig.topic_retry_base_delay)
  cluster_to_ids = Hash.new { |h, k| h[k] = [] }

  case clusters
  when String
    clusters_data = JSON.parse(File.read(clusters))
    clusters_data.each { |id, cluster| cluster_to_ids[cluster] << id }
  when Hash
    clusters.each { |id, cluster| cluster_to_ids[cluster] << id }
  else
    raise ArgumentError, 'clusters doit être un Hash ou un chemin de fichier JSON'
  end

  topics = {}
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  processed = 0
  cluster_total = cluster_to_ids.size

  puts "🚀 Topics clusters: #{cluster_total} cluster(s), model=#{model}, read_timeout=#{read_timeout}s, retries=#{max_retries}"

  cluster_to_ids.each do |cluster_id, ids|
    puts "🌀 Cluster #{cluster_id}..."

    selected_ids = if ids.size <= sample_size
      ids.dup
    else
      step = (ids.size.to_f / sample_size).ceil
      ids.each_slice(step).map(&:first)
    end

    comments = []
    selected_ids.each do |nice_id|
      ticket = tickets.find { |t| t[:nice_id] == nice_id }
      next unless ticket

      ticket[:comments].first(comments_per_cluster).each do |comment|
        value = comment[:value].to_s.strip
        comments << value unless value.empty?
      end
    end

    if comments.empty?
      topics[cluster_id] = nil
      next
    end

    prompt = <<~PROMPT
      Tâche : proposer un titre court et englobant pour ce cluster de tickets support.

      Commentaires représentatifs :
      #{comments.first(comments_per_cluster).join("\n\n")}

      Contraintes :
      - 10 mots maximum
      - style clair et opérationnel
      - répondre uniquement par le titre
    PROMPT

    response = request_cluster_topic(
      prompt,
      model: model,
      base_url: base_url,
      open_timeout: open_timeout,
      read_timeout: read_timeout,
      max_retries: max_retries,
      retry_base_delay: retry_base_delay
    )

    if response.code == '200'
      json = JSON.parse(response.body)
      raw = json['response'].to_s.strip
      title = raw.lines.first.to_s.strip[0..120]
      topics[cluster_id] = title.empty? ? nil : title
      puts "✅ Cluster #{cluster_id} : #{topics[cluster_id]}"
    else
      puts "❌ Erreur #{response.code} pour cluster #{cluster_id}"
      topics[cluster_id] = nil
    end
  rescue JSON::ParserError => e
    puts "❌ Réponse LLM invalide pour cluster #{cluster_id}: #{e.message}"
    topics[cluster_id] = nil
  rescue => e
    puts "❌ Erreur topic cluster #{cluster_id}: #{e.class} - #{e.message}"
    topics[cluster_id] = nil
  ensure
    processed += 1
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    rate = processed / [elapsed, 0.001].max
    remaining = cluster_total - processed
    eta = remaining / [rate, 0.001].max
    puts format("📊 Topics progression: %<processed>d/%<total>d | vitesse=%<rate>.2f cluster/s | elapsed=%<elapsed>s | ETA=%<eta>s", processed: processed, total: cluster_total, rate: rate, elapsed: format_topic_seconds(elapsed), eta: format_topic_seconds(eta))
  end

  File.write(output_path, JSON.pretty_generate(topics))
  total_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  puts "📂 Résultats des topics enregistrés dans #{output_path}"
  puts "🏁 Topics clusters terminés en #{format_topic_seconds(total_elapsed)}"
  topics
end

if __FILE__ == $0
  require_relative 'xml_handler'

  clusters_path = AppConfig.clusters_output
  tickets = load_tickets_from_xml(AppConfig.tickets_xml_path)
  generate_cluster_topics(clusters_path, tickets)
end
