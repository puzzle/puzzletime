//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

// Sets remotly loaded options for selectize widget when another field changed.
app.SelectizeRefresher = class SelectizeRefresher {
  constructor(master) {

    this.master = master;
    this.url = function() { return this.master.data('url'); };

    this.params = function() { return this.master.serialize(); };

    this.selectize = function() { return $(this.master.data('update'))[0].selectize; };
  }

  //# public methods

  load() {
    return $.getJSON(this.url(), this.params(), data => this.refresh(data));
  }

  refresh(data) {
    const selectize = this.selectize();
    selectize.clear();
    selectize.clearOptions();
    data.forEach(e => selectize.addOption({value: e.id, text: e.label}));
    return selectize.refreshOptions(false);
  }
};


$(document).on('change', '[data-update][data-url]', function(event) {
  return new app.SelectizeRefresher($(this)).load();
});
