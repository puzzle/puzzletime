#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

do ->
  # are these key codes? :)
  kmi_sequence = [38,38,40,40,37,39,37,39,66,65];
  kmi_input = []

  document.addEventListener 'keydown', (e) ->
    kmi_input.push(e.keyCode)
    kmi_input.shift() while kmi_input.length > kmi_sequence.length

    if kmi_input.toString() is kmi_sequence.toString()
      document.getElementById('navbar-app-title').classList.add('rainbow')
