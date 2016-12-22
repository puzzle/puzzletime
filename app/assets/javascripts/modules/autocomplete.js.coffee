app = window.App ||= {}

class app.Autocomplete
  bind: (input) ->
    $(input).selectize(
      valueField: 'id',
      searchField: @searchFields(),
      selectOnTab: true,
      render: {
        option: @renderOption.bind(this),
        item: @renderItem
      },
      load: @loadOptions(input),
      onItemAdd: @onItemAdd
    )

  searchFields: ->
    ['name', 'path_shortnames', 'path_names']

  onItemAdd: ->

  renderOption: (item, escape) ->
    "<div class='selectize-option'>" +
      "<div class='shortname'>#{ escape(item.path_shortnames) }</div>" +
      "<div class='name'>#{ escape(@limitText(item.name, 70)) }</div>" +
      "</div>"

  renderItem: (item, escape) ->
    "<div>#{ escape(item.path_shortnames) }: #{ escape(item.name) }</div>"

  loadOptions: (input) ->
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

  limitText: (string, max) ->
    if !string
      ''
    else if string.length > max
      string.substr(0, max) + '…'
    else
      string