app = window.App ||= {}

$ ->
  handle_book_on_order_radio = (value) ->
    work_item_fields = $('#work_item_fields')
    if value == 'true'
      work_item_fields.hide()
    else
      work_item_fields.show()

  $('input[name=book_on_order]').on 'change', (event) ->
    value = event.target.value.toLowerCase()
    handle_book_on_order_radio(value)

  handle_book_on_order_radio($('input[name=book_on_order]:checked').val())

  updateOfferedTotal = ->
    hours = $('#accounting_post_offered_hours').val()
    rate = $('#accounting_post_offered_rate').val()
    if !!hours && !!rate
      $('#accounting_post_offered_total').val(parseFloat(hours) * parseFloat(rate))

  $hoursPerDay = parseFloat($('[data-hours-per-day]').data('hoursPerDay'))
  $('#accounting_post_offered_hours').on 'keyup', (event) ->
    days = parseFloat($(this).val()) / $hoursPerDay
    $('#accounting_post_offered_days').val(days || '')
    updateOfferedTotal()

  $('#accounting_post_offered_days').on 'keyup', (event) ->
    hours = parseFloat($(this).val()) * $hoursPerDay
    $('#accounting_post_offered_hours').val(hours || '')
    updateOfferedTotal()

  $('#accounting_post_offered_rate').on 'keyup', (event) ->
    updateOfferedTotal()

  $('#accounting_post_offered_total').on 'change', (event) ->
    $('#accounting_post_offered_rate').val("")
