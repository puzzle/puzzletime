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
end