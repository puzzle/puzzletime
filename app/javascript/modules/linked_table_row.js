//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

// Opens the url template from the table's data-row-link with the current row id.
app.LinkedTableRow = class LinkedTableRow {
  constructor(cell) {
    this.row = $(cell).closest('tr');

    this.url = function() {
      return this.urlTemplate().replace('/:id/', '/' + this.rowId() + '/');
    };

    this.urlTemplate = function() {
      return this.row.closest('[data-row-link]').data('row-link');
    };

    this.rowId = function() {
      return this.row.get(0).id.match(/\w+_(\d+)/)[1];
    };
  }


  //# public methods

  openLink() {
    return window.location = this.url();
  }
};


$(document).on('click', '[data-row-link] tbody tr:not([data-no-link=true]) td:not(.no-link)', function(event) {
  return new app.LinkedTableRow(this).openLink();
});
