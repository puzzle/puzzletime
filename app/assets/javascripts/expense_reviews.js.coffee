$(document).on 'turbolinks:load', ->
  reimbursement    = $('#expense_reimbursement_date')
  reason           = $('#expense_reason')
  approve_button   = $('#approve_btn')
  reject_button    = $('#reject_btn')

  toggle_approve_button = () ->
    switch_to = (reimbursement.val() == '')
    approve_button.prop('disabled', switch_to)

  toggle_reject_button = () ->
    switch_to = (reason.val() == '' || reimbursement.val() != '')
    reject_button.prop('disabled', switch_to)

  toggle_approve_button()
  toggle_reject_button()

  reimbursement.change (e) ->
    toggle_approve_button()
    toggle_reject_button()

  reason.change (e) ->
    toggle_reject_button()

  reason.keyup (e) ->
    toggle_reject_button()
