Fabricator(:contact) do
  client
  lastname { Faker::Name.last_name }
  firstname { Faker::Name.first_name }
end
