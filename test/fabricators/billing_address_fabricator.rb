Fabricator(:billing_address) do
  client
  street { Faker::Address.street_address }
  zip_code { Faker::Address.zip_code }
  town { Faker::Address.city }
end
