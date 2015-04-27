# == Schema Information
#
# Table name: order_kinds
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

Fabricator(:order_kind) do
  name { Faker::Hacker.noun }
end
