renderIconItem = (item, escape) ->
  '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>'

renderStyleItem = (item, escape) ->
  '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>'



################################################################
# because of turbolinks.jquery, do bind ALL document events here

# order cockpit: change order when choosable order changes.
$(document).on('change', '#choosable_order_id', ->
  if this.value
    l = window.location.toString()
    window.location = l.replace(/orders\/\d+/, 'orders/' + this.value)
)

$(document).on('click', '[data-submit-form]', (event) ->
  form_id = $(this).attr('data-submit-form')
  $(form_id).submit()
  event.preventDefault()
)

$ ->
  # new order: once a client is selected, activate the category checkbox
  cwi = $('#client_work_item_id')
  if cwi.length > 0 && cwi[0].selectize
    cwi[0].selectize.on('change', (element) ->
      $('#category_active').prop('disabled', false)
    )

  $('#target_scope_icon').selectize({ render: { option: renderIconItem, item: renderIconItem } })
  $('#order_status_style').selectize({ render: { option: renderStyleItem, item: renderStyleItem } })
