class OrderContact < ActiveRecord::Base
  belongs_to :contact
  belongs_to :order

  before_validation :create_crm_contact

  scope :list, -> do
    includes(:contact).references(:contact).order('contacts.lastname, contacts.firstname')
  end

  def to_s
    [contact, comment.presence].compact.join(': ')
  end

  private

  def create_crm_contact
    if contact_id_before_type_cast.to_s.start_with?('crm_')
      crm_key = contact_id_before_type_cast.sub('crm_', '')
      person = Crm.instance.find_person(crm_key)
      build_contact(person.merge(client_id: order.client.id)) if person
    end
  end

end
