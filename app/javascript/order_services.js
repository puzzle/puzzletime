//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.orderServices = new (class {
  constructor() {
    this.selectionChanged = this.selectionChanged.bind(this);
  }

  init() {
    this.dateFilterChanged();
    this.initSelection();
    return this.selectionChanged();
  }

  dateFilterChanged() {
    $('#order_services_filter_form').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val());
    if ($('#period_shortcut').val()) {
      return $('#order_services_filter_form').find('#start_date,#end_date').val("");
    }
  }

  initSelection() {
    return $('body.order_services #worktimes')
      .on('change', '[name="worktime_ids[]"],#all_worktimes', this.selectionChanged);
  }

  selectionChanged() {
    return $('[data-submit-form="#worktimes"]')
      .prop('hidden', !$('[name="worktime_ids[]"]:checked').length);
  }
});



$(document).on('ajax:success', '#order_services_filter_form', () => app.orderServices.init());

$(document).on('turbolinks:load', () => app.orderServices.init());