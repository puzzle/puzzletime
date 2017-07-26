#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.



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
  modal.data('originator', $this)
  modal.modal('show')

processCreatedEntry = (event, data, status, xhr) ->
  data = $.parseJSON(eval(data))
  modal = $(this).closest('.modal')
  originator = modal.data('originator')
  if originator.data('update') == 'selectize'
    addOptionToSelectize(originator, data)
  else if originator.data('update') == 'element'
    replaceElementModalContent(originator, data)
  modal.modal('hide')

addOptionToSelectize = (originator, data) ->
  selectize = $(originator.data('element'))[0].selectize
  idField = originator.data('idField')
  id = if idField then data[idField] else data.id
  selectize.addOption({ value: id, text: data.label })
  selectize.refreshOptions(false)
  selectize.addItem(id)

replaceElementModalContent = (originator, data) ->
  element = $(originator.data('element'))
  contentField = originator.data('contentField')
  content = if contentField then data[contentField] else data.content
  element.html(content)

displayFormWithErrors = (event, xhr, status, error) ->
  $this = $(this)
  $this.closest('.modal-body').html(xhr.responseText)
  event.stopPropagation()



################################################################
# because of turbolinks.jquery, do bind ALL document events here

# wire up modal links
$(document).on('ajax:beforeSend', '[data-modal]', prepareModalRequest)
$(document).on('ajax:success', '[data-modal]', showModal)

# wire up forms in modal dialogs
$(document).on('ajax:success', '.modal form', processCreatedEntry)
$(document).on('ajax:error', '.modal form', displayFormWithErrors)

# wire up cancel links in modal dialogs
$(document).on('click', '.modal .cancel', (event) ->
  $(this).closest('.modal').modal('hide')
  event.preventDefault()
)
