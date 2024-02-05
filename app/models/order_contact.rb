# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_contacts
#
#  false      :integer          not null, primary key
#  contact_id :integer          not null
#  order_id   :integer          not null
#  comment    :string
#

class OrderContact < ApplicationRecord
  belongs_to :contact
  belongs_to :order

  validates_by_schema
  validate :assert_contact_from_same_client

  before_validation :create_crm_contact

  scope :list, lambda {
    includes(:contact).references(:contact).order('contacts.lastname, contacts.firstname')
  }

  def to_s
    [contact, comment.presence].compact.join(': ')
  end

  def contact_id_or_crm
    @contact_id_or_crm ||= contact_id
  end

  def contact_id_or_crm=(value)
    self.contact_id = value
    @contact_id_or_crm = value
  end

  private

  def create_crm_contact
    return unless Crm.instance && contact_id_or_crm.to_s.start_with?(Contact::CRM_ID_PREFIX)

    crm_key = contact_id_or_crm.sub(Contact::CRM_ID_PREFIX, '')
    person = Crm.instance.find_person(crm_key)
    self.contact_id = nil
    build_contact(person.merge(client_id: order.client.id)) if person
  end

  def assert_contact_from_same_client
    return unless contact && order && contact.client_id != order.client.id

    errors.add(:contact_id, 'muss zum selben Kunden wie der Auftrag gehören.')
  end
end
