#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

app = window.App ||= {}

app.invoices = new class
  init: ->
    @dateChanged()

  dateChanged: ->
    $('#invoice_period_from,#invoice_period_to')
      .datepicker('option', 'disabled', $('#period_shortcut').val())

$(document).on('change', '#invoice_period_from,#invoice_period_to,#period_shortcut', ->
  app.invoices.init()
)

$(document).on('turbolinks:load', ->
  app.invoices.init()
)