require 'json'
require 'net/http'
require 'uri'
require_relative 'config'

# Génère des titres de topics de clusters via LLM local (Ollama)
# IMPORTANT : modèle local pour topics = OLLAMA_LLM_MODEL (ex: llama3:instruct)
def generate_cluster_topics(clusters, tickets, output_path: AppConfig.cluster_topics_output, sample_size: 10, comments_per_cluster: 5, model: AppConfig.ollama_llm_model, base_url: AppConfig.ollama_base_url)
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

    url = URI("#{base_url}/api/generate")
    response = Net::HTTP.post(
      url,
      { model: model, prompt: prompt, stream: false }.to_json,
      { 'Content-Type' => 'application/json' }
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
  end

  File.write(output_path, JSON.pretty_generate(topics))
  puts "📂 Résultats des topics enregistrés dans #{output_path}"
  topics
end

if __FILE__ == $0
  require_relative 'xml_handler'

  clusters_path = AppConfig.clusters_output
  tickets = load_tickets_from_xml(AppConfig.tickets_xml_path)
  generate_cluster_topics(clusters_path, tickets)
end
