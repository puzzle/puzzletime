$(document).on 'turbolinks:load', ->
  toggle_project_display = () ->
    kind          = $('#expense_kind :selected')
    order         = $('#expense_order_id')
    form_group    = order.closest('.form-group')
    input         = form_group.find('input')

    kind.each ->
      if this.value == 'project'
        form_group.show()
        input[0].required = true
      else
        form_group.hide()
        input[0].required = false

  toggle_project_display()

  $('#expense_kind').change (e) ->
    toggle_project_display()
