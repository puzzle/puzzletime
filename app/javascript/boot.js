//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.

// Was `//= require_self`: ran before the modules and feature files.

const app = window.App || (window.App = {});

if (typeof String.prototype.endsWith !== 'function') {
  String.prototype.endsWith = function(suffix) {
    return this.indexOf(suffix, this.length - suffix.length) !== -1;
  };
}

if (typeof Object.assign !== 'function') {
  Object.assign = function(target) {
    'use strict';
    if (target == null) {
      throw new TypeError('Cannot convert undefined or null to object');
    }
    const output = Object(target);
    let index = 1;
    while (index < arguments.length) {
      var source = arguments[index];
      if ((source !== undefined) && (source !== null)) {
        for (var nextKey in source) {
          if (source.hasOwnProperty(nextKey)) {
            output[nextKey] = source[nextKey];
          }
        }
      }
      index++;
    }
    return output;
  };
}

// Fixes https://github.com/selectize/selectize.js/pull/1320
Selectize.define('required-fix', function(options) {
  return this.refreshValidityState = () => {
    if (!this.isRequired) { return false; }

    const invalid = !this.items.length;
    this.isInvalid = invalid;

    if (invalid) {
      this.$control_input.attr('required', '');
      return this.$input.removeAttr('required');
    } else {
      this.$control_input.removeAttr('required');
      return this.$input.attr('required');
    }
  };
});

//###############################################################
// before caching, the DOM is restored to original form, preventing selectize to render the same input twice
$(document).on('turbolinks:before-cache', () => $('.selectized').each(function() {
  return this.selectize.destroy();}));

// if the page is loaded from the browser's bfcache (event.persisted == true), reload the page
// to avoid some weird turbolinks bugs
window.addEventListener('pageshow', function(event) {
  if (event.persisted) {
    return location.reload();
  }
});

//###############################################################
// because of turbolinks.jquery, do bind ALL document events here

// wire up toggle links
$(document).on('click', '[data-toggle]', function(event) {
  const id = $(this).data('toggle');
  if (id !== 'tooltip') {
    $('#' + id).slideToggle(200);
    return event.preventDefault();
  }
});

// wire up direct submit fields
$(document).on('change', '[data-submit]', function(event) {
  return $(this).closest('form').submit();
});

// wire up tooltips
$(document).tooltip({
  selector: '[data-toggle=tooltip]',
  container: 'body',
  placement: 'top',
  html: true
});

// wire up searchable form fields for dynamically added nested form fields
$(document).on("fields_added.nested_form_fields", (event, param) => $('select.searchable').selectize());

// show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) => alert('Sorry, something went wrong\n(' + error + ')'));


//###############################################################
// only bind events for non-document elements on turbolinks:load and ajax:success
$(document).on('turbolinks:load ajax:success', function() {
  // wire up selectize
  $('select.searchable:not([multiple])').selectize({selectOnTab: true});
  $('select[multiple].searchable').selectize({plugins: ['remove_button'], selectOnTab: true});

  // wire up toggle buttons
  $('[data-toggle=buttons]').button();

  // wire up disabled links. Bind on body to handle bubbling event before document
  $('body').on('click', 'a.disabled', function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
    return event.stopPropagation();
  });

  // set initial focus
  $('.initial-focus, .initial-focus input').focus();
  return setTimeout(() => $('.initial-focus.selectized').next('.selectize-control').find('input').focus());
});
