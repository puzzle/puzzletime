# encoding: utf-8
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
#  country       :string(255)
#  invoicing_key :string
#

class BillingAddress < ActiveRecord::Base

  belongs_to :client
  belongs_to :contact

  has_many :orders, dependent: :nullify
  has_many :invoices

  validates :client_id, :street, :zip_code, :town, :country, presence: true
  validates :invoicing_key, uniqueness: true, allow_blank: true
  validate :assert_contact_belongs_to_client

  protect_if :invoices, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Rechnungen zugeordnet sind'


  # TODO country contains uppercase country code from country_select gem, default from settings

  private

  def assert_contact_belongs_to_client
    if contact_id && client_id && contact.client_id != client_id
      errors.add(:contact_id, 'muss zum gleichen Kunden gehören.')
    end
  end

end
