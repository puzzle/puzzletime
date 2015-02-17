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

  $hoursPerDay = parseFloat($('[data-hours-per-day]').data('hoursPerDay'))
  activeSource = null

  updateOfferedValues = ->
    source = $(this).attr('id')

    hours = parseFloat($('#accounting_post_offered_hours').val())
    days = parseFloat($('#accounting_post_offered_days').val())
    rate = parseFloat($('#accounting_post_offered_rate').val())
    total = parseFloat($('#accounting_post_offered_total').val())
    newHours = newDays = null

    if !isNaN(rate) && rate > 0 && (source.endsWith('_total') ||
       source.endsWith('_rate') && activeSource.endsWith('_total'))

      newHours = total / rate
      newDays = hours / $hoursPerDay
    else if !isNaN(hours) && hours > 0 && (source.endsWith('_hours') ||
            source.endsWith('_rate') && activeSource.endsWith('_hours'))

      newDays = hours / $hoursPerDay
      $('#accounting_post_offered_total').val(!isNaN(rate) && rate > 0 && hours * rate || '')
    else if !isNaN(days) && days > 0 && (source.endsWith('_days') ||
            source.endsWith('_rate') && activeSource.endsWith('_days'))

      newHours = days * $hoursPerDay
      $('#accounting_post_offered_total').val(!isNaN(rate) && rate > 0 && newHours * rate || '')

    if newHours isnt null
      $('#accounting_post_offered_hours').val(newHours || '')
    if newDays isnt null
      $('#accounting_post_offered_days').val(newDays || '')

    if !source.endsWith('_rate')
      activeSource = source

  $('#accounting_post_offered_hours, ' +
    '#accounting_post_offered_days, ' +
    '#accounting_post_offered_rate, ' +
    '#accounting_post_offered_total').on 'keyup change', updateOfferedValues
