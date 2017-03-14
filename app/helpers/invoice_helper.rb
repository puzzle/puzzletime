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

  def format_total_billing_amount(entries)
    f(entries
      .select(&:paid?)
      .map(&:calculated_total_amount)
      .reduce(0, :+))
  end

  def format_total_billing_hours(entries)
    f(entries
      .select(&:paid?)
      .map(&:total_hours)
      .reduce(0, :+))
  end
end
