app = window.App ||= {}
app.plannings ||= {}

app.plannings = new class
  board = '.planning-calendar'
  addRowSelect = null
  addRowSelectize = null
  addRowOptions = []
  waypoints = []
  positioningHeaders = false

  init: ->
    @bindListeners()
    @dateFilterChanged()
    @initSelectize()
    @initGroupheaders()
    @initWaypoints()
    @positionHeaders()

  destroy: ->
    @bindListeners(true)
    @destroyWaypoints()

  reloadAll: ->
    [@, app.plannings.selectable, app.plannings.panel].forEach((p) =>
      p.destroy()
      p.init()
    )

  dateFilterChanged: ->
    $('#planning_filter_form').find('#start_date,#end_date').closest('.form-group')
      .css('visibility', if !$('#period_shortcut').val() then 'visible' else 'hidden')

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
    $('main')[func]('scroll', @positionHeaders)

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

  initGroupheaders: ->
    $('.groupheader').click (e) ->
      return if $(e.target).hasClass('day')

      collapsed = $(this).hasClass('collapsed')

      $(this)
        .toggleClass('collapsed', !collapsed)
        .find('.glyphicon')
          .toggleClass('glyphicon-chevron-left', !collapsed)
          .toggleClass('glyphicon-chevron-down', collapsed)
        .end()
        .nextUntil('.groupheader')
        .toggle(collapsed)

      if collapsed
        $(this).children().removeClass('has-planning')

        if $(this).next('.actions').length
          $(this).next('.actions').find('.add').click()
      else
        children = $(this).children()

        $(this)
          .nextUntil('.actions')
          .find('.day')
          .filter('.-definitive,.-provisional')
          .map -> children.get($(this.parentNode.children).index(this))
          .addClass('has-planning')


    $('.groupheader')
      .filter -> $(this).next('.actions').length
      .click()

  initWaypoints: ->
    return if Modernizr.csspositionsticky
    waypoints = []

    @initTopCalendarHeaderWaypoints()
    @initLeftCalendarHeaderWaypoints()

  initTopCalendarHeaderWaypoints: ->
    $('.planning-calendar')
      .toArray()
      .map (el) ->
        [
          $(el).find('.planning-calendar-weeks')
          $(el).find('.planning-calendar-days-header')
        ]
      .forEach ([ weeks, daysHeader ]) ->
        waypoints.push(new Waypoint.Sticky(
          element: weeks
          context: $('main')
        ))
        waypoints.push(new Waypoint.Sticky(
          element: daysHeader
          context: $('main')
        ))

  initLeftCalendarHeaderWaypoints: ->
    @getLeftCalendarHeaderElements().each (_i, element) ->
      waypoints.push(new Waypoint.Sticky(
        element: element
        context: $('main')
        horizontal: true
      ))

  positionHeaders: =>
    unless positioningHeaders
      requestAnimationFrame(=>
        @positionBoardHeader()

        unless Modernizr.csspositionsticky
          $('.planning-calendar-weeks,.planning-calendar-days-header').each((_i, element) =>
            @positionTopCalendarHeader(element))
          @getLeftCalendarHeaderElements().each((_i, element) =>
            @positionLeftCalendarHeader(element))

        positioningHeaders = false
      )
    positioningHeaders = true

  positionBoardHeader: ->
    $('.planning-board-header').css('left', $(document).scrollLeft() + 'px')

  positionTopCalendarHeader: (element) ->
    if $(element).hasClass('stuck')
      leftHeaderWidth = 300
      firstDay = $(element)
        .closest('.planning-calendar-inner')
        .find('.day:first')
      offset = firstDay[0]?.getBoundingClientRect().left - leftHeaderWidth
      $(element).css('left', offset + 'px')
    else
      $(element).css('left', 'auto')

  positionLeftCalendarHeader: (element) ->
    if $(element).hasClass('stuck')
      offset = $(element)
        .closest('.sticky-wrapper')[0]
        .getBoundingClientRect().top
      $(element).css('top', offset + 'px')
    else
      $(element).css('top', 'auto')

  getLeftCalendarHeaderElements: ->
    $(['.planning-calendar-inner > .groupheader .legend',
       '.planning-calendar-inner > .actions .buttons',
       '.planning-calendar-days .legend',
       '.planning-board-header',
       '.planning-legend'
      ].join(','))

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
