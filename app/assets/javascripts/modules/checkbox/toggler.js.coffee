#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}
app.checkbox ||= {}

# Observes a checkbox and calls the toggle function of the given action class
class app.checkbox.Toggler
  constructor: (@data, @action) ->

    @toggleChecked = (checkbox) ->
      selector = $(checkbox).data(@data)
      checked = $(checkbox).prop('checked')
      new @action(selector).toggle(checked)


  ## public methods

  bind: ->
    self = this
    selector = '[data-' + @data + ']'
    $(document).on('click', selector, (event) -> self.toggleChecked(this))
    $(document).on('turbolinks:load', -> $(selector).each((i, e) -> self.toggleChecked(e)))



