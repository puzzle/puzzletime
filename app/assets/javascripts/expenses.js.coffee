$(document).on 'ready, turbolinks:load', ->
  # scope to single controller
  return unless $('body.expenses').length or
                $('body.expenses_reviews').length

  expense_kind_input     = $('#expense_kind')
  order_input            = $('#expense_order_id')
  order_selectized_input = $('#expense_order_id-selectized')
  order_form_group       = order_input.closest('.form-group')
  receipt_input          = $('#expense_receipt')
  warning_popup          = $('#file_warning')

  toggle_project_display = () ->

    if expense_kind_input.val() == 'project'
      # if order_input.value and not order_selectized_input.value
      #   input[0].value = ' '

      order_form_group.show()
      order_selectized_input.attr('disabled', false)
    else
      order_form_group.hide()
      order_selectized_input.attr('disabled', true)

  check_file_type = (initial = false) ->
    warning_popup.addClass('hidden')

    return unless receipt_input[0].files.length > 0
    return if     /^image/.test(receipt_input[0].files[0].type)

    warning_popup.removeClass('hidden')

  check_file_type(true)
  toggle_project_display()

  expense_kind_input.change (e) ->
    toggle_project_display()

  receipt_input.change (e) ->
    check_file_type()
