json.array! @work_items do |work_item|
  json.id work_item.id
  json.name work_item.name
  json.path_shortnames work_item.path_shortnames
  json.description work_item.description
end