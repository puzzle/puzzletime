# == Schema Information
#
# Table name: billing_addresses
#
#  id         :integer          not null, primary key
#  client_id  :integer
#  contact_id :integer
#  supplement :string(255)
#  street     :string(255)
#  zip_code   :string(255)
#  town       :string(255)
#  country    :string(255)
#

class BillingAddress < ActiveRecord::Base

  belongs_to :client
  belongs_to :contact

  has_many :orders

  validates :client_id, :street, :zip_code, :town, presence: true

end
