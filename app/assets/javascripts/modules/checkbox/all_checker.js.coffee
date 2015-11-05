#= require ./toggler

app = window.App ||= {}
app.checkbox ||= {}

# Checks all checkboxes with the given selector.
class app.checkbox.AllChecker
  constructor: (@name) ->

  toggle: (checked) ->
    $('input[type=checkbox][name="' + @name + '"]').prop('checked', checked)

new app.checkbox.Toggler('check', app.checkbox.AllChecker).bind()
