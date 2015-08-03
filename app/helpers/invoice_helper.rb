module InvoiceHelper
  def render_address(address)
    simple_format [
        address.client,
        address.contact,
        address.supplement,
        address.street,
        "#{address.zip_code} #{address.town}",
        address.country
    ].select {|field| field.present? }.compact.join("\n")
  end

  def format_invoice_calculated_total_amount(entry)
    formatted_amount = '%.2f' % entry.calculated_total_amount
    content_tag(:span, formatted_amount, id: :total_amount) + ' ' +
        content_tag(:span, Settings.small_invoice.constants.currency)
  end
end