app = window.App ||= {}
app.plannings ||= {}

app.plannings.selectable = new class
  selectable = '.planning-calendar-inner'
  selectee = '.planning-calendar-days > .day'
  isSelecting = false

  start = (event, ui) ->
    isSelecting = true
    setTimeout((-> isSelecting && app.plannings.panel.hide()), 100) # avoid flickering

  stop = (event, ui) ->
    isSelecting = false
    selectedElements = $(event.target).find('.ui-selected')
    selectedElements.addClass('-selected')

    if selectedElements.length > 0
      app.plannings.panel.show(selectedElements)

  selecting = (event, ui) ->
    $(ui.selecting).addClass('-selected')

  unselecting = (event, ui) ->
    $(ui.unselecting).removeClass('-selected')

  clear: ->
    $(selectable).find('.ui-selected').removeClass('ui-selected -selected')
    app.plannings.panel.hide()

  getSelectedDays: ->
    $(selectable).find('.ui-selected')
      .toArray()
      .map((element) ->
        row = $(element).parent()
        rowId = row.prop('id')
          .match(/planning_row_employee_(\d+)_work_item_(\d+)/)
        date = $(selectable).find('.planning-calendar-days-header .dayheader')
          .eq(row.children('.day').index(element)).data('date')

        { employee_id: rowId[1], work_item_id: rowId[2], date: date }
      )

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
