json.array! @entries do |contact|
  json.id_or_crm contact.id_or_crm
  json.label contact.to_s
end
