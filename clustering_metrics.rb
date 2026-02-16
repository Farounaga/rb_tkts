# clustering_metrics.rb
require 'json'
require_relative 'config'
require_relative 'ml_utils'

def evaluate_clustering_metrics(input_file = AppConfig.embeddings_output, output_file = AppConfig.clustering_metrics_output, k_min: 2, k_max: 12)
  data = JSON.parse(File.read(input_file))
  vectors = data.map { |e| e['vector'].map(&:to_f) }

  scaled_vectors, = MlUtils.standard_scale(vectors)

  elbow = []
  (k_min..k_max).each do |k|
    next if k > scaled_vectors.size
    km = MlUtils.kmeans(scaled_vectors, k, seed: 7)
    elbow << { k: k, inertia: km[:inertia].round(6) }
  end

  selected_k = [AppConfig.kmeans_k, scaled_vectors.size].min
  km = MlUtils.kmeans(scaled_vectors, selected_k, seed: 7)
  sil = MlUtils.silhouette(scaled_vectors, km[:labels])

  report = {
    selected_k: selected_k,
    silhouette_score: sil.round(6),
    elbow: elbow
  }

  File.write(output_file, JSON.pretty_generate(report))
  puts "📏 Métriques clustering sauvegardées dans #{output_file}"
  report
end
