#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


#= require ./toggler

app = window.App ||= {}
app.checkbox ||= {}

# Enables/disables all elements with the given selector.
class app.checkbox.InputEnabler
  constructor: (@selector) ->
    @inputs = ->
      $('input' + @selector +
        ', select' + @selector +
        ', textarea' + @selector)

    @affected = ->
      $(@selector)


  ## public methods

  toggle: (enabled) ->
    if enabled
      @enable()
    else
      @disable()

  enable: ->
    @inputs().prop('disabled', false)
    @affected().removeClass('disabled')
    $.each(@affected(), (i, e) -> if e.selectize then e.selectize.enable())

  disable: ->
    @inputs().prop('disabled', true)
    @affected().addClass('disabled')
    $.each(@affected(), (i, e) -> if e.selectize then e.selectize.disable())



new app.checkbox.Toggler('enable', app.checkbox.InputEnabler).bind()
