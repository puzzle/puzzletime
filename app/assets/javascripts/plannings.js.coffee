app = window.App ||= {}

app.plannings = {}


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

  initOnce: ->
    $(document).on('click', app.plannings.selectable.clear)

  initOnPageChange: ->
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


app.plannings.panel = do ->
  panel = '.planning-panel'
  container = '.planning-calendar'

  position = ->
    if $(panel).length == 0 || $(panel).is(':hidden')
      return

    $(panel).position({
      my: 'right top',
      at: 'right bottom',
      of: $(container).find('.ui-selected').last(),
      within: container
    })

  show: (selectedElements) ->
    $(panel)
      .show()
      .on('click', (event) -> event.stopPropagation())
    position()

  hide: ->
    $(panel).hide()

  initOnPageChange: ->
    $(container).on('scroll', position)
    $(panel).find('.planning-cancel').on('click', ->
      app.plannings.panel.hide()
      app.plannings.selectable.clear()
    )


app.plannings.selectable.initOnce()

$ ->
  app.plannings.selectable.initOnPageChange()
  app.plannings.panel.initOnPageChange()
