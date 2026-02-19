# xml_handler.rb

require 'nokogiri'

TICKET_FIELD_MAPPING = {
  requester_id: 'requester-id',
  submitter_id: 'submitter-id',
  assignee_id: 'assignee-id',
  group_id: 'group-id',
  status_id: 'status-id',
  priority_id: 'priority-id',
  via_id: 'via-id',
  ticket_type_id: 'ticket-type-id',
  created_at: 'created-at',
  updated_at: 'updated-at',
  description: 'description',
  assigned_at: 'assigned-at',
  status_updated_at: 'status-updated-at',
  nice_id: 'nice-id',
  recipient: 'recipient',
  organization_id: 'organization-id',
  due_date: 'due-date',
  initially_assigned_at: 'initially-assigned-at',
  solved_at: 'solved-at',
  resolution_time: 'resolution-time',
  current_tags: 'current-tags',
  current_collaborators: 'current-collaborators',
  updated_by_type_id: 'updated-by-type-id',
  subject: 'subject',
  external_id: 'external-id',
  original_recipient_address: 'original-recipient-address',
  entry_id: 'entry-id',
  latest_agent_comment_added_at: 'latest-agent-comment-added-at',
  latest_public_comment_added_at: 'latest-public-comment-added-at',
  ticket_form_id: 'ticket-form-id',
  brand_id: 'brand-id',
  number_of_incidents: 'number-of-incidents',
  via_reference_id: 'via-reference-id',
  is_public: 'is-public',
  custom_status_id: 'custom-status-id',
  custom_status_updated_at: 'custom-status-updated-at',
  problem_id: 'problem-id',
  has_incidents: 'has-incidents'
}.freeze

COMMENT_FIELD_MAPPING = {
  author_id: 'author-id',
  created_at: 'created-at',
  via_id: 'via-id',
  is_public: 'is-public',
  type: 'type',
  value: 'value'
}.freeze

TICKET_FIELD_ENTRY_MAPPING = {
  ticket_field_id: 'ticket-field-id',
  value: 'value'
}.freeze

DEFAULT_TICKET_SCHEMA = {
  root: '/ticket',
  fields: TICKET_FIELD_MAPPING,
  collections: {
    comments: {
      xpath: 'comments/comment',
      fields: COMMENT_FIELD_MAPPING
    },
    ticket_field_entries: {
      xpath: 'ticket-field-entries/ticket-field-entry',
      fields: TICKET_FIELD_ENTRY_MAPPING
    }
  }
}.freeze

def parse_node_with_schema(node, schema)
  result = map_fields(node, schema.fetch(:fields, {}))

  schema.fetch(:collections, {}).each do |collection_name, collection_schema|
    result[collection_name] = map_collection(node, collection_schema)
  end

  result
end

def map_fields(node, field_mapping)
  field_mapping.each_with_object({}) do |(target_key, xpath), hash|
    hash[target_key] = node.at_xpath(xpath)&.text&.strip
  end
end

def map_collection(node, collection_schema)
  items_xpath = collection_schema.fetch(:xpath)
  fields = collection_schema.fetch(:fields, {})

  node.xpath(items_xpath).map do |child|
    map_fields(child, fields)
  end
end

def parse_xml_records(file_path, record_tag:, schema:, max_records: nil)
  unless File.exist?(file_path)
    raise Errno::ENOENT, "Fichier XML introuvable: #{file_path}. Verifiez TICKETS_XML_PATH dans .env (chemin absolu ou relatif au dossier du projet)."
  end

  records = []
  limit = max_records.to_i.positive? ? max_records.to_i : nil
  root_xpath = schema.fetch(:root, "/#{record_tag}")

  File.open(file_path) do |xml_file|
    reader = Nokogiri::XML::Reader(xml_file)
    reader.each do |node|
      next unless node.name == record_tag && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

      record_doc = Nokogiri::XML(node.outer_xml)
      record_node = record_doc.at_xpath(root_xpath)
      next unless record_node

      records << parse_node_with_schema(record_node, schema)
      break if limit && records.size >= limit
    end
  end

  records
end

def load_tickets_from_xml(file_path, max_tickets: nil, schema: DEFAULT_TICKET_SCHEMA)
  parse_xml_records(
    file_path,
    record_tag: 'ticket',
    schema: schema,
    max_records: max_tickets
  )
end
