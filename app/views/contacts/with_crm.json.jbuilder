json.array! @entries do |contact|
  json.id contact.id
  json.label contact.to_s
  json.crm_key contact.crm_key
end
