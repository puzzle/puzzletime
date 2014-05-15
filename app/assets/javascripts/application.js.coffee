# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery
#= require jquery_ujs
#= require jquery.ui.datepicker
#= require jquery-ui-datepicker-i18n
#= require turbolinks
#= require_self



# start selection on previously selected date
datepicker = do ->
  lastDate = null
  track = (updateFunction) ->
    ->
      lastDate = $(this).val()
      $(this).trigger('change')


  show: ->
    field = $(this)
    if field.is('.calendar')
      field = field.parent().siblings('.date')
    options = { dateFormat: field.data('format'), onSelect: track(), showWeek: true }

    options = $.extend(options, $.datepicker.regional[$('html').attr('lang')])
    field.datepicker(options)
    field.datepicker('show')

    if lastDate && field.val() is ""
      field.datepicker('setDate', lastDate)
      field.val('') # user must confirm selection

workDateChanged = () ->
    workDate = $('#worktime_work_date').value;
    employee_id = $('#worktime_employee_id').value;

    #remote_function(:url => { :action => 'existing' },
    #          :method => :get,
    #          :with => "'employee_id=' + employee_id + '&work_date=' + workDate")}


switch_half_day = (day) ->
	document.getElementById(day + '_am').checked = document.getElementById(day).checked
	document.getElementById(day + '_pm').checked = document.getElementById(day).checked

switch_day = (day) ->
	document.getElementById(day).checked = document.getElementById(day + '_am').checked && document.getElementById(day + '_pm').checked


$ ->
  # wire up date picker
  $('body').on('click', 'input.date, img.calendar', datepicker.show)

  # wire up data-dynamic-param
  $('body').on('ajax:beforeSend', '[data-dynamic-param]', (event, xhr, settings) ->
    param = $(this).data('dynamic-param')
    value = $('#' + param.replace('[', '_').replace(']', '')).val()
    settings.url = settings.url + "&" +
                   encodeURIComponent(param) + "=" + value
  )
