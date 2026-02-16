# embedding.rb

# Génération d'embeddings via Ollama local.
# IMPORTANT : modèle local pour vectorisation = OLLAMA_EMBED_MODEL (ex: mxbai-embed-large)

require 'httparty'
require 'json'
require 'thread'
require_relative 'config'

def get_embedding(text, model = AppConfig.ollama_embed_model, base_url = AppConfig.ollama_base_url)
  url = "#{base_url}/api/embeddings"
  payload = { model: model, prompt: text }

  puts "📩 Envoi au modèle d'embeddings local #{model} : '#{text.to_s[0..100]}...'"
  response = HTTParty.post(url, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })

  unless response.code == 200
    puts "❌ Erreur Ollama embeddings (HTTP #{response.code})"
    return nil
  end

  data = JSON.parse(response.body)
  embedding = data['embedding'] if data.key?('embedding')
  puts "✅ Embedding : #{embedding ? "#{embedding.size}D vecteur" : 'nil'}"
  embedding
rescue JSON::ParserError => e
  puts "❌ Réponse embeddings invalide : #{e.message}"
  nil
rescue => e
  puts "❌ Erreur embeddings : #{e.class} - #{e.message}"
  nil
end

def generate_embeddings_with_tickets(documents, tickets, model = AppConfig.ollama_embed_model, thread_count = AppConfig.embedding_threads, output_file = AppConfig.embeddings_output, max_retries = 3)
  queue = Queue.new
  mutex = Mutex.new
  results = []

  documents.each_with_index { |_, i| queue << i if tickets[i] && tickets[i][:nice_id] }

  workers = thread_count.times.map do
    Thread.new do
      while (idx = (queue.pop(true) rescue nil))
        text   = documents[idx].to_s
        ticket = tickets[idx]

        embedding = nil
        retries = 0
        while embedding.nil? && retries < max_retries
          embedding = get_embedding(text, model)
          break if embedding
          retries += 1
          puts "⚠️ Embedding vide, tentative #{retries}/#{max_retries} pour le ticket #{ticket[:nice_id]}"
          sleep 0.4
        end

        next unless embedding

        entry = { nice_id: ticket[:nice_id], vector: embedding }
        mutex.synchronize { results << entry }
        puts "✅ Embedding généré pour le ticket #{ticket[:nice_id]} (#{results.size}/#{documents.size})"
      end
    end
  end

  workers.each(&:join)

  File.write(output_file, JSON.pretty_generate(results))
  puts "💾 Embeddings sauvegardés dans #{output_file}"

  results
end
