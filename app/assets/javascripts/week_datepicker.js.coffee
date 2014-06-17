app = window.App ||= {}

app.datepickerI18n = ->
  $.datepicker.regional[$('html').attr('lang')]

app.datepicker = do ->
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

    options = $.extend(options, app.datepickerI18n())
    field.datepicker(options)
    field.datepicker('show')

formatWeek = (field, dateString) ->
  if field.data('format') == 'week'
    date = $.datepicker.parseDate(app.datepickerI18n().dateFormat, dateString)
    val = $.datepicker.formatDate('yy', date) + ' ' + $.datepicker.iso8601Week(date)
    field.val(val)