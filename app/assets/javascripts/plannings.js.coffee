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

  hideOnEscape = (event) ->
    if event.key == "Escape"
      app.plannings.panel.hide()
      app.plannings.selectable.clear()

  show: (selectedElements) ->
    $(panel)
      .show()
      .on('click', (event) -> event.stopPropagation())
    position()

  hide: ->
    $(panel).hide()

  init: ->
    if $(panel).length == 0
      return

    $(document).on('keyup', hideOnEscape)
    $(container).on('scroll', position)
    $(panel).find('.planning-cancel').on('click', (event) ->
      app.plannings.panel.hide()
      $(event.target).blur()

      app.plannings.selectable.clear()
    )

  destroy: ->
    $(document).off('keyup', hideOnEscape)

$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()

  app.plannings.panel.destroy()
  app.plannings.panel.init()
