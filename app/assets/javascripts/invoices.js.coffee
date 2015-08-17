app = window.App ||= {}

toggleInvoiceFilters = (value) ->
  invoiceFilters = $('#invoice_filters')
  if value == true
    invoiceFilters.hide()
  else
    invoiceFilters.show()

updateTotal = ->
  base_url = $('form.invoice').data('preview-total-path')
  params = $('form.invoice').serialize()
  url = "#{base_url}?#{params}"
  $.getScript(url)



################################################################
# because of turbolinks.jquery, do bind ALL document events here

$(document).on('change', 'form.invoice', (event) ->
  updateTotal()
)

$(document).on('blur', 'input#invoice_period_from, input#invoice_period_to', (event) ->
  updateTotal()
)

$(document).on('change', 'input[name=manual_invoice]', (event) ->
  checked = $(event.target).is(':checked')
  toggleInvoiceFilters(checked)
)


$ ->
  toggleInvoiceFilters($('input[name=manual_invoice]').is(':checked'))

