app = window.App ||= {}

# Hides/shows all elements with the given selector.
class app.VisibilityToggler
  constructor: (@toggleControl) ->
    this.setup()

  setup: ->
    selector = $(@toggleControl).data('toggle-visibility')
    toggleElements = $(selector)

    $(@toggleControl).click ->
      toggleElements.toggle()


