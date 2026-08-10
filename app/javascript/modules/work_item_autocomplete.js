//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


// Subclasses app.Autocomplete at load time.
import "./autocomplete";

const app = window.App || (window.App = {});

app.WorkItemAutocomplete = class WorkItemAutocomplete extends app.Autocomplete {
  constructor(...args) {
    super(...args);
    this.set_progress_bar = this.set_progress_bar.bind(this);
    this.onItemAdd = this.onItemAdd.bind(this);
  }

  picked_color(offered_hrs, done_hrs) {
    if (offered_hrs === null) {
      return 'green';
    }
    if ((done_hrs / offered_hrs) >= 1) {
      return 'red';
    }
    if ((done_hrs / offered_hrs) >= 0.8) {
      return 'orange';
    }
    return 'green';
  }

  set_progress_bar(item) {
    // renderes a progress bar depending on how much of the budget is already used
    let percentage;
    let offered_hours = item.attr('data-offered_hours');
    const done_hours = parseFloat(item.attr('data-done_hours')).toFixed(2);
    $('#live-bar-success').removeClass( "bg-green bg-orange bg-red" ).addClass("bg-" + this.picked_color(offered_hours, done_hours));

    // handle the case where the budget is not set (offered_hours == 'null')
    // CAREFUL: if not set in the db, due to the json serializer, offered_hours will be 'null' (string). 
    //   Nevertheless, we also check for null in case this changes in the future
    if ((offered_hours != null) && (offered_hours !== 'null')) {  
      offered_hours = parseFloat(offered_hours).toFixed(2);  
      percentage = parseFloat((done_hours * 100) / offered_hours).toFixed(2);  
    } else {
      offered_hours = '∞';
      percentage = 0;
    }

    // set tooltip
    $('.live-budget-bar').attr('data-original-title', `${ done_hours } h / ${ offered_hours } h (${ percentage }%)`);
    // set length of filled part of progress bar
    return $('#live-bar-success').width(Math.min(percentage,100) + '%');
  }

  onInitialize(input) {
    return function() {
      const selectize = $(input).data('selectize');
      if (selectize.items.length === 1) {
        const value = selectize.getValue();
        selectize.removeOption(value);
        
        return $.ajax({
            url: app.Autocomplete.prototype.buildUrl(input, "id", value),
            type: 'GET',
            success(res) {
              const option = res[0];
              selectize.addOption(option);
              selectize.setValue(option.id, true);
              return selectize.trigger('item_add', option.id, selectize.getItem(option.id));
            } // Manually trigger event
          });
      }
    };
  }

  onItemAdd(value, item)  {
    let billable, meal_compensation;
    if (((typeof stored_account_id !== "undefined") && (stored_account_id !== null)) && (stored_account_id === item.data().value)) {
      billable = stored_billable;
      meal_compensation = stored_meal_compensation;
    } else {
      billable = item.attr('data-billable') === 'true';
      meal_compensation = item.attr('data-meal_compensation') === 'true';
    }

    $('#ordertime_billable').prop('checked', billable);
    $('#ordertime_meal_compensation').prop('checked', meal_compensation);
    return this.set_progress_bar(item);
  }
      
  onItemRemove(value) {
    // Removes the progress bar if no position is selected
    $('#live-bar-success').width(0 + '%');
    return $('.live-budget-bar').attr('data-original-title', "Wähle eine Buchungsposition aus");
  }
  
  renderOption(item, escape) {
    return "<div class='selectize-option'>" +
      `<div class='${this.picked_color(item.offered_hours, item.done_hours)} icon-disk'></div>` +
      `<div class='shortname'>${ escape(item.path_shortnames) }</div>` +
      `<div class='name'>${ escape(this.limitText(item.name, 70)) }</div>` +
      `<div class='description'>${ escape(this.limitText(item.description || '', 120)) }</div>` +
      "</div>";
  }
    
  renderItem(item, escape) {
    return `<div data-billable=${ item.billable } data-meal_compensation=${ item.meal_compensation } data-offered_hours=${ item.offered_hours } data-done_hours=${ item.done_hours }>` +
    `${ escape(item.path_shortnames) }: ${ escape(item.name) }</div>`;
  }
};

$(document).on('turbolinks:load', () => $('[data-autocomplete=work_item]').each((i, element) => new app.WorkItemAutocomplete().bind(element)));
