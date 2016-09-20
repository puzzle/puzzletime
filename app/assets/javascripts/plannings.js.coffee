app = window.App ||= {}

app.plannings = {}


app.plannings.panel = do ->
  panel = '.plannings-panel'

  show: (selectedElements) ->
    $(panel).show()
      .on('click', (event) -> event.stopPropagation())
    # TODO: position around selectedElements

  hide: ->
    $(panel).hide()


app.plannings.selectable = do ->
  selectable = '.plannings-grid'
  selectee = '.plannings-day'

  start = (event, ui) ->
    app.plannings.panel.hide()

  stop = (event, ui) ->
    app.plannings.panel.show($(event.target).find('.ui-selected'))

  unselect = (event) ->
    console.log('unselect', event)
    $(selectable + ' .ui-selected').removeClass('ui-selected')
    app.plannings.panel.hide()

  init: ->
    console.log('init')
    $(selectable).selectable({
      filter: selectee,
      start: start,
      stop: stop
    })

    $(document).on('click', ':not(' + selectee + ')', unselect)

  destroy: ->
    $(selectable).selectable('destroy');
    $(document).off('click', unselect)


$ ->
  app.plannings.selectable.init()
