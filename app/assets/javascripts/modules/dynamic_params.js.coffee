#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

# Appends the values of the inputs fields defined in data-dynamic-params to an ajax request.
class app.DynamicParams
  constructor: (@element, @request) ->
    @url = ->
      @request.url + @joint() + @urlParams().join('&')

    @urlParams = ->
      for p in @dynamicParams()
        value = $('#' + p.replace('[', '_').replace(']', '')).val() || ''
        encodeURIComponent(p) + "=" + value

    @dynamicParams = ->
      $(@element).data('dynamic-params').split(',')

    @joint = ->
      if @request.url.indexOf('?') == -1 then '?' else '&'


  ## public methods

  append: ->
    @request.url = @url()



$(document).on('ajax:beforeSend', '[data-dynamic-params]', (event, xhr, request) ->
  new app.DynamicParams(this, request).append())
