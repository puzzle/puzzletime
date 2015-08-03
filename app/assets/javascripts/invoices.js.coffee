app = window.App ||= {}

$ ->
  toggle_invoice_filters = (value) ->
    invoice_filters = $('#invoice_filters')
    if value == true
      invoice_filters.hide()
    else
      invoice_filters.show()

  $('input[name=manual_invoice]').on 'change', (event) ->
    checked = $(event.target).is(':checked')
    toggle_invoice_filters(checked)

  toggle_invoice_filters($('input[name=manual_invoice]').is(':checked'))


  update_total = ->
    base_url = $('form.invoice').data('preview-total-path')
    params = $('form.invoice').serialize()
    url = "#{base_url}?#{params}"
    update_html = (data) ->
      $("span#total_amount").html(data)
    $.get(url, update_html)


  $('form.invoice').on 'change', (event) ->
    update_total()

