//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});
if (!app.checkbox) { app.checkbox = {}; }

// Observes a checkbox and calls the toggle function of the given action class
app.checkbox.Toggler = class Toggler {
  constructor(data, action) {

    this.data = data;
    this.action = action;
    this.toggleChecked = function(checkbox) {
      const selector = $(checkbox).data(this.data);
      const checked = $(checkbox).prop('checked');
      return new this.action(selector).toggle(checked);
    };
  }


  //# public methods

  bind() {
    const self = this;
    const selector = '[data-' + this.data + ']';
    $(document).on('click', selector, function(event) { return self.toggleChecked(this); });
    return $(document).on('turbolinks:load', () => $(selector).each((i, e) => self.toggleChecked(e)));
  }
};
