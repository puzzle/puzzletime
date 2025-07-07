#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

class app.PageUpdaterTrigger
  constructor: (event, watchSelectors..., observedClass) ->
    @event = event
    @watchedElements = watchSelectors.join(', ')
    @observedClass = observedClass

class app.PageUpdaterAction
  constructor: (url) ->
    @url = url

# Update Form by running AJAX request when event fires on watched elements
class app.PageUpdater
  constructor: (trigger, actions...) ->
    @trigger = trigger
    @actions = actions
    
    @_bind()    

  _bindClassObserver: ->
    observer = new MutationObserver (mutationsList) =>
      for mutation in mutationsList
        return unless mutation.type is 'attributes' and mutation.attributeName is 'class'

        el = mutation.target
        if $(el).is(@trigger.watchedElements)
          console.log('fire action (class change)')
          @_runActionsWithSerializedClass()
          break  # avoid firing multiple times per batch

    observer.observe document.body,
      attributes: true
      subtree: true
      attributeFilter: ['class']

  _bind: ->
    if @trigger.event in ['classChange']
      @_bindClassObserver()
    else
      # unbind action before binding, as else we might
      # run into problems with turbolinks caching
      $(document).off(@trigger.event, @trigger.watchedElements)

      # use a promise chain to sequentially execute actions
      $(document).on @trigger.event, @trigger.watchedElements, (event) =>
        console.log('fire action')
        @_runActionsWithSerializedClass()
  
  _runActionsWithSerializedClass: ->
    query = @_serializeClassMatches()
    @actions.reduce (promise, action) ->
      promise.then ->
        new Promise (resolve, reject) ->
          $.getScript("#{action.url}?#{query}")
            .done(resolve)
            .fail(reject)
    , Promise.resolve()

  _serializeClassMatches: ->
    classSelector = ".#{@trigger.observedClass}"
    matching = $(@trigger.watchedElements).filter(classSelector)

    cellIds = matching.map (i, el) -> $(el).data('id')
    cellIds = $.makeArray(cellIds).filter (id) -> id?

    $.param({ 'cell_ids[]': cellIds })