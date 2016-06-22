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

