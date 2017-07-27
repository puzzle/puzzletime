# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module InvoiceHelper
  def render_address(address)
    simple_format [
      address.client,
      address.contact,
      address.supplement,
      address.street,
      "#{address.zip_code} #{address.town}",
      address.country
    ].select(&:present?).compact.join("\n")
  end

  def format_invoice_calculated_total_amount(entry)
    f(entry.calculated_total_amount) + ' ' + Settings.defaults.currency
  end

  def format_billing_date(entry)
    l(entry.billing_date)
  end

  def format_due_date(entry)
    l(entry.due_date)
  end

  def format_invoice_status(invoice)
    Invoice.human_attribute_name(:"statuses.#{invoice.status}") if invoice.status?
  end

end
