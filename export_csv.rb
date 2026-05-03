require 'csv'
require 'json'
require 'fileutils'
require_relative 'config'

def export_read_json(path, default_value)
  # Fallback silencieux: le CSV doit rester générable même si un fichier analytique manque.
  return default_value unless File.exist?(path)

  JSON.parse(File.read(path))
rescue JSON::ParserError
  default_value
end

def normalize_tags(raw_tags)
  # Uniformise les tags pour un affichage stable dans Excel (séparateur unique).
  raw_tags.to_s
          .split(/[,\s]+/)
          .map(&:strip)
          .reject(&:empty?)
          .uniq
          .join('|')
end

def build_embeddings_index(embeddings_data)
  # Index minimal pour éviter de stocker les vecteurs bruts dans le CSV.
  embeddings_data.each_with_object({}) do |entry, acc|
    id = entry['nice_id'].to_s
    vector = entry['vector'].is_a?(Array) ? entry['vector'] : []
    acc[id] = { dim: vector.size }
  end
end

# Génère un CSV récapitulatif "métier" à partir des sorties JSON du pipeline.
# Le format est volontairement plat pour rester lisible dans Excel/LibreOffice.
def export_tickets_summary_csv(
  tickets,
  output_file = AppConfig.csv_export_output,
  clusters_file: AppConfig.clusters_output,
  topics_file: AppConfig.cluster_topics_output,
  similarity_file: AppConfig.similar_tickets_output,
  metrics_file: AppConfig.clustering_metrics_output,
  embeddings_file: AppConfig.embeddings_output
)
  clusters = export_read_json(clusters_file, {})
  topics = export_read_json(topics_file, {})
  similarities = export_read_json(similarity_file, {})
  metrics = export_read_json(metrics_file, {})
  embeddings_index = build_embeddings_index(export_read_json(embeddings_file, []))

  FileUtils.mkdir_p(File.dirname(output_file))

  headers = [
    'nice_id',
    'subject',
    'created_at',
    'status_id',
    'requester_id',
    'tags',
    'comments_count',
    'cluster_id',
    'cluster_topic',
    'top_similar_ticket',
    'top_similarity',
    'probable_duplicates_count',
    'embedding_dim',
    'selected_k',
    'silhouette_score',
    'elbow_json'
  ]

  CSV.open(output_file, 'wb', col_sep: ';', headers: headers, write_headers: true) do |csv|
    tickets.each do |ticket|
      id = ticket[:nice_id].to_s
      cluster_id = clusters[id]
      cluster_topic = cluster_id.nil? ? '' : topics[cluster_id.to_s].to_s

      # Similarités: on expose un résumé lisible (top 1 + compteur de doublons probables).
      sims = similarities[id].is_a?(Array) ? similarities[id] : []
      top = sims.first
      probable_count = sims.count { |s| s['probable_duplicate'] == true }

      csv << [
        id,
        ticket[:subject].to_s.strip,
        ticket[:created_at].to_s,
        ticket[:status_id].to_s,
        ticket[:requester_id].to_s,
        normalize_tags(ticket[:current_tags]),
        ticket[:comments].is_a?(Array) ? ticket[:comments].size : 0,
        cluster_id,
        cluster_topic,
        top ? top['nice_id'] : '',
        top ? top['similarity'] : '',
        probable_count,
        embeddings_index.dig(id, :dim),
        metrics['selected_k'],
        metrics['silhouette_score'],
        JSON.generate(metrics['elbow'] || [])
      ]
    end
  end

  puts "📄 Export CSV sauvegardé dans #{output_file}"
  output_file
end
