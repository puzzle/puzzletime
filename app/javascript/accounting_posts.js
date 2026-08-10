//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

$(document).on('turbolinks:load', function() {
  const handle_book_on_order_radio = function(value) {
    const work_item_fields = $('#work_item_fields');
    if (value === 'true') {
      return work_item_fields.hide();
    } else {
      return work_item_fields.show();
    }
  };

  $('input[name=book_on_order]').on('change', function(event) {
    const value = event.target.value.toLowerCase();
    return handle_book_on_order_radio(value);
  });

  handle_book_on_order_radio($('input[name=book_on_order]:checked').val());

  const $hoursPerDay = parseFloat($('[data-hours-per-day]').data('hoursPerDay'));
  let activeSource = null;

  const updateOfferedValues = function() {
    let newDays;
    const source = $(this).attr('id');

    const hours = parseFloat($('#accounting_post_offered_hours').val());
    const days = parseFloat($('#accounting_post_offered_days').val());
    const rate = parseFloat($('#accounting_post_offered_rate').val());
    const total = parseFloat($('#accounting_post_offered_total').val());
    let newHours = (newDays = null);

    if (!isNaN(rate) && (rate > 0) && (source.endsWith('_total') ||
       (source.endsWith('_rate') && activeSource.endsWith('_total')))) {

      newHours = total / rate;
      newDays = newHours / $hoursPerDay;
    } else if (!isNaN(hours) && (hours > 0) && (source.endsWith('_hours') ||
            (source.endsWith('_rate') && activeSource.endsWith('_hours')))) {

      newDays = hours / $hoursPerDay;
      $('#accounting_post_offered_total').val((!isNaN(rate) && (rate > 0) && (hours * rate)) || '');
    } else if (!isNaN(days) && (days > 0) && (source.endsWith('_days') ||
            (source.endsWith('_rate') && activeSource.endsWith('_days')))) {

      newHours = days * $hoursPerDay;
      $('#accounting_post_offered_total').val((!isNaN(rate) && (rate > 0) && (newHours * rate)) || '');
    }

    if (newHours !== null) {
      $('#accounting_post_offered_hours').val(newHours || '');
    }
    if (newDays !== null) {
      $('#accounting_post_offered_days').val(newDays || '');
    }

    if (!source.endsWith('_rate')) {
      return activeSource = source;
    }
  };

  return $('#accounting_post_offered_hours, ' +
    '#accounting_post_offered_days, ' +
    '#accounting_post_offered_rate, ' +
    '#accounting_post_offered_total').on('keyup change', updateOfferedValues);
});
