# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery.ui.datepicker
#= require jquery-ui-datepicker-i18n
#= require jquery.ui.autocomplete
#= require waypoints
#= require waypoints-sticky
#= require_self
#= require worktimes
#= require week_datepicker
#= require project_autocomplete
#= require planning
#= require turbolinks


app = window.App ||= {}

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

  # change cursor for turbolink requests to give the user a minimal feedback
  $(document).on('page:fetch', ->
    $('body').css( 'cursor', 'wait' ))
  $(document).on('page:change', ->
    $('body').css( 'cursor', 'default' ))

  # show alert if ajax requests fail
  $(document).on('ajax:error', (event, xhr, status, error) ->
    alert('Sorry, something went wrong\n(' + error + ')'))
