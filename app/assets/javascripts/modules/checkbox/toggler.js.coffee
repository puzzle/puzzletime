app = window.App ||= {}
app.checkbox ||= {}

# Observes a checkbox and calls the toggle function of the given action class
class app.checkbox.Toggler
  constructor: (@data, @action) ->

    @toggleChecked = (checkbox) ->
      selector = $(checkbox).data(@data)
      checked = $(checkbox).prop('checked')
      new @action(selector).toggle(checked)


  ## public methods

  bind: ->
    self = this
    selector = '[data-' + @data + ']'
    $(document).on('click', selector, (event) -> self.toggleChecked(this))
    $(document).on('turbolinks:load', -> $(selector).each((i, e) -> self.toggleChecked(e)))



