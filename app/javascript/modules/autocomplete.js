//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.Autocomplete = class Autocomplete {
  bind(input) {
    return $(input).selectize({
      plugins: ['required-fix'],
      valueField: 'id',
      searchField: this.searchFields(),
      selectOnTab: true,
      openOnFocus: false,
      render: {
        option: this.renderOption.bind(this),
        item: this.renderItem
      },
      load: this.loadOptions(input),
      onItemAdd: this.onItemAdd,
      onItemRemove: this.onItemRemove,
      onInitialize: this.onInitialize(input)
    });
  }

  searchFields() {
    return ['name', 'path_shortnames', 'path_names'];
  }

  onInitialize(input) {}
      
  onItemAdd() {}

  onItemRemove() {}

  renderOption(item, escape) {
    return "<div class='selectize-option'>" +
      `<div class='shortname'>${ escape(item.path_shortnames) }</div>` +
      `<div class='name'>${ escape(this.limitText(item.name, 70)) }</div>` +
      "</div>";
  }

  renderItem(item, escape) {
    return `<div>${ escape(item.path_shortnames) }: ${ escape(item.name) }</div>`;
  }

  loadOptions(input) {
    return function(query, callback) {
      if (query.length) {
        return $.ajax({
          url: Autocomplete.prototype.buildUrl(input, "q", query),
          type: 'GET',
          error() { return callback(); },
          success(res) { return callback(res); }
        });
      } else {
        return callback();
      }
    };
  }

  buildUrl(input, param_key, param_val) {
    const url        = $(input).data('url');
    const param      = encodeURIComponent(param_val);
    const param_char = url.indexOf('?') >= 0 ? '&' : '?';
    return `${url}${param_char}${param_key}=${param}`;
  }

  limitText(string, max) {
    if (!string) {
      return '';
    } else if (string.length > max) {
      return string.substr(0, max) + '…';
    } else {
      return string;
    }
  }
};
