renderIconItem = (item, escape) ->
  '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>'

renderStyleItem = (item, escape) ->
  '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>'

$ ->
  # once a client is selected, activate the category checkbox
  cwi = $('#client_work_item_id')
  if cwi.length > 0
    cwi[0].selectize.on('change', (element) ->
      $('#category_active').prop('disabled', false)
    )

  # change order when choosable order changes.
  $(document).on('change', '#choosable_order_id', ->
    if this.value
      l = window.location.toString()
      window.location = l.replace(/orders\/\d+/, 'orders/' + this.value)
  )

  $(document).on('click', '[data-multi-edit]', (event) ->
     $this = $(this)
     params = $($this.data('multi-edit')).serialize()
     console.log(params)
     window.location = $this.attr('href') + '?' + params
     event.preventDefault()
  )

  $('#target_scope_icon').selectize({ render: { option: renderIconItem, item: renderIconItem } })
  $('#order_status_style').selectize({ render: { option: renderStyleItem, item: renderStyleItem } })

