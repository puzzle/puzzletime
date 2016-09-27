app = window.App ||= {}
app.plannings ||= {}

app.plannings.selectable = new class
  selectable = '.planning-calendar-inner'
  selectee = '.planning-calendar-days > .day'
  isSelecting = false

  init: ->
    if @selectable().length == 0
      return

    $(document).on('click', @clear)
    @selectable().selectable({
      filter: selectee,
      classes: {
        'ui-selected': '-selected'
      },
      start: @start,
      stop: @stop,
      selecting: @selecting,
      unselecting: @unselecting
    })

  destroy: ->
    $(document).off('click', @clear)

  clear: (e) =>
    unless e && $(e.target).closest('.panel').length
      @selectable('.ui-selected').removeClass('ui-selected -selected')
      app.plannings.panel.hide()

  getSelectedDays: ->
    @selectable('.ui-selected')
      .toArray()
      .map((element) =>
        row = $(element).parent()
        [ _match, employee_id, work_item_id ] = row.prop('id')
          .match(/planning_row_employee_(\d+)_work_item_(\d+)/)
        date = @selectable('.planning-calendar-days-header .dayheader')
          .eq(row.children('.day').index(element)).data('date')

        { employee_id, work_item_id, date }
      )

  getSelectedPlanningIds: ->
    @selectable('.ui-selected')
      .toArray()
      .map((el) -> el.dataset.id)
      .filter((id) -> id)

  getSelectedPercentValues: ->
    @selectable('.ui-selected')
      .toArray()
      .map((element) -> $(element).text().trim())
      .filter((value, index, self) -> self.indexOf(value) == index)

  getSelectedDefinitiveValues: ->
    @selectable('.ui-selected')
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

  start: (event, ui) ->
    isSelecting = true
    setTimeout((-> isSelecting && app.plannings.panel.hide()), 100) # avoid flickering

  stop: (event, ui) ->
    isSelecting = false
    selectedElements = $(event.target).find('.ui-selected')
    selectedElements.addClass('-selected')

    if selectedElements.length > 0
      app.plannings.panel.show(selectedElements)

  selecting: (event, ui) ->
    $(ui.selecting).addClass('-selected')

  unselecting: (event, ui) ->
    $(ui.unselecting).removeClass('-selected')

  selectable: (selector) ->
    if selector
      $(selector, selectable)
    else
      $(selectable)

$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()
