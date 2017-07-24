module ContactsHelper
  def format_contact_crm_key(contact)
    crm_contact_link(contact, contact.crm_key)
  end
end
