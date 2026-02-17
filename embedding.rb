# embedding.rb

# Génération d'embeddings via Ollama local.
# IMPORTANT : modèle local pour vectorisation = OLLAMA_EMBED_MODEL (ex: mxbai-embed-large)

require 'httparty'
require 'json'
require 'thread'
require 'net/http'
require_relative 'config'


def format_seconds(seconds)
  total = seconds.to_i
  hours = total / 3600
  minutes = (total % 3600) / 60
  secs = total % 60

  if hours.positive?
    format('%02dh %02dm %02ds', hours, minutes, secs)
  elsif minutes.positive?
    format('%02dm %02ds', minutes, secs)
  else
    format('%02ds', secs)
  end
end

def get_embedding(text, model = AppConfig.ollama_embed_model, base_url = AppConfig.ollama_base_url, open_timeout: AppConfig.ollama_open_timeout, read_timeout: AppConfig.ollama_read_timeout)
  url = "#{base_url}/api/embeddings"
  payload = { model: model, prompt: text }

  puts "📩 Envoi au modèle d'embeddings local #{model} : '#{text.to_s[0..100]}...'"
  response = HTTParty.post(
    url,
    body: payload.to_json,
    headers: { 'Content-Type' => 'application/json' },
    open_timeout: open_timeout,
    read_timeout: read_timeout
  )

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
rescue Net::ReadTimeout, Net::OpenTimeout => e
  puts "❌ Timeout embeddings : #{e.class} - #{e.message}"
  nil
rescue => e
  puts "❌ Erreur embeddings : #{e.class} - #{e.message}"
  nil
end

def generate_embeddings_with_tickets(documents, tickets, model = AppConfig.ollama_embed_model, thread_count = AppConfig.embedding_threads, output_file = AppConfig.embeddings_output, max_retries = 3)
  queue = Queue.new
  mutex = Mutex.new
  results = []
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  stats = { processed: 0, success: 0, failed: 0 }

  documents.each_with_index { |_, i| queue << i if tickets[i] && tickets[i][:nice_id] }
  total = queue.size

  puts "🚀 Embeddings: démarrage avec #{thread_count} thread(s), #{total} ticket(s), max_retries=#{max_retries}"

  workers = thread_count.times.map do |worker_idx|
    Thread.new do
      while (idx = (queue.pop(true) rescue nil))
        text = documents[idx].to_s
        ticket = tickets[idx]

        embedding = nil
        retries = 0
        while embedding.nil? && retries < max_retries
          embedding = get_embedding(text, model)
          break if embedding

          retries += 1
          delay = AppConfig.ollama_retry_base_delay * (2**(retries - 1))
          puts "⚠️ Embedding vide, tentative #{retries}/#{max_retries} pour le ticket #{ticket[:nice_id]} (worker=#{worker_idx + 1}, pause #{format('%.1f', delay)}s)"
          sleep delay
        end

        mutex.synchronize do
          stats[:processed] += 1

          if embedding
            results << { nice_id: ticket[:nice_id], vector: embedding }
            stats[:success] += 1
          else
            stats[:failed] += 1
            puts "❌ Embedding abandonné pour ticket #{ticket[:nice_id]} après #{max_retries} tentative(s)"
          end

          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
          rate = stats[:processed] / [elapsed, 0.001].max
          remaining = total - stats[:processed]
          eta_seconds = remaining / [rate, 0.001].max
          percent = total.positive? ? (stats[:processed].to_f / total * 100) : 100.0

          puts format(
            "📊 Progression embeddings: %<processed>d/%<total>d (%<percent>.1f%%) | ✅ %<success>d | ❌ %<failed>d | vitesse=%<rate>.2f ticket/s | elapsed=%<elapsed>s | ETA=%<eta>s",
            processed: stats[:processed],
            total: total,
            percent: percent,
            success: stats[:success],
            failed: stats[:failed],
            rate: rate,
            elapsed: format_seconds(elapsed),
            eta: format_seconds(eta_seconds)
          )
        end
      end
    end
  end

  workers.each(&:join)

  total_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  File.write(output_file, JSON.pretty_generate(results))
  puts "💾 Embeddings sauvegardés dans #{output_file}"
  puts "🏁 Embeddings terminés: #{stats[:success]} succès, #{stats[:failed]} échecs, durée totale #{format_seconds(total_elapsed)}"

  results
end
