
$ ->
  cwi = $('#client_work_item_id')
  if cwi.length > 0
    cwi[0].selectize.on('change', (element) ->
      $('#category_active').prop('disabled', false)
    )
