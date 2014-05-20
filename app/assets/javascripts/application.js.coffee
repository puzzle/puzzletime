# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery.ui.datepicker
#= require jquery-ui-datepicker-i18n
#= require_self
#= require worktime
#= require planning
#= require turbolinks


app = window.App ||= {}

datepickerI18n = ->
  $.datepicker.regional[$('html').attr('lang')]

formatWeek = (field, dateString) ->
  if field.data('format') == 'week'
    date = $.datepicker.parseDate(datepickerI18n().dateFormat, dateString)
    val = $.datepicker.formatDate('yy', date) + ' ' + $.datepicker.iso8601Week(date)
    field.val(val)

datepicker = do ->
  track = (dateString) ->
    formatWeek($(this), dateString)
    $(this).trigger('change')

  show: ->
    field = $(this)
    if field.is('.calendar')
      field = field.parent().siblings('.date')
    options =
      onSelect: track
      showWeek: true

    options = $.extend(options, datepickerI18n())
    field.datepicker(options)
    field.datepicker('show')


$ ->
  # wire up date picker
  $('body').on('click', 'input.date, img.calendar', datepicker.show)

  # wire up data-dynamic-param
  $('body').on('ajax:beforeSend', '[data-dynamic-params]', (event, xhr, settings) ->
    params = $(this).data('dynamic-params').split(',')
    urlParams = for p in params
      value = $('#' + p.replace('[', '_').replace(']', '')).val()
      encodeURIComponent(p) + "=" + value
    settings.url = settings.url + "&" + urlParams.join('&')
  )

  $('body').on('click', '[data-toggle]', (event) ->
    id = $(this).data('toggle')
    $('#' + id).slideToggle(200)
    event.preventDefault()
  )
