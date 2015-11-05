#= require ./toggler

app = window.App ||= {}
app.checkbox ||= {}

# Hides/shows all elements with the given selector.
class app.checkbox.ElementHider
  constructor: (@selector) ->

  toggle: (hide) ->
    $(@selector).toggle(!hide)

new app.checkbox.Toggler('hide', app.checkbox.ElementHider).bind()

