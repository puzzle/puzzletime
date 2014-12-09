module Crm
  class Base
    def client_link(client)
    end

    def contact_link(contact)
    end

    def order_link(order)
    end

    def crm_key_label
      'CRM Key'
    end

    def sync_all

    end

    def restrict_local?
      false
    end
  end
end