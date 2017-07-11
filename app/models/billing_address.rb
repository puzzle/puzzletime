# encoding: utf-8
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

class BillingAddress < ActiveRecord::Base

  belongs_to :client
  belongs_to :contact, optional: true

  has_many :orders, dependent: :nullify
  has_many :invoices

  validates_by_schema
  validates :client_id, :street, :zip_code, :town, :country, presence: true
  validates :invoicing_key, uniqueness: true, allow_blank: true
  validates :country, inclusion: ISO3166::Data.codes
  validate :assert_contact_belongs_to_client

  after_initialize :set_default_country

  protect_if :invoices, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Rechnungen zugeordnet sind'

  scope :list, -> { includes(:contact).order(:country, :zip_code, :street) }

  def to_s
    ''
  end

  def country_name
    c = ISO3166::Country.new(country)
    c.translations['de'] || c.name
  end

  private

  def assert_contact_belongs_to_client
    if contact_id && client_id && contact.client_id != client_id
      errors.add(:contact_id, 'muss zum gleichen Kunden gehören.')
    end
  end

  def set_default_country
    self.country ||= 'CH'
  end
end
