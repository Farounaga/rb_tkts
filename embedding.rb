# embedding.rb

# utilisé le modèle bge-m3 pour générer des embeddings pour les commentaires de tickets via l'API Ollama
# Assurez-vous de lancer le serveur Ollama avec le modèle chargé :
# ollama serve --model bge-m3

require 'httparty'
require 'json'
require 'thread'

def get_embedding(text, model = "bge-m3")
  url = "http://localhost:11434/api/embeddings"
  payload = { model: model, prompt: text }
  puts "📩 Envoi du texte au modèle #{model} : '#{text[0..100]}...'"
  response = HTTParty.post(url, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
  data = JSON.parse(response.body)
  embedding = data['embedding'] if data.key?('embedding')
  puts "✅ Embedding : #{embedding ? "#{embedding.size}D vecteur" : 'nil'}"
  embedding
end

def generate_embeddings_with_tickets(documents, tickets, model = "bge-m3", thread_count = 8)
  queue = Queue.new
  mutex = Mutex.new
  results = []

  documents.each_with_index { |_, i| queue << i if tickets[i] && tickets[i][:nice_id] }

  workers = thread_count.times.map do
    Thread.new do
      while idx = (queue.pop(true) rescue nil)
        text   = documents[idx]
        ticket = tickets[idx]
        embedding = nil

        loop do
          embedding = get_embedding(text, model)
          break if embedding
          puts "⚠️ Embedding vide, nouvelle tentative pour le ticket #{ticket[:nice_id]}"
          sleep 0.5
        end

        entry = { nice_id: ticket[:nice_id], vector: embedding }
        mutex.synchronize { results << entry }
        puts "✅ Embedding généré pour le ticket #{ticket[:nice_id]} (#{results.size}/#{documents.size})"
        sleep 0.1
      end
    end
  end

  workers.each(&:join)

  File.open("embeddings.json", "w") do |file|
    file.puts("[")
    results.each_with_index do |res, i|
      line = JSON.generate(res)
      comma = i < results.size - 1 ? "," : ""
      file.puts("#{line}#{comma}")
    end
    file.puts("]")
  end

  results
end