
app = window.App ||= {}

prepareModalRequest = (event, xhr, settings) ->
  index = settings.url.indexOf('?')
  if index < 1
    settings.url += '.js'
  else
    settings.url = settings.url.substr(0, index) + '.js' + settings.url.substr(index)

showModal = (event, data, status, xhr) ->
  $this = $(this)
  modal = $($this.data('modal'))
  modal.find('.modal-body').html(data)
  title = $this.data('title')
  if title
    modal.find('.modal-title').html(title)
  modal.attr('data-originator', '#' + $this[0].id)
  modal.data('originator', '#' + $this[0].id)
  modal.modal('show')

processCreatedEntry = (event, data, status, xhr) ->
  data = $.parseJSON(eval(data))
  modal = $(this).closest('.modal')
  originator = $(modal.data('originator'))
  if originator.data('update') == 'selectize'
    addOptionToSelectize(originator, data)
  modal.modal('hide')

addOptionToSelectize = (originator, data) ->
  selectize = $(originator.data('element'))[0].selectize
  idField = originator.data('idField')
  id = if idField then data[idField] else data.id
  selectize.addOption({ value: id, text: data.label })
  selectize.refreshOptions(false)
  selectize.addItem(id)

displayFormWithErrors = (event, xhr, status, error) ->
  $this = $(this)
  $this.closest('.modal-body').html(xhr.responseText)
  event.stopPropagation()


$ ->
  # wire up modal links
  $('body').on('ajax:beforeSend', '[data-modal]', prepareModalRequest)
  $('body').on('ajax:success', '[data-modal]', showModal)

  # wire up forms in modal dialogs
  $('body').on('ajax:success', '.modal form', processCreatedEntry)
  $('body').on('ajax:error', '.modal form', displayFormWithErrors)

  # wire up cancel links in modal dialogs
  $('body').on('click', '.modal .cancel', (event) ->
    $(this).closest('.modal').modal('hide')
    event.preventDefault()
  )