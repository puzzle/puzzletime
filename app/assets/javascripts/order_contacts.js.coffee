
loadContactsWithCrm = () ->
  return if $('#order_order_contacts_template').length == 0
  url = $('form[data-contacts-url]').data('contacts-url')
  return unless url

  addButton = $('.add_nested_fields_link[data-association-path=order_order_contacts]')
  addButton.hide().siblings('.spinner').show()

  if @xhr then @xhr.abort()
  @xhr = $.getJSON(url, (data) ->
    replaceContactsWithCrm(data)
    addButton.show().siblings('.spinner').hide()
  )

replaceContactsWithCrm = (data) ->
  original = $('#order_order_contacts_template').html()
  return unless original # probably page was left in the mean time
  modified = original.replace(/<option value="\d+">.*<\/option>/g, '')
  $.each(data, (index, element) ->
    option = '<option value="' + (element.id || 'crm_' + element.crm_key) + '">' +
             element.label + '</option>'
    modified = modified.replace(/<\/select>/, option + '</select>')
  )
  $('#order_order_contacts_template').html(modified)

$ ->
  # new/edit order: replace contact select with crm entries
  loadContactsWithCrm()
