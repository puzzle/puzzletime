$(document).on 'turbolinks:load', ->
  $('#expense_kind :selected').each ->
    if this.value != 'project'
      $('#expense_order_id').closest('.form-group').hide()

  $('#expense_kind').change (e) ->
    if $(this).find(':selected')[0].value == 'project'
      $('#expense_order_id').closest('.form-group').show()
    else
      $('#expense_order_id').closest('.form-group').hide()

