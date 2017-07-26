#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

class app.WorkItemAutocomplete extends app.Autocomplete

  onItemAdd: (value, item) ->
    billable = item.attr('data-billable') == 'true'
    $('#ordertime_billable').prop('checked', billable);

  renderOption: (item, escape) ->
    "<div class='selectize-option'>" +
      "<div class='shortname'>#{ escape(item.path_shortnames) }</div>" +
      "<div class='name'>#{ escape(@limitText(item.name, 70)) }</div>" +
      "<div class='description'>#{ escape(@limitText(item.description || '', 120)) }</div>" +
      "</div>"

  renderItem: (item, escape) ->
    "<div data-billable=#{ item.billable }>#{ escape(item.path_shortnames) }: #{ escape(item.name) }</div>"


$(document).on('turbolinks:load', ->
  $('[data-autocomplete=work_item]').each((i, element) -> new app.WorkItemAutocomplete().bind(element))
)
