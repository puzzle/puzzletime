# encoding: utf-8
# == Schema Information
#
# Table name: order_contacts
#
#  false      :integer          not null, primary key
#  contact_id :integer          not null
#  order_id   :integer          not null
#  comment    :string(255)
#


class OrderContact < ActiveRecord::Base

  belongs_to :contact
  belongs_to :order

  validates_by_schema
  validate :assert_contact_from_same_client

  before_validation :create_crm_contact

  scope :list, -> do
    includes(:contact).references(:contact).order('contacts.lastname, contacts.firstname')
  end

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
    if Crm.instance && contact_id_or_crm.to_s.start_with?(Contact::CRM_ID_PREFIX)
      crm_key = contact_id_or_crm.sub(Contact::CRM_ID_PREFIX, '')
      person = Crm.instance.find_person(crm_key)
      self.contact_id = nil
      build_contact(person.merge(client_id: order.client.id)) if person
    end
  end

  def assert_contact_from_same_client
    if contact.client_id != order.client.id
      errors.add(:contact_id, 'muss zum selben Kunden wie der Auftrag gehören.')
    end
  end

end
