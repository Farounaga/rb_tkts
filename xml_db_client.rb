require 'net/http'
require 'uri'
require 'fileutils'
require_relative 'config'

module XmlDbClient
  module_function

  def resolve_tickets_xml_path(local_fallback_path)
    return local_fallback_path unless AppConfig.xml_db_enabled?

    cache_path = File.expand_path(AppConfig.xml_db_local_cache, __dir__)
    FileUtils.mkdir_p(File.dirname(cache_path))

    if fetch_xml_from_db(cache_path)
      puts "🗃️ XML chargé depuis la base NoSQL XML (#{AppConfig.xml_db_base_url})."
      return cache_path
    end

    if AppConfig.xml_db_import_on_start? && File.exist?(local_fallback_path)
      puts "📥 Import initial XML vers la base NoSQL XML: #{local_fallback_path}"
      if upload_xml_to_db(local_fallback_path) && fetch_xml_from_db(cache_path)
        puts '✅ XML importé puis relu depuis la base XML.'
        return cache_path
      end
    end

    warn '⚠️ Base XML indisponible: fallback sur fichier local.'
    local_fallback_path
  rescue StandardError => e
    warn "⚠️ Erreur base XML: #{e.class} - #{e.message}. Fallback fichier local."
    local_fallback_path
  end

  def fetch_xml_from_db(output_path)
    response = http_request(:get, rest_resource_url)
    return false unless response.is_a?(Net::HTTPSuccess)

    File.write(output_path, response.body)
    true
  end

  def upload_xml_to_db(input_path)
    body = File.read(input_path)
    response = http_request(:put, rest_resource_url, body: body, content_type: 'application/xml')
    if response.is_a?(Net::HTTPNotFound)
      create_response = http_request(:put, rest_database_url, body: body, content_type: 'application/xml')
      return false unless create_response.is_a?(Net::HTTPSuccess) || create_response.is_a?(Net::HTTPCreated)

      response = http_request(:put, rest_resource_url, body: body, content_type: 'application/xml')
    end

    response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)
  end

  def rest_resource_url
    base = AppConfig.xml_db_base_url.sub(%r{/*\z}, '')
    "#{base}/rest/#{AppConfig.xml_db_database}/#{AppConfig.xml_db_resource}"
  end

  def rest_database_url
    base = AppConfig.xml_db_base_url.sub(%r{/*\z}, '')
    "#{base}/rest/#{AppConfig.xml_db_database}"
  end

  def http_request(method, url, body: nil, content_type: nil)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = AppConfig.ollama_open_timeout
    http.read_timeout = AppConfig.ollama_read_timeout

    request =
      case method
      when :get then Net::HTTP::Get.new(uri.request_uri)
      when :put then Net::HTTP::Put.new(uri.request_uri)
      else
        raise ArgumentError, "Methode HTTP non supportee: #{method}"
      end

    request.basic_auth(AppConfig.xml_db_user, AppConfig.xml_db_password)
    request['Content-Type'] = content_type if content_type
    request.body = body if body

    http.request(request)
  end
end
