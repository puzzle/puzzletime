# == Schema Information
#
# Table name: contacts
#
#  id            :integer          not null, primary key
#  client_id     :integer          not null
#  lastname      :string(255)
#  firstname     :string(255)
#  function      :string(255)
#  email         :string(255)
#  phone         :string(255)
#  mobile        :string(255)
#  crm_key       :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  invoicing_key :string
#

Fabricator(:contact) do
  client
  lastname { Faker::Name.last_name }
  firstname { Faker::Name.first_name }
end
