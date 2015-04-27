app = window.App ||= {}

app.datepickerI18n = ->
  $.datepicker.regional[$('html').attr('lang')]

app.datepicker = do ->
  track = (dateString) ->
    formatWeek($(this), dateString)
    $(this).trigger('change')

  showI18n = (field, options) ->
    options = $.extend(options, app.datepickerI18n())
    field.datepicker(options)
    field.datepicker('show')

  show: ->
    field = $(this)
    if field.is('.glyphicon-calendar')
      field = field.closest('.input-group').find('.date')
    options =
      onSelect: track
      showWeek: true

    showI18n(field, options)

formatWeek = (field, dateString) ->
  if field.data('format') == 'week'
    date = $.datepicker.parseDate(app.datepickerI18n().dateFormat, dateString)
    val = $.datepicker.formatDate('yy', date) + ' ' + $.datepicker.iso8601Week(date)
    field.val(val)


# wire up date picker
$(document).on('click', 'input.date, .input-group .glyphicon-calendar', app.datepicker.show)
