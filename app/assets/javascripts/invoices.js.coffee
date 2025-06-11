#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

app = window.App ||= {}

app.invoices = new class
  init: ->
    @dateChanged()

  dateChanged: ->
    $('#invoice_period_from,#invoice_period_to').each ->
      val = $(this).val()
      $(this).datepicker('option', 'disabled', $('#period_shortcut').val())
      if $('#period_shortcut').val()
        $(this).val('')
      else
        $(this).val(val)

$(document).on('change', '#period_shortcut', ->
  app.invoices.init()
)

$(document).on('turbolinks:load', ->
  app.invoices.init()
)