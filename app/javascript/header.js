//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

(function() {
  // are these key codes? :)
  const kmi_sequence = [38,38,40,40,37,39,37,39,66,65];
  const kmi_input = [];

  return document.addEventListener('keydown', function(e) {
    kmi_input.push(e.keyCode);
    while (kmi_input.length > kmi_sequence.length) { kmi_input.shift(); }

    if (kmi_input.toString() === kmi_sequence.toString()) {
      return document.getElementById('navbar-app-title').classList.add('rainbow');
    }
  });
})();
