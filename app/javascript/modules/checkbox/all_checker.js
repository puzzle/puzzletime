//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


// Was a `//= require ./toggler` directive, which esbuild ignores.
import "./toggler";

const app = window.App || (window.App = {});
if (!app.checkbox) { app.checkbox = {}; }

// Checks all checkboxes with the given selector.
app.checkbox.AllChecker = class AllChecker {
  constructor(name) {
    this.name = name;
  }

  toggle(checked) {
    return $('input[type=checkbox][name="' + this.name + '"]').prop('checked', checked);
  }
};

new app.checkbox.Toggler('check', app.checkbox.AllChecker).bind();
