# clusterer.rb

require 'json'
require 'rumale'
require 'numo/narray'
require_relative 'config'
require_relative 'xml_handler'
require_relative 'cluster_topics'

def run_clustering(input_file = AppConfig.embeddings_output, output_file = AppConfig.clusters_output, k = AppConfig.kmeans_k, tickets_xml_path: AppConfig.tickets_xml_path)
  puts "🧠 Chargement des embeddings depuis #{input_file}..."
  data = JSON.parse(File.read(input_file))

  vectors_list = data.map { |e| e['vector'] }
  nice_ids     = data.map { |e| e['nice_id'] }

  vectors = Numo::DFloat[*vectors_list]

  puts '⚙️ Normalisation des données...'
  scaler         = Rumale::Preprocessing::StandardScaler.new
  scaled_vectors = scaler.fit_transform(vectors)

  puts "🔄 Lancement de KMeans (#{k} clusters)..."
  kmeans = Rumale::Clustering::KMeans.new(n_clusters: k, random_seed: 7)
  labels = kmeans.fit_predict(scaled_vectors).to_a

  clusters = labels.each_with_index.map { |label, i| [nice_ids[i], label] }
  clusters = clusters.sort_by { |_, label| label }.to_h

  File.write(output_file, JSON.pretty_generate(clusters))
  puts "💾 Résultats clustering enregistrés dans #{output_file}"

  puts '📂 Génération des thèmes de cluster via LLM local...'
  tickets = load_tickets_from_xml(tickets_xml_path)
  generate_cluster_topics(clusters, tickets, output_path: AppConfig.cluster_topics_output)

  clusters
end
