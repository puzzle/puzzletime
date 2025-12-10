#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Wenn edit -> form id: edit_employment_<id>

$ ->
  $('#new_employment').on 'submit', (event) ->
    vacationDaysInput = $('#employment_vacation_days_per_year')
    vacationDaysValue = vacationDaysInput.val().trim()

    if vacationDaysValue == ''
      confirmation_message = "Möglicherweise ging vergessen die Ferientage pro Jahr einzutragen. Dennoch fortfahren?"

      if not confirm(confirmation_message)
        event.preventDefault()
        vacationDaysInput.focus()
        return false