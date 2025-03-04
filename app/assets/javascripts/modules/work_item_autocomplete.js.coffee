#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

class app.WorkItemAutocomplete extends app.Autocomplete
  picked_color: (offered_hrs, done_hrs) ->
    if offered_hrs == null
      return 'green'
    if done_hrs / offered_hrs >= 1
        return 'red'
    if done_hrs / offered_hrs >= 0.8
        return 'orange'
    'green'

  onItemAdd: (value, item) ->
    console.log(item)
    billable = item.attr('data-billable') == 'true'
    meal_compensation = item.attr('data-meal_compensation') == 'true'
    $('#ordertime_billable').prop('checked', billable);
    $('#ordertime_meal_compensation').prop('checked', meal_compensation);

    offered_hours = item.attr('data-offered_hours')
    done_hours = item.attr('data-done_hours')
    percentage = done_hours * 100 / offered_hours
      
    console.log(done_hours + "/" + offered_hours)
    $('.live_budget_bar').show();
    $('#live_bar_success').width(Math.min(percentage,100) + '%');
    $('.live_budget_bar').attr('data-original-title', "#{ parseFloat(done_hours).toFixed(1) } h / #{ parseFloat(offered_hours).toFixed(1) } h (#{ percentage.toFixed(2) }%)");
      
    

  onItemRemove: (value, item) ->
    $('#live_bar_success').width(0 + '%');
    $('.live_budget_bar').hide();

  renderOption: (item, escape) ->
    "<div class='selectize-option'>" +
      "<div class='#{@picked_color(item.offered_hours, item.done_hours)} icon-disk'></div>" +
      "<div class='shortname'>#{ escape(item.path_shortnames) }</div>" +
      "<div class='name'>#{ escape(@limitText(item.name, 70)) }</div>" +
      "<div class='description'>#{ escape(@limitText(item.description || '', 120)) }</div>" +
      "</div>"
    
  # TODO: update progress bar on update

  renderItem: (item, escape) ->
    "<div data-billable=#{ item.billable } data-meal_compensation=#{ item.meal_compensation } data-offered_hours=#{ item.offered_hours } data-done_hours=#{ item.done_hours }>" +
    "#{ escape(item.path_shortnames) }: #{ escape(item.name) }</div>"

$(document).on('turbolinks:load', ->
  $('[data-autocomplete=work_item]').each((i, element) -> new app.WorkItemAutocomplete().bind(element))
  $('.live_budget_bar').hide();
)
