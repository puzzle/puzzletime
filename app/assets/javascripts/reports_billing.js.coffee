#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

app.reportsBilling = new class
  init: ->
    @dateFilterChanged()

  dateFilterChanged: ->
    $('.billing_reports form[role="filter"]').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val())
    if $('#period_shortcut').val()
      $('.billing_reports form[role="filter"]').find('#start_date,#end_date').val("")

$(document).on('ajax:success', '.billing_reports form[role="filter"]', ->
  app.reportsBilling.init()
)

$(document).on 'turbolinks:load', ->
  app.reportsBilling.init()
