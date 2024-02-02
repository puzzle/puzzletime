# frozen_string_literal: true

json.array! @work_items do |item|
  json.id item.id
  json.name item.name
  json.path_shortnames item.path_shortnames
  json.description item.description
  json.path_names item.path_names
  json.billable item.accounting_post&.billable
  json.meal_compensation item.accounting_post&.meal_compensation
end
