app = window.App ||= {}
app.plannings ||= {}

app.plannings = new class
  board = '.planning-calendar'
  addRowSelect = null
  addRowSelectize = null
  addRowOptions = []

  init: ->
    @initListeners()
    @initSelectize()

  destroy: ->
    @destroyListeners()

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
        addRowSelect.detach()

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

  initListeners: ->
    @board('.actions .add').click(@add)

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

  destroyListeners: ->
    @board('.actions .add').off(@add)

  board: (selector) ->
    if selector
      $(selector, board)
    else
      $(board)

$ ->
  app.plannings.destroy()
  app.plannings.init()
