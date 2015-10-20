# == Schema Information
#
# Table name: contracts
#
#  id             :integer          not null, primary key
#  number         :string(255)      not null
#  start_date     :date             not null
#  end_date       :date             not null
#  payment_period :integer          not null
#  reference      :text
#  sla            :text
#  notes          :text
#

Fabricator(:contract) do
  order
  number { rand(1000000).to_i }
  start_date { Date.today - 1.year }
  end_date { Date.today + 1.year}
end
