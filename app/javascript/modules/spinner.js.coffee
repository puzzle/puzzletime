#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

# Shows/hides a spinner when a button triggers an ajax request.
# The spinner has to be added manually
class app.Spinner

  show: (button) ->
    button.prop('disable', true).addClass('disabled')
    button.siblings('.spinner').show()
    button.find('.spinner').show()

  hide: (button) ->
    button.prop('disable', false).removeClass('disabled')
    button.siblings('.spinner').hide()
    button.find('.spinner').hide()

  bind: ->
    self = this
    $(document).on('ajax:beforeSend', '[data-spin]', () -> self.show($(this)))
    $(document).on('ajax:complete', '[data-spin]', () -> self.hide($(this)))


new app.Spinner().bind()
