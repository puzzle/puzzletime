# frozen_string_literal: true

Fabricator(:invoice_flatrate) do
  invoice
  flatrate
  quantity { 1 }
end
