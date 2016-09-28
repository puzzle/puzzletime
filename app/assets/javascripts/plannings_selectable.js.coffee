app = window.App ||= {}
app.plannings ||= {}

app.plannings.selectable = new class
  selectable = '.planning-calendar-inner.editable'
  selectee = '.planning-calendar-days > .day'
  isSelecting = false

  init: ->
    return if @selectable().length == 0

    @bindListeners()
    @selectable().selectable({
      filter: selectee,
      cancel: 'a, .actions',
      classes: {
        'ui-selected': '-selected'
      },
      start: @start,
      stop: @stop,
      selecting: @selecting,
      unselecting: @unselecting
    })

  destroy: ->
    @bindListeners(true)
    @selectable().selectable('destroy') if @selectable().selectable('instance')

  bindListeners: (unbind) ->
    func = if unbind then 'off' else 'on'

    $(document)[func]('click', @clear)
    $(document)[func]('keyup', @clearOnEscape)

    @selectable()[func]('click', @stopPropagation)
    @selectable()[func]('mousedown', '.ui-selected', @startTranslate)

  clear: (e) =>
    unless @preventClear(e)
      @selectable('.ui-selected').removeClass('ui-selected -selected')
      app.plannings.panel.hide()

  preventClear: (e) =>
    ignoredContainers = '.panel, .ui-datepicker'
    e && ($(e.target).closest(ignoredContainers).length ||
      $(e.target).is(':hidden') # ignore clicks on detached nodes (i.e. datepicker previous/next)
    )

  clearOnEscape: (event) =>
    if event.key == 'Escape'
      @clear()

  stopPropagation: (event) -> event.stopPropagation()

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

  startTranslate: (e) =>
    return unless e.shiftKey
    e.stopPropagation()

    currentlySelected = @selectable('.ui-selected')
    children = e.target.parentNode.children
    startNodeIndex = $(children).index(e.target)
    selectedIndexes = Array.from(currentlySelected, (el) ->
      $(el.parentNode.children).index(el)
    )
    minTranslateBy = -selectedIndexes.reduce((a, b) -> Math.min(a, b))
    maxSelectedIndex = selectedIndexes.reduce((a, b) -> Math.max(a, b))
    maxTranslateBy = children.length - maxSelectedIndex
    translateBy = 0
    getRows = (elements) -> $.unique(elements.map(-> @parentNode))
    originalRows = getRows(currentlySelected).clone()

    @selectable().on('mousemove', (e) =>
      if e.target.matches('.day')
        e.stopPropagation()

        app.plannings.panel.hide()

        currentNodeIndex = $(e.target.parentNode.children).index(e.target)
        currentTranslateBy = currentNodeIndex - startNodeIndex

        return if translateBy == currentTranslateBy ||
          currentTranslateBy <= minTranslateBy ||
          currentTranslateBy >= maxTranslateBy

        translateBy = currentTranslateBy

        @resetCellsOfRows(
          getRows(@selectable('.ui-selected')),
          originalRows,
          translateBy
        )
        @translateDays(currentlySelected, translateBy)
    )

    @selectable().on('mouseup', (e) =>
      @selectable().off('mousemove')
      @updateDayTranslation()
    )

  resetCellsOfRows: (rows, originalRows, unselect) ->
    Array.from(rows, (row, i) ->
      Array.from(row.children, (cell, j) ->
        cell.innerHTML = originalRows[i].children[j].innerHTML
        cell.className = originalRows[i].children[j].className
        cell.classList.remove('ui-selected', '-selected') if unselect
        cell
      )
    )

  translateDays: (days, translateBy) ->
    return unless translateBy

    Array
      .from(days, (el) -> [
        $(el.parentNode.children).index(el)
        el.parentNode
      ])
      .map(([ i, parentNode ]) -> [
        parentNode.children[i]
        parentNode.children[i + translateBy]
      ])
      .do(-> @reverse() if translateBy > 0)
      .forEach(([ from, to ]) ->
        to.innerHTML = from.innerHTML
        to.className = from.className
        from.className = 'day'
        from.innerHTML = ''
        to.classList.add('ui-selected', '-selected')
      )

  updateDayTranslation: ->
    console.log('updateDayTranslation')


$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()
