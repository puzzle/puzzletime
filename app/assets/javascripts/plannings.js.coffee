app = window.App ||= {}

app.plannings = {}


app.plannings.panel = do ->
  panel = '.planning-panel'

  show: (selectedElements) ->
    $(panel).show()
      .on('click', (event) -> event.stopPropagation())
    # TODO: position around selectedElements

  hide: ->
    $(panel).hide()


app.plannings.selectable = do ->
  selectable = '.planning-calendar'
  selectee = '.day'

  start = (event, ui) ->
    app.plannings.panel.hide()

  stop = (event, ui) ->
    $(event.target).find('.ui-selected').addClass('-selected')
    app.plannings.panel.show($(event.target).find('.ui-selected'))

  selecting = (event, ui) ->
    $(ui.selecting).addClass('-selected')

  unselecting = (event, ui) ->
    $(ui.unselecting).removeClass('-selected')

  unselect = ->
    $(selectable).find('.ui-selected').removeClass('ui-selected -selected')
    app.plannings.panel.hide()

  init: ->
    $(selectable).selectable({
      filter: selectee,
      classes: {
        'ui-selected': '-selected'
      }
      start: start,
      stop: stop,
      selecting: selecting,
      unselecting: unselecting
    })

    $(document).on('click', ':not(' + selectee + ')', unselect)

  destroy: ->
    $(selectable).selectable('destroy');
    $(document).off('click', unselect)


$ ->
  app.plannings.selectable.init()
