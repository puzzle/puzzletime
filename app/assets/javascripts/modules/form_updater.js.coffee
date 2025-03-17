#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

class app.FormUpdaterTrigger
  constructor: (event, watchSelectors...) ->
    @event = event
    @watchedElements = watchSelectors.join(', ')

class app.FormUpdaterAction
  constructor: (url, formSelector) ->
    @url = url
    @form = $(formSelector)

# Update Form by running AJAX request when event fires on watched elements
class app.FormUpdater
  constructor: (trigger, actions...) ->
    @trigger = trigger
    @actions = actions
    
    @_bind()    

  _bind: ->
    # use a promise chain to sequentially execute actions
    $(document).on @trigger.event, @trigger.watchedElements, (event) =>
      @actions.reduce (promise, action) ->
        promise.then ->
          new Promise (resolve, reject) ->
            $.getScript("#{action.url}?#{action.form.serialize()}")
              .done(resolve)
              .fail(reject)
      , Promise.resolve()  # Start with a resolved promise to begin the chain