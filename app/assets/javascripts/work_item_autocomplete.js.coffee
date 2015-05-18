app = window.App ||= {}

app.workItemAutocomplete = (i, input) ->
  $(input).selectize(
    valueField: 'id',
    searchField: ['name','path_shortnames','description','path_names'],
    selectOnTab: true,
    render: {
      option: renderOption,
      item: renderItem
    },
    load: loadOptions(input),
    onItemAdd: (value, item) ->
      billable = item.attr('data-billable') == 'true'
      $('#ordertime_billable').prop('checked', billable);
  )

renderOption = (item, escape) ->
  "<div class='selectize-option'>" +
    "<div class='shortname'>#{ escape(item.path_shortnames) }</div>" +
    "<div class='name'>#{ escape(limitText(item.name, 70)) }</div>" +
    "<div class='description'>#{ escape(limitText(item.description || '', 120)) }</div>" +
  "</div>"

renderItem = (item, escape) ->
  "<div data-billable=#{ item.billable }>#{ escape(item.path_shortnames) }: #{ escape(item.name) }</div>"

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
    string.substr(0, max) + '…'
  else
    string
