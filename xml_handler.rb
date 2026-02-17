# xml_handler.rb

require 'nokogiri'

def get_xml_field(node, xpath)
  node.at_xpath(xpath)&.text&.strip
end

def get_xml_collection(node, xpath)
  node.xpath(xpath).map(&:itself)
end

def extract_comments(ticket_node)
  get_xml_collection(ticket_node, "comments/comment").map do |comment|
    {
      author_id: get_xml_field(comment, "author-id"),
      created_at: get_xml_field(comment, "created-at"),
      via_id: get_xml_field(comment, "via-id"),
      is_public: get_xml_field(comment, "is-public"),
      type: get_xml_field(comment, "type"),
      value: get_xml_field(comment, "value")
    }
  end
end

def extract_ticket_fields(ticket_node)
  get_xml_collection(ticket_node, "ticket-field-entries/ticket-field-entry").map do |field|
    {
      ticket_field_id: get_xml_field(field, "ticket-field-id"),
      value: get_xml_field(field, "value")
    }
  end
end

def extract_ticket(ticket_node)
  {
    requester_id: get_xml_field(ticket_node, "requester-id"),
    submitter_id: get_xml_field(ticket_node, "submitter-id"),
    assignee_id: get_xml_field(ticket_node, "assignee-id"),
    group_id: get_xml_field(ticket_node, "group-id"),
    status_id: get_xml_field(ticket_node, "status-id"),
    priority_id: get_xml_field(ticket_node, "priority-id"),
    via_id: get_xml_field(ticket_node, "via-id"),
    ticket_type_id: get_xml_field(ticket_node, "ticket-type-id"),
    created_at: get_xml_field(ticket_node, "created-at"),
    updated_at: get_xml_field(ticket_node, "updated-at"),
    description: get_xml_field(ticket_node, "description"),
    assigned_at: get_xml_field(ticket_node, "assigned-at"),
    status_updated_at: get_xml_field(ticket_node, "status-updated-at"),
    nice_id: get_xml_field(ticket_node, "nice-id"),
    recipient: get_xml_field(ticket_node, "recipient"),
    organization_id: get_xml_field(ticket_node, "organization-id"),
    due_date: get_xml_field(ticket_node, "due-date"),
    initially_assigned_at: get_xml_field(ticket_node, "initially-assigned-at"),
    solved_at: get_xml_field(ticket_node, "solved-at"),
    resolution_time: get_xml_field(ticket_node, "resolution-time"),
    current_tags: get_xml_field(ticket_node, "current-tags"),
    current_collaborators: get_xml_field(ticket_node, "current-collaborators"),
    updated_by_type_id: get_xml_field(ticket_node, "updated-by-type-id"),
    subject: get_xml_field(ticket_node, "subject"),
    external_id: get_xml_field(ticket_node, "external-id"),
    original_recipient_address: get_xml_field(ticket_node, "original-recipient-address"),
    entry_id: get_xml_field(ticket_node, "entry-id"),
    latest_agent_comment_added_at: get_xml_field(ticket_node, "latest-agent-comment-added-at"),
    latest_public_comment_added_at: get_xml_field(ticket_node, "latest-public-comment-added-at"),
    ticket_form_id: get_xml_field(ticket_node, "ticket-form-id"),
    brand_id: get_xml_field(ticket_node, "brand-id"),
    number_of_incidents: get_xml_field(ticket_node, "number-of-incidents"),
    via_reference_id: get_xml_field(ticket_node, "via-reference-id"),
    is_public: get_xml_field(ticket_node, "is-public"),
    custom_status_id: get_xml_field(ticket_node, "custom-status-id"),
    custom_status_updated_at: get_xml_field(ticket_node, "custom-status-updated-at"),
    problem_id: get_xml_field(ticket_node, "problem-id"),
    has_incidents: get_xml_field(ticket_node, "has-incidents"),

    comments: extract_comments(ticket_node),
    ticket_field_entries: extract_ticket_fields(ticket_node)
  }
end

def load_tickets_from_xml(file_path)
  unless File.exist?(file_path)
    raise Errno::ENOENT, "Fichier XML introuvable: #{file_path}. Verifiez TICKETS_XML_PATH dans .env (chemin absolu ou relatif au dossier du projet)."
  end

  xml = Nokogiri::XML(File.read(file_path))
  xml.xpath("//ticket").map do |ticket_node|
    extract_ticket(ticket_node)
  end
end