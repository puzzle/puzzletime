renderIconItem = (item, escape) ->
  '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>'

renderStyleItem = (item, escape) ->
  '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>'

loadContactsWithCrm = () ->
  return if $('#order_order_contacts_template').length == 0
  url = $('form[data-contacts-url]').data('contacts-url')
  return unless url

  # TODO: only one request may exist at one point in time, all others have to be aborted!
  # e.g. client is changed quickly serveral times -> every change creates a request ->
  # race conditions
  $.getJSON(url, (data) ->
    original = $('#order_order_contacts_template').html()
    return unless original # probably page was left in the mean time
    modified = original.replace(/<option value="\d+">.*<\/option>/g, '')
    $.each(data, (index, element) ->
      option = '<option value="' + (element.id || 'crm_' + element.crm_key) + '">' +
               element.label + '</option>'
      modified = modified.replace(/<\/select>/, option + '</select>')
    )
    $('#order_order_contacts_template').html(modified)
  )

$ ->
  # new order: once a client is selected, activate the category checkbox
  cwi = $('#client_work_item_id')
  if cwi.length > 0
    cwi[0].selectize.on('change', (element) ->
      $('#category_active').prop('disabled', false)
    )

  # new/edit order: replace contact select with crm entries
  loadContactsWithCrm()

  # order cockpit: change order when choosable order changes.
  $(document).on('change', '#choosable_order_id', ->
    if this.value
      l = window.location.toString()
      window.location = l.replace(/orders\/\d+/, 'orders/' + this.value)
  )

  $(document).on('click', '[data-multi-edit]', (event) ->
     $this = $(this)
     params = $($this.data('multi-edit')).serialize()
     window.location = $this.attr('href') + '?' + params
     event.preventDefault()
  )

  $('#target_scope_icon').selectize({ render: { option: renderIconItem, item: renderIconItem } })
  $('#order_status_style').selectize({ render: { option: renderStyleItem, item: renderStyleItem } })
