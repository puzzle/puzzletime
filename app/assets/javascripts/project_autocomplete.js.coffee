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
  input.val(item.path_shortnames + ": " + item.name)
  false

projectItem = (ul, item) ->
  $("<li>")
    .append("<a><strong>" + item.path_shortnames + "</strong> - " +
            item.name + "<br>" +
            (item.description || '') + "</a>" )
    .appendTo(ul)