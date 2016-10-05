app = window.App ||= {}
app.plannings ||= {}

app.plannings = new class
  board = '.planning-calendar'
  addRowSelect = null
  addRowSelectize = null
  addRowOptions = []
  waypoints = []
  positioningWaypoints = false

  init: ->
    @bindListeners()
    @initSelectize()
    @initWaypoints()

  destroy: ->
    @bindListeners(true)
    @destroyWaypoints()

  reloadAll: ->
    [@, app.plannings.selectable, app.plannings.panel].forEach((p) =>
      p.destroy()
      p.init()
    )

  dateFilterChanged: ->
    $('#start_date,#end_date').closest('.form-group')
      .css('visibility', if !$('#period').val() then 'visible' else 'hidden')

  add: (event) =>
    @showSelect(event)

  showSelect: (event) ->
    actionData = $(event.target).closest('.actions').data()
    addRowSelectize.setValue(null)
    addRowSelectize.clearOptions()
    addRowOptions
      .filter((option) -> option?.value)
      .forEach((option) =>
        actionData["#{actionData.type}Id"] = option.value

        return if @board().has("#planning_row_employee_#{actionData.employeeId}_work_item_#{actionData.workItemId}").length

        addRowSelectize.addOption(option)
      )

    $(event.target)
      .closest('.buttons')
      .prepend(addRowSelect)

    @board('.add').show()
    $(event.target).hide()
    addRowSelect.show()
    requestAnimationFrame(() => addRowSelectize.refreshOptions())

  addRow: (employeeId, workItemId) ->
    app.plannings.service
      .addPlanningRow(employeeId, workItemId)
      .then(() =>
        addRowSelect.hide()

        @board('.add').show()
      )

  onAddSelect: (value) =>
    if value
      if addRowSelect.is('#add_employee_id')
        employeeId = value
        workItemId = addRowSelect
          .closest('.actions')
          .data('work-item-id')
      else if addRowSelect.is('#add_work_item_id')
        workItemId = value
        employeeId = addRowSelect
          .closest('.actions')
          .data('employee-id')
      else
        throw new Error('Unknown select!')

      @addRow(employeeId, workItemId)

  bindListeners: (unbind) ->
    func = if unbind then 'off' else 'on'

    @board('.actions .add')[func]('click', @add)
    $(document)[func]('scroll', @positionWaypoints) unless Modernizr.csspositionsticky

  initSelectize: ->
    addRowSelect = $('#add_employee_id,#add_work_item_id')
    addRowSelectize = addRowSelect
      .children('select')
      .selectize(
        selectOnTab: true
        dropdownParent: 'body'
        onItemAdd: @onAddSelect
      )
      .get(0)?.selectize

    return unless addRowSelectize

    addRowOptions = [
      undefined,
      Object.keys(addRowSelectize.options)
        .map((key) -> addRowSelectize.options[key])...
    ]

  initWaypoints: ->
    return if Modernizr.csspositionsticky
    waypoints = []

    @initTopHeaderWaypoints();
    @initLeftHeaderWaypoints();

  initTopHeaderWaypoints: ->
    $('.planning-calendar').each((_i, element) ->
      navHeight = 140
      planningHeaderHeight = $(element).find('.planning-calendar-weeks')[0].clientHeight +
        $(element).find('.planning-calendar-days-header')[0].clientHeight
      waypoints.push(new Waypoint.Sticky({
        element: $(element).find('.planning-calendar-weeks'),
        offset: navHeight
      }))
      waypoints.push(new Waypoint.Sticky({
        element: $(element).find('.planning-calendar-days-header'),
        offset: navHeight
      }))
      waypoints.push(new Waypoint({
        element: element,
        handler: ((direction) ->
          headerElements = $('.planning-calendar-weeks,.planning-calendar-days-header', element)
          if direction == 'down'
            headerElements.removeClass('stuck')
          if direction == 'up'
            headerElements.addClass('stuck')
        ),
        offset: () -> navHeight - this.element.clientHeight + planningHeaderHeight
      }))
    )

  initLeftHeaderWaypoints: ->
    @getLeftHeaderElements().each((_i, element) ->
      waypoints.push(new Waypoint.Sticky({ element: element, horizontal: true }))
    )

  positionWaypoints: =>
    unless positioningWaypoints
      requestAnimationFrame(=>
        $('.planning-calendar-weeks,.planning-calendar-days-header').each((_i, element) =>
          @positionTopHeaderWaypoint(element)
        )

        @getLeftHeaderElements().each((_i, element) =>
          @positionLeftHeaderWaypoint(element)
        )

        positioningWaypoints = false
      )
    positioningWaypoints = true

  positionTopHeaderWaypoint: (element) ->
    if $(element).hasClass('stuck')
      firstDay = $(element).parent().parent().find('.day:first')
      offset = firstDay[0].getBoundingClientRect().left - 300
      $(element).css('left', offset + 'px')
    else
      $(element).css('left', 'auto')

  positionLeftHeaderWaypoint: (element) ->
    if $(element).hasClass('stuck')
      offset = $(element).parent().parent()[0].getBoundingClientRect().top
      $(element).css('top', offset + 'px')
    else
      $(element).css('top', 'auto')

  getLeftHeaderElements: ->
    $(['.planning-calendar-inner > .groupheader strong',
       '.planning-calendar-inner > .actions .buttons',
       '.planning-calendar-days .legend'].join(','))

  destroyWaypoints: ->
    waypoints.forEach((waypoint) -> waypoint.destroy())
    waypoints = []

  board: (selector) ->
    if selector
      $(selector, board)
    else
      $(board)

$ ->
  app.plannings.destroy()
  app.plannings.init()
