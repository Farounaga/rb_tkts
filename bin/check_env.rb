#!/usr/bin/env ruby
# Vérifie la présence des dépendances Ruby et variables clés.

required_gems = %w[dotenv httparty nokogiri]
missing = []

required_gems.each do |lib|
  begin
    require lib
  rescue LoadError
    missing << lib
  end
end

if missing.any?
  warn "❌ Dépendances Ruby manquantes: #{missing.join(', ')}"
  warn 'Exécutez: bundle install'
  exit 1
end

puts '✅ Toutes les dépendances Ruby sont disponibles.'

required_env = %w[TICKETS_XML_PATH OLLAMA_BASE_URL OLLAMA_EMBED_MODEL OLLAMA_LLM_MODEL]
unset = required_env.select { |k| ENV[k].to_s.strip.empty? }

if unset.any?
  puts "⚠️ Variables ENV non définies (des valeurs par défaut existent peut-être): #{unset.join(', ')}"
else
  puts '✅ Variables d\'environnement principales renseignées.'
end
