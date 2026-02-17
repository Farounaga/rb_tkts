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
require 'rumale'
require 'numo/narray'
require_relative 'config'


def compute_inertia(vectors, labels, centers)
  total = 0.0
  labels.each_with_index do |label, i|
    diff = vectors[i, true] - centers[label, true]
    total += (diff * diff).sum
  end
  total.to_f
end

def silhouette_score(vectors, labels)
  n = vectors.shape[0]
  return 0.0 if n <= 1

  clusters = Hash.new { |h, k| h[k] = [] }
  labels.each_with_index { |label, idx| clusters[label] << idx }

  scores = []
  n.times do |i|
    own_label = labels[i]
    own_cluster = clusters[own_label]

    a = if own_cluster.size <= 1
      0.0
    else
      dsum = own_cluster.reject { |j| j == i }.sum do |j|
        diff = vectors[i, true] - vectors[j, true]
        Math.sqrt((diff * diff).sum)
      end
      dsum / (own_cluster.size - 1)
    end

    b = clusters.reject { |lab, _| lab == own_label }.values.map do |idxs|
      next nil if idxs.empty?
      dsum = idxs.sum do |j|
        diff = vectors[i, true] - vectors[j, true]
        Math.sqrt((diff * diff).sum)
      end
      dsum / idxs.size
    end.compact.min

    b ||= 0.0
    denom = [a, b].max
    s = denom.zero? ? 0.0 : ((b - a) / denom)
    scores << s
  end

  (scores.sum / scores.size).to_f
end


def evaluate_clustering_metrics(input_file = AppConfig.embeddings_output, output_file = AppConfig.clustering_metrics_output, k_min: 2, k_max: 12)
  data = JSON.parse(File.read(input_file))
  vectors = Numo::DFloat[*data.map { |e| e['vector'] }]

  scaler = Rumale::Preprocessing::StandardScaler.new
  scaled_vectors = scaler.fit_transform(vectors)

  elbow = []
  (k_min..k_max).each do |k|
    kmeans = Rumale::Clustering::KMeans.new(n_clusters: k, random_seed: 7)
    labels = kmeans.fit_predict(scaled_vectors).to_a
    inertia = compute_inertia(scaled_vectors, labels, kmeans.cluster_centers)
    elbow << { k: k, inertia: inertia.round(6) }
  end

  selected_k = AppConfig.kmeans_k
  kmeans = Rumale::Clustering::KMeans.new(n_clusters: selected_k, random_seed: 7)
  labels = kmeans.fit_predict(scaled_vectors).to_a
  sil = silhouette_score(scaled_vectors, labels)

  report = {
    selected_k: selected_k,
    silhouette_score: sil.round(6),
    elbow: elbow
  }

  File.write(output_file, JSON.pretty_generate(report))
  puts "📏 Métriques clustering sauvegardées dans #{output_file}"
  report
end
