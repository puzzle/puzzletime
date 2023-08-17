#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

app.orderServices = new class
  init: ->
    @dateFilterChanged()
    @initSelection()
    @selectionChanged()

  dateFilterChanged: ->
    $('#order_services_filter_form').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val())

  initSelection: ->
    $('body.order_services #worktimes')
      .on 'change', '[name="worktime_ids[]"],#all_worktimes', @selectionChanged

  selectionChanged: =>
    $('[data-submit-form="#worktimes"]')
      .prop('hidden', !$('[name="worktime_ids[]"]:checked').length)



$(document).on('ajax:success', '#order_services_filter_form', ->
  app.orderServices.init()
)

$(document).on('turbolinks:load', ->
  app.orderServices.init()
)