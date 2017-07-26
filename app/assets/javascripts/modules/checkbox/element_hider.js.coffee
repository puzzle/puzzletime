#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


#= require ./toggler

app = window.App ||= {}
app.checkbox ||= {}

# Hides/shows all elements with the given selector.
class app.checkbox.ElementHider
  constructor: (@selector) ->

  toggle: (hide) ->
    $(@selector).toggle(!hide)

new app.checkbox.Toggler('hide', app.checkbox.ElementHider).bind()

