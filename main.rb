# main.rb
require_relative 'xml_handler'
require_relative 'embedding'
require_relative 'clusterer'
require_relative 'visualisation'


# Chemin vers le fichier XML
file_path = "../mesvaccinshelp-20250211/tickets.xml"

# Chargement des tickets
tickets = load_tickets_from_xml(file_path)

# Exemple d'utilisation :
puts "Importé #{tickets.size} tickets"

first_ticket = tickets.first

# Exemple d'affichage du premier commentaire
if first_ticket[:comments].any?
  puts "\nPremier ticket------------------------------"
  puts "ID : #{first_ticket[:nice_id]}"
  puts "ID de l'auteur : #{first_ticket[:comments].first[:author_id]}"
  puts "Sujet : #{first_ticket[:subject]}"
  puts "Commentaire : #{first_ticket[:comments].first[:value][0..400]}..."  #changer à [0..400] pour limiter l'affichage
  puts "Créé le : #{first_ticket[:comments].first[:created_at]}"
  puts "Entrées de champ : #{first_ticket[:ticket_field_entries].size}"
end

# Après avoir obtenu les documents :
documents = tickets.map do |ticket|
  all_comments = ticket[:comments].map { |c| c[:value] }.join(" ")
end

puts "🧠 Génération des embeddings pour #{documents.size} tickets..."
#generate_embeddings_with_tickets(documents, tickets)
puts "💾 Embeddings sauvegardés dans le fichier embeddings.json"

puts "🧮 Lancement du clustering..."
#run_clustering("embeddings.json", "clusters.json", 10) # source.json output.json k=10
puts "📂 Clustering terminé, résultats sauvegardés dans clusters.json"

# Affichage des resultats
Visualiser.generate_html_report(tickets)