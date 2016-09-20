app = window.App ||= {}

app.plannings = {}


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

  clear: ->
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

    $(document).on('click', ':not(' + selectee + ')', app.plannings.selectable.clear)

  destroy: ->
    $(selectable).selectable('destroy');
    $(document).off('click', app.plannings.selectable.clear)


app.plannings.panel = do ->
  panel = '.planning-panel'
  container = '.planning-calendar'

  init: ->
    $(document).find(panel).find('.planning-cancel')
      .on('click', ->
        app.plannings.panel.hide()
        app.plannings.selectable.clear()
      )

  show: (selectedElements) ->
    $(panel)
      .show()
      .position({
        my: 'right top',
        at: 'right bottom',
        of: selectedElements.last(),
        within: container
      })
      .on('click', (event) -> event.stopPropagation())

  hide: ->
    $(panel).hide()


$ ->
  app.plannings.selectable.init()
  app.plannings.panel.init()
