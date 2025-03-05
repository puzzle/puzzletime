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
    billable = item.attr('data-billable') == 'true'
    meal_compensation = item.attr('data-meal_compensation') == 'true'
    $('#ordertime_billable').prop('checked', billable);
    $('#ordertime_meal_compensation').prop('checked', meal_compensation);

    # renderes a progress bar depending on how much of the budget is already used
    offered_hours = item.attr('data-offered_hours')
    done_hours = parseFloat(item.attr('data-done_hours')).toFixed(2)
    if offered_hours? and offered_hours != 'null'  
      offered_hours = parseFloat(offered_hours).toFixed(2)  
      percentage = parseFloat(done_hours * 100 / offered_hours).toFixed(2)  
    else
      offered_hours = '∞'
      percentage = 0
    
    $('.live_budget_bar').show();
    $('#live_bar_success').width(Math.min(percentage,100) + '%');
    $('.live_budget_bar').attr('data-original-title', "#{ done_hours } h / #{ offered_hours } h (#{ percentage }%)");
      
  onItemRemove: (value, item) ->
    # Removes the progress bar if no position is set
    $('#live_bar_success').width(0 + '%');
    $('.live_budget_bar').hide();

  renderOption: (item, escape) ->
    "<div class='selectize-option'>" +
      "<div class='#{@picked_color(item.offered_hours, item.done_hours)} icon-disk'></div>" +
      "<div class='shortname'>#{ escape(item.path_shortnames) }</div>" +
      "<div class='name'>#{ escape(@limitText(item.name, 70)) }</div>" +
      "<div class='description'>#{ escape(@limitText(item.description || '', 120)) }</div>" +
      "</div>"
    
  renderItem: (item, escape) ->
    "<div data-billable=#{ item.billable } data-meal_compensation=#{ item.meal_compensation } data-offered_hours=#{ item.offered_hours } data-done_hours=#{ item.done_hours }>" +
    "#{ escape(item.path_shortnames) }: #{ escape(item.name) }</div>"

$(document).on('turbolinks:load', ->
  $('[data-autocomplete=work_item]').each((i, element) -> new app.WorkItemAutocomplete().bind(element))
  # hide the progress bar depicting the usage of the budget upon initialization of the site
  $('.live_budget_bar').hide();
)
