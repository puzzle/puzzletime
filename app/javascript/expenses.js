$(document).on('ready, turbolinks:load', function () {
  // scope to single controller
  if (!$('body.expenses').length &&
                !$('body.expenses_reviews').length) { return }

  const expenseKindInput = $('#expense_kind')
  const orderInput = $('#expense_order_id')
  const orderSelectizedInput = $('#expense_order_id-selectized')
  const orderFormGroup = orderInput.closest('.form-group')
  const receiptInput = $('#expense_receipt')
  const warningPopup = $('#file_warning')

  const toggleProjectDisplay = function () {
    if (expenseKindInput.val() === 'project') {
      orderFormGroup.show()
      return orderSelectizedInput.attr('disabled', false)
    } else {
      orderFormGroup.hide()
      return orderSelectizedInput.attr('disabled', true)
    }
  }

  const checkFileType = function () {
    warningPopup.addClass('hidden')

    if (!receiptInput[0] || (receiptInput[0].files.length <= 0)) { return }

    const fileType = receiptInput[0].files[0].type

    if (!/^image/.test(fileType) && (fileType !== 'application/pdf')) {
      return warningPopup.removeClass('hidden')
    }
  }

  checkFileType()
  toggleProjectDisplay()

  expenseKindInput.change(e => toggleProjectDisplay())

  return receiptInput.change(e => checkFileType())
})
