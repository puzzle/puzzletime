json.array! @work_items do |item|
  json.id item.id
  json.name item.name
  json.path_shortnames item.path_shortnames
  json.description item.description
  json.billable item.accounting_post.billable
end