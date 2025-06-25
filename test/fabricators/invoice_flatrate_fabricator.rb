# frozen_string_literal: true

Fabricator(:invoice_flatrate) do
  flatrate
  invoice { |attrs| Fabricate(:invoice, order: attrs[:flatrate].accounting_post.order) }
  quantity { 1 }
end
