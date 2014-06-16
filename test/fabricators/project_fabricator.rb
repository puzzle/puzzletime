Fabricator(:project) do
  name { Faker::Company.catch_phrase }
  shortname { ('A'..'Z').to_a.shuffle.take(3).join }
  client
  department
end
