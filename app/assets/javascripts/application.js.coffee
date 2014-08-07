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
#= require bootstrap/tooltip
#= require_self
#= require modal_create
#= require worktimes
#= require week_datepicker
#= require work_item_autocomplete
#= require planning
#= require orders
#= require turbolinks


app = window.App ||= {}

toggleEnabled = (element) ->
  enabled = $(element).prop('checked')
  selector = $(element).data('enable')
  $('input' + selector +
    ', select' + selector +
    ', textarea' + selector).prop('disabled', !enabled)
  affected = $(selector)
  if enabled
    affected.removeClass('disabled')
    $.each(affected, (i, e) -> if e.selectize then e.selectize.enable())
  else
    affected.addClass('disabled')
    $.each(affected, (i, e) -> if e.selectize then e.selectize.disable())


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

  # wire up enable links
  $('body').on('click', '[data-enable]', (event) -> toggleEnabled(this))
  $('[data-enable]').each((i, e) -> toggleEnabled(e))

  # wire up autocompletes
  $('[data-autocomplete=work_item]').each(app.workItemAutocomplete)

  # wire up selectize
  $('select.searchable').selectize()

  # wire up direct submit fields
  $('body').on('change', '[data-submit]', (event) ->
    $(this).closest('form').submit()
  )

  # wire up disabled links
  $('body').on('click', 'a.disabled', (event) ->
   event.preventDefault()
   event.stopPropagation()
  )

  # wire up tooltips
  $('body').tooltip({ selector: '[data-toggle=tooltip]', placement: 'top', html: true })

  # change cursor for turbolink requests to give the user a minimal feedback
  $(document).on('page:fetch', ->
    $('body').addClass('loading'))
  $(document).on('page:change', ->
    $('body').removeClass('loading'))

  # show alert if ajax requests fail
  $(document).on('ajax:error', (event, xhr, status, error) ->
    alert('Sorry, something went wrong\n(' + error + ')'))
