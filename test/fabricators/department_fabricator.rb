Fabricator(:department) do
  name { Faker::Company.suffix }
  shortname { ('A'..'Z').to_a.shuffle.take(2).join }
end
