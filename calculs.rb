require 'httparty'
require 'json'
require 'date'

 


module ZendeskAPI
  def self.get_users_by_role(subdomain, email, api_token, role)


    url = "https://#{subdomain}.zendesk.com/api/v2/users.json?role=#{role}"


    response = HTTParty.get(
      url,
      basic_auth: {
        username: email,
        password: api_token
      }
    )

    if response.code == 200
      data = response.parsed_response
      data["users"]
    else
      puts "Error getting #{role}: #{response.code}"
      puts response.body
      []
    end
  end

  def self.get_agents_and_admins(subdomain, email, api_token)
    agents = get_users_by_role(subdomain, email, api_token, 'agent')
    admins = get_users_by_role(subdomain, email, api_token, 'admin')

    # Fusionner et construire un hash name => id
    combined = agents + admins

    # Construire le dictionnaire
    users_hash = {}
    combined.each do |user|
      users_hash[user["name"]] = user["id"]
    end

    users_hash
  end
end














module TicketTagStats
  def self.build_tag_datasets_weekly(tickets)
    tickets_per_week_and_tag = Hash.new { |h, k| h[k] = Hash.new(0) }
    all_week_starts = []

    tickets.each do |ticket|
      next unless ticket[:created_at]
      date = Date.parse(ticket[:created_at]) rescue next
      # Trouver le lundi de la semaine
      week_start = date - (date.wday - 1) % 7
      week_start_str = week_start.strftime("%d-%m-%Y")
      all_week_starts << week_start_str unless all_week_starts.include?(week_start_str)

      tags = (ticket[:current_tags] || "").split(' ')
      tags.each do |tag|
        tickets_per_week_and_tag[week_start_str][tag] += 1
      end
    end

    all_week_starts.sort_by! { |d| Date.strptime(d, "%d-%m-%Y") }

    tags = tickets_per_week_and_tag.values.flat_map(&:keys).uniq

    colors = generate_colors(tags.size)

    datasets = tags.map.with_index do |tag, i|
      {
        label: tag,
        data: all_week_starts.map { |week_start| tickets_per_week_and_tag[week_start][tag] || 0 },
        borderColor: colors[i],
        fill: false,
        hidden: true
      }
    end

    [all_week_starts, datasets]
  end

  def self.generate_colors(n)
    base_colors = [
      '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0',
      '#9966FF', '#FF9F40', '#C9CBCF', '#FF6384',
      '#36A2EB', '#FFCE56', '#8BC34A', '#E91E63',
      '#00BCD4', '#CDDC39', '#FFC107', '#795548',
      '#607D8B', '#F44336', '#3F51B5', '#009688',
      '#FFEB3B', '#673AB7'
    ]
    (0...n).map { |i| base_colors[i % base_colors.size] }
  end
end








if __FILE__ == $0
  puts "Starting test"

  email     = ENV['ZENDESK_EMAIL']
  api_token = ENV['ZENDESK_API_TOKEN']
  subdomain = ENV['ZENDESK_SUBDOMAIN']

  if [email, api_token, subdomain].any? { |v| v.nil? || v.strip.empty? }
    warn "⚠️ Variables d'environnement manquantes : ZENDESK_EMAIL, ZENDESK_API_TOKEN, ZENDESK_SUBDOMAIN"
    exit 1
  end

  add_suffix = ENV.fetch('ZENDESK_ADD_TOKEN_SUFFIX', 'true') != 'false'
  email = add_suffix && !email.end_with?('/token') ? "#{email}/token" : email

  result = ZendeskAPI.get_agents_and_admins(subdomain, email, api_token)

  puts "\nTotal staff: #{result.size}"
  puts result
end
