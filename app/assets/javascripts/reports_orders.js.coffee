#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

app.reportsOrders = new class
  init: ->
    @dateFilterChanged()

  dateFilterChanged: ->
    $('.order_reports form[role="filter"]').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val())
    if $('#period_shortcut').val()
      $('.order_reports form[role="filter"]').find('#start_date,#end_date').val("")

$(document).on('ajax:success', '.order_reports form[role="filter"]', ->
  app.reportsOrders.init()
)

$(document).on 'turbolinks:load', ->
  app.reportsOrders.init()
