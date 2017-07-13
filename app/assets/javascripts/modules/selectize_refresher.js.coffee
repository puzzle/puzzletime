app = window.App ||= {}

# Sets remotly loaded options for selectize widget when another field changed.
class app.SelectizeRefresher
  constructor: (@master) ->

    @url = -> @master.data('url')

    @params = -> @master.serialize()

    @selectize = -> $(@master.data('update'))[0].selectize

  ## public methods

  load: ->
    $.getJSON(@url(), @params(), (data) => @refresh(data))

  refresh: (data) ->
    selectize = @selectize()
    selectize.clearOptions()
    data.forEach((e) -> selectize.addOption(value: e.id, text: e.label))
    selectize.refreshOptions(false)


$(document).on('change', '[data-update][data-url]', (event) ->
  new app.SelectizeRefresher($(this)).load())
