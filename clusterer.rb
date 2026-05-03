# clusterer.rb

require 'json'
require_relative 'config'
require_relative 'xml_handler'
require_relative 'cluster_topics'
require_relative 'ml_utils'

def run_clustering(
  input_file = AppConfig.embeddings_output,
  output_file = AppConfig.clusters_output,
  k = AppConfig.kmeans_k,
  tickets_xml_path: AppConfig.tickets_xml_path,
  run_topics: AppConfig.run_cluster_topics?
)
  # Lecture des embeddings produits en amont (source de clustering).
  puts "🧠 Chargement des embeddings depuis #{input_file}..."
  data = JSON.parse(File.read(input_file))

  if data.empty?
    warn '⚠️ Aucun embedding disponible: clustering ignoré.'
    File.write(output_file, JSON.pretty_generate({}))
    return {}
  end

  # Conversion en float pour garantir la stabilité numérique des calculs.
  vectors = data.map { |e| e['vector'].map(&:to_f) }
  nice_ids = data.map { |e| e['nice_id'] }

  puts '⚙️ Normalisation des données...'
  scaled_vectors, = MlUtils.standard_scale(vectors)

  # Protection simple: on borne k à la taille du dataset pour éviter un crash inutile.
  selected_k = [k, scaled_vectors.size].min
  puts "🔄 Lancement de KMeans (#{selected_k} clusters)..."
  km = MlUtils.kmeans(scaled_vectors, selected_k, seed: 7)
  labels = km[:labels]

  clusters = labels.each_with_index.map { |label, i| [nice_ids[i], label] }
  clusters = clusters.sort_by { |_, label| label }.to_h

  File.write(output_file, JSON.pretty_generate(clusters))
  puts "💾 Résultats clustering enregistrés dans #{output_file}"

  if run_topics
    puts '📂 Génération des thèmes de cluster via LLM local...'
    tickets = load_tickets_from_xml(tickets_xml_path)
    generate_cluster_topics(clusters, tickets, output_path: AppConfig.cluster_topics_output)
  else
    puts '⏭️ Génération des thèmes de cluster désactivée (RUN_CLUSTER_TOPICS=false)'
  end

  clusters
end
