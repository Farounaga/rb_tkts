# main.rb
require_relative 'config'
require_relative 'xml_handler'
require_relative 'embedding'
require_relative 'clusterer'
require_relative 'visualisation'

file_path = AppConfig.tickets_xml_path
tickets = load_tickets_from_xml(file_path)
puts "Importé #{tickets.size} tickets depuis #{file_path}"

first_ticket = tickets.first
if first_ticket && first_ticket[:comments].any?
  puts "\nPremier ticket------------------------------"
  puts "ID : #{first_ticket[:nice_id]}"
  puts "ID de l'auteur : #{first_ticket[:comments].first[:author_id]}"
  puts "Sujet : #{first_ticket[:subject]}"
  puts "Commentaire : #{first_ticket[:comments].first[:value].to_s[0..400]}..."
  puts "Créé le : #{first_ticket[:comments].first[:created_at]}"
  puts "Entrées de champ : #{first_ticket[:ticket_field_entries].size}"
end

documents = tickets.map do |ticket|
  parts = []
  parts << ticket[:subject].to_s
  parts << ticket[:description].to_s
  parts << ticket[:comments].map { |c| c[:value].to_s }.join(' ')
  parts.join(' ').strip
end

puts "🧠 Modèle local d'embeddings : #{AppConfig.ollama_embed_model}"
puts "🧾 Modèle local de topics : #{AppConfig.ollama_llm_model}"

if AppConfig.run_embeddings?
  puts "🧠 Génération des embeddings pour #{documents.size} tickets..."
  generate_embeddings_with_tickets(documents, tickets)
else
  puts '⏭️ Étape embeddings désactivée (RUN_EMBEDDINGS=false)'
end

if AppConfig.run_clustering?
  puts '🧮 Lancement du clustering...'
  run_clustering
else
  puts '⏭️ Étape clustering désactivée (RUN_CLUSTERING=false)'
end

Visualiser.generate_html_report(tickets, AppConfig.html_report_output)
