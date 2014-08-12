app = window.App ||= {}

app.projectAutocomplete = (i, input) ->
  $(input)
    .attr('autocomplete', "off")
    .autocomplete(
      minLength: 2,
      source: $(input).data('url'),
      select: projectSelect
    )
    .data("ui-autocomplete")._renderItem = projectItem

projectSelect = (event, item) ->
  input = $(event.target)
  item = item.item
  $('#' + input.data('id-field')).val(item.id)
  $('#' + input.data('billable-field')).prop('checked', item.billable)
  input.val(item.path_shortnames + ": " + item.name)
  false

projectItem = (ul, item) ->
  name = item.name
  if name and name.length > 70
    name = name.substr(0, 70) + '…';

  description = item.description
  if description and description.length > 120
    description = description.substr(0, 120) + '…'

  $('<li class="project-autocomplete">')
    .append('<a>' +
            '<div class="shortname">' + item.path_shortnames + '</div>' +
            '<div class="name">' + name + '</div>' +
            (description && ('<div class="description">' + description + '</div>') || '') +
            '</a>')
    .appendTo(ul)
