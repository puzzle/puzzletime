app = window.App ||= {}
app.plannings ||= {}

app.plannings = new class
  board = '.planning-calendar'
  addEmployeeSelect = null
  addEmployeeSelectize = null
  addEmployeeOptions = []

  init: ->
    @initListeners()
    @initSelectize()

  destroy: ->
    @destroyListeners()

  add: (event) =>
    @showSelect(event)

  showSelect: (event) ->
    work_item_id = $(event.target).closest('.actions').data('work-item-id')
    addEmployeeSelectize.setValue(null)
    addEmployeeSelectize.clearOptions()
    addEmployeeOptions
      .filter((option) -> option?.value)
      .forEach((option) =>
        employee_id = option.value
        return if @board().has("#planning_row_employee_#{employee_id}_work_item_#{work_item_id}").length

        addEmployeeSelectize.addOption(option)
      )

    $(event.target)
      .closest('.buttons')
      .prepend(addEmployeeSelect)

    @board('.add').show()
    $(event.target).hide()
    addEmployeeSelect.show()
    requestAnimationFrame(() => addEmployeeSelectize.refreshOptions())

  addEmployee: (employee_id, work_item_id) ->
    app.plannings.service
      .addPlanningRow(employee_id, work_item_id)
      .then(() =>
        addEmployeeSelect.detach()

        @board('.add').show()
      )

  initListeners: ->
    @board().on('click', '.actions .add', @add)

  initSelectize: ->
    addEmployeeSelect = $('#add_employee_id')
    addEmployeeSelectize = addEmployeeSelect
      .children('select')
      .selectize(
        selectOnTab: true
        dropdownParent: 'body'
        onItemAdd: (value) =>
          if value
            employee_id = value
            work_item_id = addEmployeeSelect
              .closest('.actions')
              .data('work-item-id')

            @addEmployee(employee_id, work_item_id)
      )
      .get(0).selectize

    addEmployeeOptions = [
      undefined,
      Object.keys(addEmployeeSelectize.options)
        .map((key) -> addEmployeeSelectize.options[key])...
    ]

  destroyListeners: ->
    @board().off('click', @add)

  board: (selector) ->
    if selector
      $(selector, board)
    else
      $(board)

$ ->
  app.plannings.destroy()
  app.plannings.init()
