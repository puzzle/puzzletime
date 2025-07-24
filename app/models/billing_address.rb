# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: billing_addresses
#
#  id            :integer          not null, primary key
#  country       :string(2)
#  invoicing_key :string
#  street        :string
#  supplement    :string
#  town          :string
#  zip_code      :string
#  client_id     :integer          not null
#  contact_id    :integer
#
# Indexes
#
#  index_billing_addresses_on_client_id   (client_id)
#  index_billing_addresses_on_contact_id  (contact_id)
#
# }}}

class BillingAddress < ApplicationRecord
  protect_if :invoices,
             'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Rechnungen zugeordnet sind'

  belongs_to :client
  belongs_to :contact, optional: true

  has_many :orders, dependent: :nullify
  has_many :invoices

  validates_by_schema
  validates :street, :zip_code, :town, :country, presence: true
  validates :invoicing_key, uniqueness: true, allow_blank: true
  validates :country, inclusion: ISO3166::Data.codes
  validate :assert_contact_belongs_to_client

  after_initialize :set_default_country

  scope :list, (lambda do
    includes(:contact)
      .references(:contact)
      .order(:country, :zip_code, :street, 'contacts.lastname', 'contacts.firstname', :id)
  end)

  def to_s
    ''
  end

  def country_name
    c = ISO3166::Country.new(country)
    c.translations['de'] || c.name
  end

  private

  def assert_contact_belongs_to_client
    return unless contact_id && client_id && contact.client_id != client_id

    errors.add(:contact_id, 'muss zum gleichen Kunden gehören.')
  end

  def set_default_country
    self.country ||= 'CH'
  end
end
