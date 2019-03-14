$(document).on 'turbolinks:load', ->
  return unless $('body.expenses').length > 0 # scope to single controller

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

  check_file_type = (initial = false) ->
    input = $('#expense_receipt')[0]
    files = input.files
    warning = $('#file_warning')

    warning.addClass('hidden')
    return unless files.length > 0
    return if     /^image/.test(files[0].type)

    warning.removeClass('hidden') unless initial
    input.value = ''

  check_file_type(true)
  toggle_project_display()

  $('#expense_kind').change (e) ->
    toggle_project_display()

  $('#expense_receipt').change (e) ->
    check_file_type()
