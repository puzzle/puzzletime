#  Copyright (c) 2006-2017, Puzzle ITC GmbH.
#  This file is part of PuzzleTime and licensed under the AGPL v3 or later.

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
      instance.input.val(@formatWeek(date))
    instance.input.trigger('change')

  options = $.extend({ onSelect: @onSelect, showWeek: true }, i18n())

  init: ->
    $('input.date:not(.datepicker-initialized)').each (_i, elem) =>
      $elem = $(elem)
      $elem.datepicker($.extend({}, @options, {
        changeYear: $elem.data('changeyear')
      }))
      $elem.addClass('datepicker-initialized')

    @bindListeners()
    @observe()

  formatWeek: formatWeek

  destroy: ->
    $('input.date.datepicker-initialized').each (_i, elem) =>
      $(elem).datepicker('destroy').removeClass('datepicker-initialized')

    @bindListeners(true)

    if @observer?
      @observer.disconnect()
      @observer = null

  bindListeners: (unbind = false) ->
    func = if unbind then 'off' else 'on'
    $(document)[func]('click', 'input.date + .input-group-addon', @show)

  show: (event) ->
    field = $(event.target)
    unless field.is('input.date')
      field = field.closest('.input-group').find('.date')
    field.datepicker('show')

  observe: ->
    return if @observer?

    @observer = new MutationObserver (mutations) =>
      mutations.forEach (mutation) =>
        mutation.addedNodes.forEach (node) =>
          return unless node.nodeType is 1  # ELEMENT_NODE
          $node = $(node)

          if $node.is('input.date') || $node.find('input.date').length > 0
            @init()  # Will only init uninitialized ones

    @observer.observe(document.body,
      childList: true,
      subtree: true
    )

$(document).on 'turbolinks:load', ->
  app.datepicker.destroy()
  app.datepicker.init()

$(document).on 'turbolinks:before-cache', ->
  app.datepicker.destroy()
