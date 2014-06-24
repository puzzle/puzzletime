# encoding: UTF-8

# == Schema Information
#
# Table name: clients
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  contact   :string(255)
#  shortname :string(4)        not null
#


Fabricator(:client) do
  name { Faker::Company.name }
  shortname { ('A'..'Z').to_a.shuffle.take(4).join }
end
