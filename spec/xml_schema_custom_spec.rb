require 'tempfile'
require_relative '../xml_handler'

RSpec.describe 'XML parser with custom schema' do
  it 'parses a non-ticket XML structure via custom schema' do
    xml = <<~XML
      <root>
        <entry>
          <id>e-1</id>
          <title>Hello</title>
          <items>
            <item><name>A</name><value>1</value></item>
            <item><name>B</name><value>2</value></item>
          </items>
        </entry>
      </root>
    XML

    schema = {
      root: '/entry',
      fields: {
        external_id: 'id',
        title: 'title'
      },
      collections: {
        elements: {
          xpath: 'items/item',
          fields: {
            name: 'name',
            value: 'value'
          }
        }
      }
    }

    Tempfile.create(['entries', '.xml']) do |f|
      f.write(xml)
      f.flush

      rows = parse_xml_records(f.path, record_tag: 'entry', schema: schema)
      expect(rows.size).to eq(1)
      expect(rows.first[:external_id]).to eq('e-1')
      expect(rows.first[:elements].map { |e| e[:name] }).to eq(%w[A B])
    end
  end

  it 'raises ENOENT for missing files' do
    expect {
      parse_xml_records('/tmp/does-not-exist-xyz.xml', record_tag: 'entry', schema: { fields: {} })
    }.to raise_error(Errno::ENOENT)
  end
end
