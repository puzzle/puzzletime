#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class ClearInput

  clear: (cross) ->
    console.log('click')
    @_input(cross).val('').trigger('change')
    @_input(cross).parents('form').submit()

  toggleHide: (input) ->
    group = input.parents('.has-clear')
    if input.val() == ''
      group.addClass('has-empty-value')
    else
      group.removeClass('has-empty-value')

  _input: (cross) ->
    cross.parents('.has-clear').find('input[type=search]')

  bind: ->
    self = this
    $(document).on('click', '[data-clear]', () -> self.clear($(this)))
    $(document).on('change', '.has-clear input[type=search]', () -> self.toggleHide($(this)))


new ClearInput().bind()

$(document).on('turbolinks:load', ->
  $('.has-clear input[type=search]').each((i, e) -> new ClearInput().toggleHide($(e)))
)
