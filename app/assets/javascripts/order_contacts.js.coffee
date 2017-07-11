
app = window.App ||= {}

app.loadContactsWithCrm = () ->
  clientId = $('#client_work_item_id').val()

  if clientId.length < 1
    $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled')
    return

  url = $('form[data-contacts-url]').data('contacts-url')
  url = url += '?client_work_item_id=' + clientId

  addButton = $('.add_nested_fields_link[data-association-path=order_order_contacts]')
  addButton.hide().siblings('.spinner').show()

  if @xhr then @xhr.abort()
  @xhr = $.getJSON(url, (data) ->
    replaceContactsWithCrm(data)
    addButton.show().removeClass('disabled').siblings('.spinner').hide()
  )

replaceContactsWithCrm = (data) ->
  original = $('#order_order_contacts_template').html()
  return unless original # probably page was left in the mean time
  modified = original.replace(/<option value=".+">.*<\/option>/g, '')
  data.forEach (element) ->
    option = "<option value=\"#{element.id_or_crm}\">#{element.label}</option>"
    modified = modified.replace(/<\/select>/, option + '</select>')

  $('#order_order_contacts_template').html(modified)



################################################################
# because of turbolinks.jquery, do bind ALL document events here

$(document).on('change', '#new_order #client_work_item_id', app.loadContactsWithCrm)

$(document).on('turbolinks:load', ->
  unless $('#client_work_item_id').val()
    $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled')
)