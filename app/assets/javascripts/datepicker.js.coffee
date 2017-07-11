app = window.App ||= {}

# Initializes date pickers on inputs with class .date,
# works as week picker if data-format="week"
app.datepicker = new class
  i18n = ->
    $.datepicker.regional[$('html').attr('lang')]

  formatWeek = (field, dateString) ->
    if field.data('format') == 'week'
      date = $.datepicker.parseDate(i18n().dateFormat, dateString)
      val = $.datepicker.formatDate('yy', date) + ' ' + $.datepicker.iso8601Week(date)
      field.val(val)

  onSelect = (dateString, instance) ->
    formatWeek(instance.input, dateString)
    instance.input.trigger('change')

  options = $.extend({ onSelect: onSelect, showWeek: true }, i18n())

  init: ->
    $('input.date').each((_i, elem) ->
      $(elem).datepicker($.extend({}, options, {
        changeYear: $(elem).data('changeyear')
      })))
    @bindListeners()

  destroy: ->
    $('input.date').datepicker('destroy')
    @bindListeners(true)

  bindListeners: (unbind) ->
    func = if unbind then 'off' else 'on'

    $(document)[func]('click', 'input.date + .input-group-addon', @show)

  show: (event) ->
    field = $(event.target)
    if !field.is('input.date')
      field = field.closest('.input-group').find('.date')
    field.datepicker('show')

$(document).on('turbolinks:load', ->
  app.datepicker.destroy()
  app.datepicker.init()
)