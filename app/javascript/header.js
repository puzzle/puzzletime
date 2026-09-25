//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

(function () {
  // are these key codes? :)
  const kmiSequence = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65]
  const kmiInput = []

  return document.addEventListener('keydown', function (e) {
    kmiInput.push(e.keyCode)
    while (kmiInput.length > kmiSequence.length) { kmiInput.shift() }

    if (kmiInput.toString() === kmiSequence.toString()) {
      return document.getElementById('navbar-app-title').classList.add('rainbow')
    }
  })
})()
