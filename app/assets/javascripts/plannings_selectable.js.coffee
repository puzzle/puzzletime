app = window.App ||= {}
app.plannings ||= {}

app.plannings.selectable = do ->
  selectable = '.planning-calendar-inner'
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

  clear: ->
    $(selectable).find('.ui-selected').removeClass('ui-selected -selected')
    app.plannings.panel.hide()

  init: ->
    if $(selectable).length == 0
      return

    $(document).on('click', app.plannings.selectable.clear)
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

  destroy: ->
    $(document).off('click', app.plannings.selectable.clear)

$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()
