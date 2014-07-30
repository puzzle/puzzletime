Fabricator(:order_status) do
  name { Faker::Hacker.ingverb }
  style { 'success' }
  position { Faker::Number.number(2) }
end
