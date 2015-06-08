module Invoicing
  module SmallInvoice
    module Entity
      class Invoice < Base
        def to_hash
          {
            number:            entry.reference,
            client_id:         entry.order.client.invoicing_key,
            client_address_id: entry.billing_address.invoicing_key,
            client_contact_id: entry.billing_address.contact.try(:invoicing_key),
            currency:          constant(:currency),
            title:             entry.title,
            period:            entry.period,
            date:              entry.billing_date,
            due:               entry.due_date,
            account_id:        constant(:account_id),
            esr:               bool_constant(:esr),
            esr_number:        constant(:esr_number),
            esr_singlepage:    bool_constant(:esr_singlepage),
            lsvplus:           bool_constant(:lsvplus),
            dd:                bool_constant(:debit_direct),
            conditions:        conditions,
            introduction:      introduction,
            language:          constant(:language),
            paypal:            bool_constant(:paypal),
            paypal_url:        constant(:paypay_url),
            vat_included:      !entry.add_vat ? 1 : 0,
            totalamount:       entry.total_amount,
            positions:         []
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
