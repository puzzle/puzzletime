module Crm
  class Base
    # Fully styled html label for the crm key.
    def crm_key_label
      crm_key_name
    end

    # String with the name of the crm key.
    def crm_key_name
      'CRM Key'
    end

    # CRM Url for the given client
    def client_url(client)
    end

    # CRM Url for the given contact
    def contact_url(contact)
    end

    # CRM Url for the given order
    def order_url(order)
    end

    # Find an order with the given key in the crm
    def find_order(key)
    end

    # Find all contacts for a given client in the crm
    def find_client_contacts(client)
      []
    end

    # Find a contact with the given key in the crm
    def find_person(key)
    end

    # Sync all entities from the crm, discarding local changes.
    def sync_all
    end

    # Whether only orders from the CRM are allowed or also local ones.
    def restrict_local?
      false
    end
  end
end
