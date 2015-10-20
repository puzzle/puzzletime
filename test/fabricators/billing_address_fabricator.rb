# == Schema Information
#
# Table name: billing_addresses
#
#  id            :integer          not null, primary key
#  client_id     :integer          not null
#  contact_id    :integer
#  supplement    :string(255)
#  street        :string(255)
#  zip_code      :string(255)
#  town          :string(255)
#  country       :string(2)
#  invoicing_key :string
#

Fabricator(:billing_address) do
  client
  street { Faker::Address.street_address }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
end
