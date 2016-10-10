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
      cancel: [
        'a'
        '.actions'
        '.legend'
      ].join(',')
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
      selected = @selectable('.ui-selected')
      if e?.type == 'selectablestart'
        # clear selections on other boards
        selected = @selectable().not(e.target).find('.ui-selected')

      selected.removeClass('ui-selected -selected')
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

  getSelectedDays: (elements = @selectable('.ui-selected')) ->
    elements
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
      .map((element) ->
        if $(element).hasClass('-definitive')
          true
        else if ($(element).hasClass('-provisional'))
          false
        else
          null
      )
      .filter((value, index, self) -> self.indexOf(value) == index)

  selectionHasExistingPlannings: ->
    @selectable('.ui-selected.-definitive,.ui-selected.-provisional').length > 0

  start: (event, ui) =>
    isSelecting = true
    @clear(event)
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
    return unless e.target.matches('.-definitive,.-provisional')
    e.stopPropagation()

    currentlySelected = @selectable('.ui-selected')
    daysToUpdate = @getSelectedDays(
      currentlySelected.filter('.-definitive,.-provisional')
    )
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
      e.stopPropagation()

      if e.target.matches('.day')
        app.plannings.panel.hide()

        currentNodeIndex = $(e.target.parentNode.children).index(e.target)
        currentTranslateBy = currentNodeIndex - startNodeIndex

        return unless currentTranslateBy

        translateBy = Math.max(
          minTranslateBy + 1,
          Math.min(maxTranslateBy - 1, currentTranslateBy)
        )

        @resetCellsOfRows(
          getRows(@selectable('.ui-selected')),
          originalRows,
          translateBy
        )
        @translateDays(currentlySelected, translateBy)
    )

    @selectable().on('mouseup', (e) =>
      @selectable().off('mousemove mouseup')
      @updateDayTranslation(daysToUpdate, translateBy)
    )

  resetCellsOfRows: (rows, originalRows, unselect) ->
    Array.from(rows, (row, i) ->
      Array.from(row.children, (cell, j) ->
        copyCell(cell, originalRows[i].children[j])
        cell.classList.remove('ui-selected', '-selected') if unselect
        cell
      )
    )

  copyCell = (to, from) ->
    to.innerHTML = from.innerHTML
    to.className = from.className
    to

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
        copyCell(to, from)
        to.classList.add('ui-selected', '-selected')
        from.className = 'day'
        from.innerHTML = ''
      )

  updateDayTranslation: (items, translateBy) ->
    app.plannings.service.update(
      "#{window.location.origin}#{window.location.pathname}",
      items: items
      planning:
        translate_by: translateBy
    )

$ ->
  app.plannings.selectable.destroy()
  app.plannings.selectable.init()
