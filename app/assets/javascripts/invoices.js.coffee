app = window.App ||= {}

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


