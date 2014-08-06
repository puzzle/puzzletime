app = window.App ||= {}

app.workItemAutocomplete = (i, input) ->
  $(input).selectize(
    valueField: 'id',
    searchField: ['name','path_shortnames','description'],
    render: {
      option: renderOption,
      item: renderItem
    },
    load: loadOptions(input)
  )

renderOption = (item, escape) ->
  '<div class="selectize-option">' +
  '<div class="shortname">' + escape(item.path_shortnames) + '</div>' +
  '<div class="name">' + escape(limitText(item.name, 70)) + '</div>' +
  (if item.description then '<div class="description">' + escape(limitText(item.description, 120)) + '</div>' else '') +
  '</div>'

renderItem = (item, escape) ->
  '<div>' + escape(item.path_shortnames) + ": " + escape(item.name) + '</div>'

loadOptions = (input) ->
  (query, callback) ->
    if query.length
      $.ajax(
        url: $(input).data('url') + '?q=' + encodeURIComponent(query),
        type: 'GET',
        error: -> callback(),
        success: (res) -> callback(res)
      )
    else
      callback()

limitText = (string, max) ->
  if !string
    ''
  else if string.length > max
    string.substr(0, 70) + '…'
  else
    string

