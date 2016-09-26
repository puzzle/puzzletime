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

  clear: (e) =>
    unless ($(e.target).closest('.panel').length)
      $(selectable).find('.ui-selected').removeClass('ui-selected -selected')
      app.plannings.panel.hide()

  getSelectedDays: ->
    $(selectable).find('.ui-selected')
      .toArray()
      .map((element) ->
        row = $(element).parent()
        [ _match, employee_id, work_item_id ] = row.prop('id')
          .match(/planning_row_employee_(\d+)_work_item_(\d+)/)
        date = $(selectable).find('.planning-calendar-days-header .dayheader')
          .eq(row.children('.day').index(element)).data('date')

        { employee_id, work_item_id, date }
      )

  getSelectedPercentValues: ->
    $(selectable).find('.ui-selected')
      .toArray()
      .map((element) -> $(element).text().trim())
      .filter((value, index, self) -> self.indexOf(value) == index)

  getSelectedDefinitiveValues: ->
    $(selectable).find('.ui-selected')
      .toArray()
      .map(((element) ->
        if $(element).hasClass('-definitive')
          return true
        else if ($(element).hasClass('-provisional'))
          return false
        return null
      ))
      .filter((value, index, self) -> self.indexOf(value) == index)

  selectionHasExistingPlannings: ->
    @getSelectedPercentValues().find((v) => v != '')

  init: ->
    if $(selectable).length == 0
      return

    $(document).on('click', @clear)
    $(selectable).selectable({
      filter: selectee,
      classes: {
        'ui-selected': '-selected'
      }
      start,
      stop,
      selecting,
      unselecting
    })

  destroy: ->
    $(document).off('click', @clear)

$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()
