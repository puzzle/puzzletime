//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


// Was a `//= require ./toggler` directive, which esbuild ignores.
import "./toggler";

const app = window.App || (window.App = {});
if (!app.checkbox) { app.checkbox = {}; }

// Hides/shows all elements with the given selector.
app.checkbox.ElementHider = class ElementHider {
  constructor(selector) {
    this.selector = selector;
  }

  toggle(hide) {
    return $(this.selector).toggle(!hide);
  }
};

new app.checkbox.Toggler('hide', app.checkbox.ElementHider).bind();

