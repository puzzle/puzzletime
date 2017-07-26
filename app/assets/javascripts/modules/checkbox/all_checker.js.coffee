#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


#= require ./toggler

app = window.App ||= {}
app.checkbox ||= {}

# Checks all checkboxes with the given selector.
class app.checkbox.AllChecker
  constructor: (@name) ->

  toggle: (checked) ->
    $('input[type=checkbox][name="' + @name + '"]').prop('checked', checked)

new app.checkbox.Toggler('check', app.checkbox.AllChecker).bind()
