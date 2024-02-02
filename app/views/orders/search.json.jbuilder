# frozen_string_literal: true

json.array! @orders do |order|
  json.id order.id
  json.name order.name
  json.path_shortnames order.path_shortnames
  json.path_names order.path_names
end
