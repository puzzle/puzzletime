app = window.App ||= {}

class app.OrderAutocomplete extends app.Autocomplete

  onItemAdd: (value, item) ->
    if value
      window.location = window.location.toString().replace(/orders\/\d+/, 'orders/' + value)

$(document).on('turbolinks:load', ->
  $('[data-autocomplete=order]').each((i, element) -> new app.OrderAutocomplete().bind(element))
)
