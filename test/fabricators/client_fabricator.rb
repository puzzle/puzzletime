# encoding: UTF-8

Fabricator(:client) do
  name { Faker::Company.name }
  shortname { ('A'..'Z').to_a.shuffle.take(4).join }
end
