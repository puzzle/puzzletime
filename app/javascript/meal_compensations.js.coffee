#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

app = window.App ||= {}

$(document).on('turbolinks:load', ->

  dateFilterChanged = ->
    $('#meal_compensations_filter_form').find('#start_date,#end_date').closest('.form-group')
      .css('visibility', if !$('#period_shortcut').val() then 'visible' else 'hidden')

  $('#period_shortcut').on 'change', (event) -> dateFilterChanged()

  dateFilterChanged()
)
