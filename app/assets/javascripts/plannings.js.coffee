app = window.App ||= {}
app.plannings ||= {}

app.plannings = new class
  board = '.planning-calendar'
  add_employee_select = null
  add_employee_selectize = null
  add_employee_options = []

  init: ->
    @initListeners()
    @initSelectize()

  destroy: ->
    @destroyListeners()

  add: (event) =>
    @showSelect(event)

  showSelect: (event) ->
    work_item_id = $(event.target).closest('.actions').data('work-item-id')
    add_employee_selectize.setValue(null)
    add_employee_selectize.clearOptions()
    add_employee_options
      .filter((option) -> option?.value)
      .forEach((option) =>
        employee_id = option.value
        return if @board().has("#planning_row_employee_#{employee_id}_work_item_#{work_item_id}").length

        add_employee_selectize.addOption(option)
      )

    $(event.target)
      .closest('.buttons')
      .prepend(add_employee_select)

    @board('.add').show()
    $(event.target).hide()
    add_employee_select.show()
    requestAnimationFrame(() => add_employee_selectize.refreshOptions())

  add_employee: (employee_id, work_item_id) ->
    app.plannings.service
      .addPlanningRow(employee_id, work_item_id)
      .then(() =>
        add_employee_select.detach()

        @board('.add').show()
      )

  initListeners: ->
    @board().on('click', '.actions .add', @add)

  initSelectize: ->
    add_employee_select = $('#add_employee_id')
    add_employee_selectize = add_employee_select
      .children('select')
      .selectize(
        selectOnTab: true
        dropdownParent: 'body'
        onItemAdd: (value) =>
          if value
            employee_id = value
            work_item_id = add_employee_select
              .closest('.actions')
              .data('work-item-id')

            @add_employee(employee_id, work_item_id)
      )
      .get(0).selectize

    add_employee_options = [
      undefined,
      Object.keys(add_employee_selectize.options)
        .map((key) -> add_employee_selectize.options[key])...
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
