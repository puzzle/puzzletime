Fabricator(:employment_role) do
  name     { "#{Faker::Cat.breed} #{Time.now.to_i}" }
  billable { false }
  level    { false }
end