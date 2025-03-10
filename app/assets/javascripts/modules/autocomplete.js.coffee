#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

class app.Autocomplete
  bind: (input) ->
    $(input).selectize(
      plugins: ['required-fix'],
      valueField: 'id',
      searchField: @searchFields(),
      selectOnTab: true,
      openOnFocus: false,
      render: {
        option: @renderOption.bind(this),
        item: @renderItem
      },
      load: @loadOptions(input),
      onItemAdd: @onItemAdd,
      onItemRemove: @onItemRemove,
      onInitialize: @onInitialize(input)
    )

  searchFields: ->
    ['name', 'path_shortnames', 'path_names']

  onInitialize: (input) ->
      
  onItemAdd: ->

  onItemRemove: ->

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
          url: Autocomplete.prototype.buildUrl(input, "q", query)
          type: 'GET',
          error: -> callback(),
          success: (res) -> callback(res)
        )
      else
        callback()

  buildUrl: (input, param_key, param_val) ->
    url        = $(input).data('url')
    param      = encodeURIComponent(param_val)
    param_char = if url.indexOf('?') >= 0 then '&' else '?'
    "#{url}#{param_char}#{param_key}=#{param}"

  limitText: (string, max) ->
    if !string
      ''
    else if string.length > max
      string.substr(0, max) + '…'
    else
      string
