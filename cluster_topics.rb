require 'json'
require 'net/http'
require 'uri'
require_relative 'xml_handler'

CLUSTERS_PATH = "./clusters.json"
XML_PATH      = "../mesvaccinshelp-20250211/tickets.xml"
OLLAMA_MODEL  = "llama3:instruct"
OLLAMA_URL    = "http://localhost:11434/api/generate"
OUTPUT_PATH   = "cluster_topics.json"
SAMPLE_SIZE   = 10

puts "📥 Chargement des clusters..."
clusters_data = JSON.parse(File.read(CLUSTERS_PATH))

puts "📥 Chargement des tickets XML..."
tickets = load_tickets_from_xml(XML_PATH)

# Regroupe les nice_id par cluster
cluster_to_ids = Hash.new { |h, k| h[k] = [] }
clusters_data.each { |id, cluster| cluster_to_ids[cluster] << id }

topics = {}

cluster_to_ids.each do |cluster_id, ids|
  puts "🌀 Cluster #{cluster_id}..."

  if ids.size <= SAMPLE_SIZE
    selected_ids = ids.dup
  else
    step = (ids.size.to_f / SAMPLE_SIZE).ceil
    # берём каждый step-й элемент
    selected_ids = ids.each_slice(step).map(&:first)
  end

  comments = []

  selected_ids.each do |nice_id|
    ticket = tickets.find { |t| t[:nice_id] == nice_id }
    next unless ticket

    # Берём только первый комментарий, если он есть
    first_comment = ticket[:comments].first
    if first_comment
      value = first_comment[:value].to_s.strip
      comments << value unless value.empty?
    end
  end

  next if comments.empty?

  sample_comments = comments.first(1)

  prompt = <<~PROMPT
    Tâche : Tu dois donner **UN SEUL TITRE GÉNÉRAL** qui résume les commentaires suivants.

    Ces commentaires :
    #{sample_comments.join("\n\n")}

    Donne un titre qui resume le thème général de ces commentaires.
    Le titre doit être englobant, clair et concis, idéalement moins de 10 mots.
    La reponse doit etre **uniquement** en texte brut.
    
  PROMPT

  puts "🔁 Envoi à Llama3..."
  
# Uncomment the following lines to use Ollama API

  response = Net::HTTP.post(
    URI(OLLAMA_URL),
    { model: OLLAMA_MODEL, prompt: prompt, stream: false }.to_json,
    { "Content-Type" => "application/json" }
  )

  if response.code == "200"
    json = JSON.parse(response.body)
    raw = json["response"].strip
    title = raw.lines.first.strip[0..100] # protection contre les pavés
    topics[cluster_id] = title
    puts "✅ Cluster #{cluster_id} : #{title}"
  else
    puts "❌ Erreur #{response.code} pour cluster #{cluster_id}"
    topics[cluster_id] = nil
  end
end


#  Enregistrement des résultats
  File.write(OUTPUT_PATH, JSON.pretty_generate(topics))
  puts "\n📂 Résultats enregistrés dans #{OUTPUT_PATH}"
