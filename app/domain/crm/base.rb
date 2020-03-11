#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Crm
  class Base
    # String with the name of the crm key.
    def crm_key_name
      'CRM Key'
    end

    # Plural String with the name of the crm key.
    def crm_key_name_plural
      'CRM Keys'
    end

    # Name of the CRM
    def name
      'CRM'
    end

    # CRM icon to display for links
    def icon
    end

    # CRM Url for the given client
    def client_url(_client)
    end

    # CRM Url for the given contact
    def contact_url(_contact)
    end

    # CRM Url for the given order
    def order_url(_order)
    end

    # Find an order with the given key in the crm
    def find_order(_key)
    end

    # Find all contacts for a given client in the crm
    def find_client_contacts(_client)
      []
    end

    # Find a contact with the given key in the crm
    def find_person(_key)
    end

    # Find people with the given email
    def find_people_by_email(_email)
    end

    # Sync all entities from the crm, discarding local changes.
    def sync_all
    end

    # Sync a single AdditionalCrmOrder
    def sync_additional_order(additional)
    end

    # Whether only orders from the CRM are allowed or also local ones.
    def restrict_local?
      false
    end
  end
end
