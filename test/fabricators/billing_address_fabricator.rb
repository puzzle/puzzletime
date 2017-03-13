# == Schema Information
#
# Table name: billing_addresses
#
#  id            :integer          not null, primary key
#  client_id     :integer          not null
#  contact_id    :integer
#  supplement    :string
#  street        :string
#  zip_code      :string
#  town          :string
#  country       :string(2)
#  invoicing_key :string
#

Fabricator(:billing_address) do
  client
  street { Faker::Address.street_address }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
end
