//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


// Was a `//= require ./toggler` directive, which esbuild ignores.
import "./toggler";

const app = window.App || (window.App = {});
if (!app.checkbox) { app.checkbox = {}; }

// Enables/disables all elements with the given selector.
app.checkbox.InputEnabler = class InputEnabler {
  constructor(selector) {
    this.selector = selector;
    this.inputs = function() {
      return $('input' + this.selector +
        ', select' + this.selector +
        ', textarea' + this.selector);
    };

    this.affected = function() {
      return $(this.selector);
    };
  }


  //# public methods

  toggle(enabled) {
    if (enabled) {
      return this.enable();
    } else {
      return this.disable();
    }
  }

  enable() {
    this.inputs().prop('disabled', false);
    this.affected().removeClass('disabled');
    return $.each(this.affected(), function(i, e) { if (e.selectize) { return e.selectize.enable(); } });
  }

  disable() {
    this.inputs().prop('disabled', true);
    this.affected().addClass('disabled');
    return $.each(this.affected(), function(i, e) { if (e.selectize) { return e.selectize.disable(); } });
  }
};



new app.checkbox.Toggler('enable', app.checkbox.InputEnabler).bind();
