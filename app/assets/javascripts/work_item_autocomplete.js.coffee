app = window.App ||= {}

app.workItemAutocomplete = (i, input) ->
  $(input)
    .attr('autocomplete', "off")
    .autocomplete(
      minLength: 2,
      source: $(input).data('url'),
      select: workItemSelect
    )
    .data("ui-autocomplete")._renderItem = workItem

workItemSelect = (event, item) ->
  input = $(event.target)
  item = item.item
  $('#' + input.data('id-field')).val(item.id)
  input.val(item.path_shortnames + ": " + item.name)
  false

workItem = (ul, item) ->
  name = item.name
  if name and name.length > 70
    name = name.substr(0, 70) + '…';

  description = item.description
  if description and description.length > 120
    description = description.substr(0, 120) + '…'

  $('<li class="work_item-autocomplete">')
    .append('<a>' +
            '<div class="shortname">' + item.path_shortnames + '</div>' +
            '<div class="name">' + name + '</div>' +
            (description && ('<div class="description">' + description + '</div>') || '') +
            '</a>')
    .appendTo(ul)
