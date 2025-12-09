#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

# Initializes date pickers on inputs with class .date,
# works as week picker if data-format="week"
app.datepicker = new class
  i18n = ->
    $.datepicker.regional[$('html').attr('lang')]

  formatWeek = (date) ->
    week = $.datepicker.iso8601Week(date)
    if date.getMonth() + 1 == 12 && Number(week) == 1
      "#{date.getFullYear() + 1} #{week}"
    else
      "#{date.getFullYear()} #{week}"

  onSelect = (dateString, instance) =>
    if instance.input.data('format') == 'week'
      date = $.datepicker.parseDate(i18n().dateFormat, dateString)
      instance.input.val(formatWeek(date))
    instance.input.trigger('change')

  options = $.extend({ onSelect, showWeek: true }, i18n())

  unavailableDates = ($input) ->
    (date) ->
      if $input.hasClass('only-mondays')
        return [date.getDay() == 1, '', 'Bitte wähle einen Montag aus']
      if $input.hasClass('only-fridays')
        return [date.getDay() == 5, '', 'Bitte wähle einen Freitag aus']
      [true, '', '']  # allow all dates by default


  init: ->
    $('input.date').each((_i, elem) ->
      $(elem).datepicker($.extend({}, options, {
        changeYear: $(elem).data('changeyear')
        changeMonth: $(elem).data('changemonth')
        beforeShowDay: unavailableDates($(elem))
      })))
    @bindListeners()

  formatWeek: formatWeek

  bindListeners: (unbind) ->
    func = if unbind then 'off' else 'on'

    $(document)[func]('click', 'input.date + .input-group-addon', @show)

  show: (event) ->
    field = $(event.target)
    if !field.is('input.date')
      field = field.closest('.input-group').find('.date')
    field.datepicker('show')


document.addEventListener "turbolinks:before-cache", ->
  $.datepicker.dpDiv.remove()

  for element in document.querySelectorAll("input.hasDatepicker")
    $(element).datepicker("destroy")

document.addEventListener "turbolinks:before-render", (event) ->
  $.datepicker.dpDiv.appendTo(event.data.newBody)

$(document).on('turbolinks:load', ->
  app.datepicker.init()
)
