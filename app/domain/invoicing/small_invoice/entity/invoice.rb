# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    module Entity
      class Invoice < Base
        attr_reader :positions

        def initialize(invoice, positions)
          super(invoice)
          @positions = positions
        end

        def to_hash
          {
            number:            entry.reference,
            client_id:         entry.billing_address.client.invoicing_key,
            client_address_id: entry.billing_address.invoicing_key,
            client_contact_id: entry.billing_address.contact.try(:invoicing_key),
            currency:          Settings.defaults.currency,
            title:             entry.title,
            period:            entry.period.to_s,
            date:              entry.billing_date,
            due:               entry.due_date,
            account_id:        constant(:account_id),
            esr:               bool_constant(:esr),
            esr_singlepage:    bool_constant(:esr_singlepage),
            lsvplus:           bool_constant(:lsvplus),
            dd:                bool_constant(:debit_direct),
            conditions:        conditions,
            introduction:      introduction,
            language:          constant(:language),
            paypal:            bool_constant(:paypal),
            paypal_url:        constant(:paypay_url),
            vat_included:      constant(:vat_included),
            totalamount:       entry.total_amount.round(2),
            positions:         positions.collect do |p|
                                 Invoicing::SmallInvoice::Entity::Position.new(p).to_hash
                               end
          }
        end

        private

        def conditions
          "Zahlbar innert #{entry.payment_period} Tagen ab Rechnungsdatum."
        end

        def introduction
          string = 'Besten Dank für Ihren Auftrag'
          string += "\n\nIhre Referenzinformationen:\n#{entry.contract_reference}" if entry.contract_reference.present?
          string
        end
      end
    end
  end
end
