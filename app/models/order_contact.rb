class OrderContact < ActiveRecord::Base

  belongs_to :contact
  belongs_to :order

  validate :assert_contact_from_same_client

  before_validation :create_crm_contact

  scope :list, -> do
    includes(:contact).references(:contact).order('contacts.lastname, contacts.firstname')
  end

  def to_s
    [contact, comment.presence].compact.join(': ')
  end

  private

  def create_crm_contact
    if Crm.instance && contact_id_before_type_cast.to_s.start_with?('crm_')
      crm_key = contact_id_before_type_cast.sub('crm_', '')
      person = Crm.instance.find_person(crm_key)
      build_contact(person.merge(client_id: order.client.id)) if person
    end
  end

  def assert_contact_from_same_client
    if contact.client_id != order.client.id
      errors.add(:contact_id, 'muss zum selben Kunden wie der Auftrag gehören.')
    end
  end

end
