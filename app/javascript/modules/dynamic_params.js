//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

// Appends the values of the inputs fields defined in data-dynamic-params to an ajax request.
app.DynamicParams = class DynamicParams {
  constructor(element, request) {
    this.element = element;
    this.request = request;
    this.url = function() {
      return this.request.url + this.joint() + this.urlParams().join('&');
    };

    this.urlParams = function() {
      return (() => {
        const result = [];
        for (var p of this.dynamicParams()) {
          var value = $('#' + p.replace('[', '_').replace(']', '')).val() || '';
          result.push(encodeURIComponent(p) + "=" + value);
        }
        return result;
      })();
    };

    this.dynamicParams = function() {
      return $(this.element).data('dynamic-params').split(',');
    };

    this.joint = function() {
      if (this.request.url.indexOf('?') === -1) { return '?'; } else { return '&'; }
    };
  }


  //# public methods

  append() {
    return this.request.url = this.url();
  }
};



$(document).on('ajax:beforeSend', '[data-dynamic-params]', function(event, xhr, request) {
  return new app.DynamicParams(this, request).append();
});
