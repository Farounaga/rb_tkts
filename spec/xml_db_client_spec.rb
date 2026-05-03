require_relative '../xml_db_client'

RSpec.describe XmlDbClient do
  describe '.resolve_tickets_xml_path' do
    it 'retourne le fichier local si XML_DB est désactivé' do
      allow(AppConfig).to receive(:xml_db_enabled?).and_return(false)
      local = File.expand_path('../sample_data/tickets_demo_50.xml', __dir__)

      expect(XmlDbClient.resolve_tickets_xml_path(local)).to eq(local)
    end

    it 'retourne le cache local si la lecture base XML réussit' do
      allow(AppConfig).to receive(:xml_db_enabled?).and_return(true)
      allow(AppConfig).to receive(:xml_db_local_cache).and_return('tmp/spec_tickets.xml')
      allow(XmlDbClient).to receive(:fetch_xml_from_db).and_return(true)

      local = File.expand_path('../sample_data/tickets_demo_50.xml', __dir__)
      resolved = XmlDbClient.resolve_tickets_xml_path(local)

      expect(resolved.end_with?('tmp/spec_tickets.xml')).to eq(true)
    end
  end

  describe '.upload_xml_to_db' do
    it 'crée la base XML si le premier import de ressource échoue car la base est absente' do
      xml_file = File.expand_path('../sample_data/tickets_demo_50.xml', __dir__)

      allow(XmlDbClient).to receive(:http_request).and_return(
        Net::HTTPNotFound.new('1.1', '404', 'Not Found'),
        Net::HTTPCreated.new('1.1', '201', 'Created'),
        Net::HTTPCreated.new('1.1', '201', 'Created')
      )

      expect(XmlDbClient.upload_xml_to_db(xml_file)).to eq(true)
      expect(XmlDbClient).to have_received(:http_request).exactly(3).times
    end
  end
end
