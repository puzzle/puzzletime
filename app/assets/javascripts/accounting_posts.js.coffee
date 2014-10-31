$ ->
  $('input[name=book_on_order]').on 'change', (event) ->
    value = event.target.value.toLowerCase()
    work_item_fields = $('#work_item_fields')
    if value == 'true'
      work_item_fields.hide()
    else
      work_item_fields.show()

  if $('input[name=book_on_order]:checked').val() == 'true'
    $('#work_item_fields').hide()
