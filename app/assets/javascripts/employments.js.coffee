#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

$ ->
  form = $('form[data-needs-confirmation="true"]')
  return unless form.length
  return if form.data('confirmed')

  if confirm('Möglicherweise ging vergessen die Ferientage pro Jahr einzutragen. Dennoch fortfahren?')
    $('<input>')
      .attr('type', 'hidden')
      .attr('name', 'confirmed')
      .val('true')
      .appendTo(form)
    form.data('confirmed', true)
    form.submit()
