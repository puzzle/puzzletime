#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

# Update Form by running AJAX request when event fires on watched elements
class app.FormUpdater
  constructor: (url, event, formSelector, watchSelectors...) ->
    @url = url
    @event = event
    @form = $(formSelector)
    @watchedElements = watchSelectors.join(', ')

    @_bind()

  updateForm: ->
    this._getUrl(@url)

  _params: ->
    @form.serialize()

  _getUrl: ->
    $.getScript("#{@url}?#{@_params()}")

  _bind: ->
    $(document).on(@event, @watchedElements, (event) => this.updateForm())

