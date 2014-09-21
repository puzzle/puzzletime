
# encoding: UTF-8

# == Schema Information
#
# Table name: departments
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(3)        not null
#

Fabricator(:department) do
  name { Faker::Company.suffix }
  shortname { ('A'..'Z').to_a.shuffle.take(2).join }
end
