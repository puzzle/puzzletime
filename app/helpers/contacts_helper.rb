module ContactsHelper
  def format_contact_crm_key(contact)
    link_to(contact.crm_key, Crm.instance.contact_url(contact), target: :blank) if contact.crm_key?
  end
end
