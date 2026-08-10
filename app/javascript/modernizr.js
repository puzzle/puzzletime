//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

// Replaces modernizr-custom.js, built for ?-csspositionsticky-setclasses.
window.Modernizr = { csspositionsticky: CSS.supports("position", "sticky") };

document.documentElement.classList.toggle(
  "csspositionsticky",
  window.Modernizr.csspositionsticky
);
