# clusterer.rb

require 'json'
require 'rumale'
require 'numo/narray'
require_relative 'xml_handler'
require_relative 'cluster_topics'

def run_clustering(input_file = "embeddings.json", output_file = "clusters.json", k = 5)
  puts "🧠 Chargement des embeddings depuis #{input_file}..."
  data = JSON.parse(File.read(input_file))

  vectors_list = data.map { |e| e["vector"] }
  nice_ids     = data.map { |e| e["nice_id"] }

  vectors = Numo::DFloat[*vectors_list]

  puts "⚙️ Normalisation des données..."
  scaler         = Rumale::Preprocessing::StandardScaler.new
  scaled_vectors = scaler.fit_transform(vectors)

  puts "\n🔄 Lancement de KMeans (#{k} clusters)..."
  kmeans = Rumale::Clustering::KMeans.new(n_clusters: k, random_seed: 7)
  labels = kmeans.fit_predict(scaled_vectors).to_a

  # Regrouper et trier par numéro de cluster
  clusters = labels.each_with_index.map { |label, i| [nice_ids[i], label] }
  clusters = clusters.sort_by { |_, label| label }.to_h

  File.write(output_file, JSON.pretty_generate(clusters))
  puts "💾 Résultats enregistrés dans #{output_file}"

  # Génération des thèmes
  puts "📂 Génération des thèmes pour chaque cluster..."
  tickets = load_tickets_from_xml("../mesvaccinshelp-20250211/tickets.xml")
  generate_cluster_topics(clusters, tickets)

  clusters
end
