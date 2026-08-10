//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


// Subclasses app.Autocomplete at load time.
import "./autocomplete";

const app = window.App || (window.App = {});

app.OrderAutocomplete = class OrderAutocomplete extends app.Autocomplete {

  onItemAdd(value, item) {
    if (value) {
      return window.location = window.location.toString().replace(/orders\/\d+/, 'orders/' + value);
    }
  }
};

$(document).on('turbolinks:load', () => $('[data-autocomplete=order]').each((i, element) => new app.OrderAutocomplete().bind(element)));
