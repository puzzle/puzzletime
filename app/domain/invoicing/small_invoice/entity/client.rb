# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  module SmallInvoice
    module Entity
      class Client < Base
        def to_hash
          {
            number: entry.shortname,
            name: entry.name,
            type: constant(:client_type),
            language: constant(:language),
            einvoice_account_id: entry.e_bill_account_key,
            addresses: entry.billing_addresses.list.collect.with_index do |a, i|
              Address.new(a).to_hash.update(primary: i.zero?)
            end,
            contacts: entry.contacts.list.collect.with_index do |c, i|
              # Set primary on the first contact to ensure we always have a
              # primary contact for this client.
              # Clients can only have one primary contact,
              # setting more than one contact to primary will overwrite the
              # existing one.
              # See #20498
              Entity::Contact.new(c).to_hash.update(primary: i.zero?)
            end
          }
        end
      end
    end
  end
end
