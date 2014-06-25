
Fabricator(:employee) do
  firstname { Faker::Name.first_name }
  lastname  { Faker::Name.last_name }
  shortname { ('A'..'Z').to_a.shuffle.take(3).join }
  email     { Faker::Internet.email }
end