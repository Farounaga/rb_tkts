#!/usr/bin/env ruby
# encoding: UTF-8

require 'csv'
require 'json'

input  = 'vaccine_centres.csv'
output = 'centre_to_team.json'

mapping = {}

CSV.foreach(input, headers: true, encoding: 'UTF-8') do |row|
  name = row['Nom_Centre_Vaccination']
  team = row['TEAMS_ID']
  mapping[name] = team
end

File.write(output, JSON.pretty_generate(mapping))
puts "Готово: словарь сохранён в #{output}"
