$(document).on('turbolinks:load', function () {
  $('.js-toggle-inlineedit').on('click', function (e) {
    e.preventDefault()
    $('.inlineedit').toggleClass('hidden')
  })

  const reimbursement = $('#expense_reimbursement_date')
  const reason = $('#expense_reason')
  const approveButton = $('#approve_btn')
  const rejectButton = $('#reject_btn')

  const toggleApproveButton = function () {
    const switchTo = (reimbursement.val() === '')
    return approveButton.prop('disabled', switchTo)
  }

  const toggleRejectButton = function () {
    const switchTo = ((reason.val() === '') || (reimbursement.val() !== ''))
    return rejectButton.prop('disabled', switchTo)
  }

  toggleApproveButton()
  toggleRejectButton()

  reimbursement.change(function (e) {
    toggleApproveButton()
    return toggleRejectButton()
  })

  reason.change(e => toggleRejectButton())

  return reason.keyup(e => toggleRejectButton())
})
