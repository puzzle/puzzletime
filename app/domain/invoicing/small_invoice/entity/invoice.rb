#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Invoice < Base
        ENDPOINT = ['receivables', 'invoices'].freeze

        attr_reader :positions

        def initialize(invoice, positions)
          super(invoice)
          @positions = positions
        end

        def self.path(invoicing_key: nil)
          [*ENDPOINT, invoicing_key].compact
        end

        def path
          self.class.path(invoicing_key: entry.invoicing_key)
        end

        def pdf_path
          [*path, 'pdf']
        end

        def to_hash
          {
            number:            entry.reference,
            contact_id:        Integer(entry.billing_address.client.invoicing_key),
            contact_address_id: Integer(entry.billing_address.invoicing_key),
            contact_person_id: entry.billing_address.contact.try(:invoicing_key)&.to_i,
            date:              entry.billing_date,
            due:               entry.due_date,
            period:            entry.period.to_s,
            currency:          Settings.defaults.currency,
            vat_included:      constant(:vat_included),
            language:          constant(:language),

            positions: positions.collect do |p|
              Entity::Position.new(p).to_hash
            end,

            texts: [
              {
                status:            'D', # TODO: do we need other states?
                title:             entry.title,
                conditions:,
                introduction:
              }
            ]

            # totalamount:       entry.total_amount.round(2),
          }
        end

        private

        def conditions
          "Zahlbar innert #{entry.payment_period} Tagen ab Rechnungsdatum."
        end

        def introduction
          string = 'Besten Dank für Ihren Auftrag'
          if entry.contract_reference.present?
            string += "\n\nIhre Referenzinformationen:\n#{entry.contract_reference}"
          end
          string
        end
      end
    end
  end
end
