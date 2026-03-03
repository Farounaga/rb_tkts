require 'tempfile'
require_relative '../xml_handler'

RSpec.describe 'XML streaming parser' do
  it 'extracts configured ticket fields and nested collections' do
    xml = <<~XML
      <tickets>
        <ticket>
          <nice-id>1001</nice-id>
          <subject>Sujet A</subject>
          <description>Desc A</description>
          <comments>
            <comment>
              <author-id>42</author-id>
              <value>Texte commentaire</value>
            </comment>
          </comments>
          <ticket-field-entries>
            <ticket-field-entry>
              <ticket-field-id>abc</ticket-field-id>
              <value>oui</value>
            </ticket-field-entry>
          </ticket-field-entries>
        </ticket>
      </tickets>
    XML

    Tempfile.create(['tickets', '.xml']) do |f|
      f.write(xml)
      f.flush

      tickets = load_tickets_from_xml(f.path)
      expect(tickets.size).to eq(1)
      expect(tickets.first[:nice_id]).to eq('1001')
      expect(tickets.first[:comments].first[:author_id]).to eq('42')
      expect(tickets.first[:ticket_field_entries].first[:ticket_field_id]).to eq('abc')
    end
  end

  it 'stops parsing early with max_tickets' do
    xml = "<tickets>" + (1..3).map { |i| "<ticket><nice-id>#{i}</nice-id></ticket>" }.join + "</tickets>"

    Tempfile.create(['tickets', '.xml']) do |f|
      f.write(xml)
      f.flush

      tickets = load_tickets_from_xml(f.path, max_tickets: 2)
      expect(tickets.map { |t| t[:nice_id] }).to eq(%w[1 2])
    end
  end
end
