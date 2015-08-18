Fabricator(:invoice) do
  order
  billing_address { |attrs| Fabricate(:billing_address, client: attrs[:order].client) }
  work_items(count: 2)
  employees(count: 2)
  billing_date { Date.today }
  period_from { (Date.today - 1.month).at_beginning_of_month }
  period_to { (Date.today - 1.month).at_end_of_month }
end
