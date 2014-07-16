# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery.ui.datepicker
#= require jquery-ui-datepicker-i18n
#= require jquery.ui.autocomplete
#= require selectize
#= require waypoints
#= require waypoints-sticky
#= require bootstrap/modal
#= require_self
#= require worktimes
#= require week_datepicker
#= require project_autocomplete
#= require planning
#= require turbolinks


app = window.App ||= {}

showModal = (event, data, status, xhr) ->
  $this = $(this)
  modal = $($this.data('modal'))
  modal.find('.modal-body').html(data)
  title = $this.data('title')
  if title
    modal.find('.modal-title').html(title)
  modal.modal('show')

addCreatedEntry = (event, data, status, xhr) ->
  console.log(data)
  # TODO add entry to select (which one???)
  $(this).closest('.modal').modal('hide')

displayErrorMessages = (event, xhr, status, error) ->
  $this = $(this)
  alert = $this.find('#error_explanation')
  if alert.length == 0
    $this.prepend('<div id="error_explanation" class="alert alert-danger"><ul></ul></div>')
    alert = $this.find('#error_explanation')
  alert.html(composeErrorMessage(xhr.responseJSON.errors))
  event.stopPropagation()

composeErrorMessage = (errors) ->
  html = ''
  for attr, messages of errors
    do (attr, messages) ->
      for msg in messages
        do (msg) ->
          html += '<li>' + msg + '</li>'

$ ->
  # wire up date picker
  $('body').on('click', 'input.date, .input-group .glyphicon-calendar', app.datepicker.show)

  # wire up data-dynamic-param
  $('body').on('ajax:beforeSend', '[data-dynamic-params]', (event, xhr, settings) ->
    params = $(this).data('dynamic-params').split(',')
    urlParams = for p in params
      value = $('#' + p.replace('[', '_').replace(']', '')).val() || ''
      encodeURIComponent(p) + "=" + value
    settings.url = settings.url + "&" + urlParams.join('&')
  )

  # wire up toggle links
  $('body').on('click', '[data-toggle]', (event) ->
    id = $(this).data('toggle')
    $('#' + id).slideToggle(200)
    event.preventDefault()
  )

  # wire up autocompletes
  $('[data-autocomplete=project]').each(app.projectAutocomplete)

  # wire up selectize
  $('select.searchable').selectize()

  # wire up modal links
  $('body').on('ajax:success', '[data-modal]', showModal)

  # wire up forms in modal dialogs
  $('body').on('ajax:success', '.modal form[data-type=json]', addCreatedEntry)
  $('body').on('ajax:error', '.modal form[data-type=json]', displayErrorMessages)

  # wire up cancel links in modal dialogs
  $('body').on('click', '.modal .cancel', (event) ->
    $(this).closest('.modal').modal('hide')
    event.preventDefault()
  )

  # change cursor for turbolink requests to give the user a minimal feedback
  $(document).on('page:fetch', ->
    $('body').css( 'cursor', 'wait' ))
  $(document).on('page:change', ->
    $('body').css( 'cursor', 'default' ))

  # show alert if ajax requests fail
  $(document).on('ajax:error', (event, xhr, status, error) ->
    alert('Sorry, something went wrong\n(' + error + ')'))
