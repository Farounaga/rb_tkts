# similarity.rb
require 'json'
require_relative 'config'
require_relative 'ml_utils'

# Calcul des tickets similaires via cosinus sur embeddings
# Sortie: liste top-k par ticket + marquage des doublons probables

def generate_similarity_report(
  input_file = AppConfig.embeddings_output,
  output_file = AppConfig.similar_tickets_output,
  top_k: AppConfig.similarity_top_k,
  threshold: AppConfig.similarity_threshold
)
  data = JSON.parse(File.read(input_file))
  ids = data.map { |e| e['nice_id'] }
  vecs = data.map { |e| e['vector'].map(&:to_f) }

  results = {}
  ids.each_with_index do |id, i|
    sims = []
    vec_i = vecs[i]

    ids.each_with_index do |other_id, j|
      next if i == j

      sim = MlUtils.cosine(vec_i, vecs[j])
      sims << {
        nice_id: other_id,
        similarity: sim.round(6),
        probable_duplicate: sim >= threshold
      }
    end

    sims.sort_by! { |h| -h[:similarity] }
    results[id] = sims.first(top_k)
  end

  File.write(output_file, JSON.pretty_generate(results))
  puts "📎 Similarités sauvegardées dans #{output_file}"
  results
end
