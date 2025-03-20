#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

app = window.App ||= {}

app.cockpit = new class
  init: ->
    @dateChanged()

  dateChanged: ->
    $('.filter-elements form[role="filter"]').find('#start_date,#end_date').each ->
      val = $(this).val()
      $(this).datepicker('option', 'disabled', $('#period_shortcut').val())
      $(this).val(val)

$(document).on('change', '#period_shortcut', ->
  app.cockpit.init()
)

$(document).on('turbolinks:load', ->
  app.cockpit.init()
)