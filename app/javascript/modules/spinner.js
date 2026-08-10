//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

// Shows/hides a spinner when a button triggers an ajax request.
// The spinner has to be added manually
app.Spinner = class Spinner {

  show(button) {
    button.prop('disable', true).addClass('disabled');
    button.siblings('.spinner').show();
    return button.find('.spinner').show();
  }

  hide(button) {
    button.prop('disable', false).removeClass('disabled');
    button.siblings('.spinner').hide();
    return button.find('.spinner').hide();
  }

  bind() {
    const self = this;
    $(document).on('ajax:beforeSend', '[data-spin]', function() { return self.show($(this)); });
    return $(document).on('ajax:complete', '[data-spin]', function() { return self.hide($(this)); });
  }
};


new app.Spinner().bind();
