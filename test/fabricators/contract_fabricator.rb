Fabricator(:contract) do
  order
  number { rand(1000000).to_i }
  start_date { Date.today - 1.year }
  end_date { Date.today + 1.year}
end
