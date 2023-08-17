#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

# Opens the url template from the table's data-row-link with the current row id.
class app.LinkedTableRow
  constructor: (cell) ->
    @row = $(cell).closest('tr')

    @url = ->
      @urlTemplate().replace('/:id/', '/' + @rowId() + '/')

    @urlTemplate = ->
      @row.closest('[data-row-link]').data('row-link')

    @rowId = ->
      @row.get(0).id.match(/\w+_(\d+)/)[1]


  ## public methods

  openLink: ->
    window.location = @url()


$(document).on('click', '[data-row-link] tbody tr:not([data-no-link=true]) td:not(.no-link)', (event) ->
  new app.LinkedTableRow(this).openLink())
