# similarity.rb
require 'json'
require 'numo/narray'
require_relative 'config'

# Calcul des tickets similaires via cosinus sur embeddings
# Sortie: liste top-k par ticket + marquage des doublons probables

def cosine_similarity(a, b)
  na = Math.sqrt((a * a).sum)
  nb = Math.sqrt((b * b).sum)
  return 0.0 if na.zero? || nb.zero?
  ((a * b).sum / (na * nb)).to_f
end

def generate_similarity_report(input_file = AppConfig.embeddings_output, output_file = AppConfig.similar_tickets_output, top_k: AppConfig.similarity_top_k, threshold: AppConfig.similarity_threshold)
  data = JSON.parse(File.read(input_file))
  ids = data.map { |e| e['nice_id'] }
  vecs = data.map { |e| Numo::DFloat[*e['vector']] }

  results = {}
  ids.each_with_index do |id, i|
    sims = []
    vec_i = vecs[i]

    ids.each_with_index do |other_id, j|
      next if i == j
      sim = cosine_similarity(vec_i, vecs[j])
      sims << { nice_id: other_id, similarity: sim.round(6), probable_duplicate: sim >= threshold }
    end

    sims.sort_by! { |h| -h[:similarity] }
    results[id] = sims.first(top_k)
  end

  File.write(output_file, JSON.pretty_generate(results))
  puts "📎 Similarités sauvegardées dans #{output_file}"
  results
end
