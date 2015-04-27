# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  style    :string(255)
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#

Fabricator(:order_status) do
  name { Faker::Hacker.ingverb }
  style { 'success' }
  position { Faker::Number.number(2) }
end
