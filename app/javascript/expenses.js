$(document).on('ready, turbolinks:load', function() {
  // scope to single controller
  if (!$('body.expenses').length &&
                !$('body.expenses_reviews').length) { return; }

  const expense_kind_input     = $('#expense_kind');
  const order_input            = $('#expense_order_id');
  const order_selectized_input = $('#expense_order_id-selectized');
  const order_form_group       = order_input.closest('.form-group');
  const receipt_input          = $('#expense_receipt');
  const warning_popup          = $('#file_warning');

  const toggle_project_display = function() {

    if (expense_kind_input.val() === 'project') {
      order_form_group.show();
      return order_selectized_input.attr('disabled', false);
    } else {
      order_form_group.hide();
      return order_selectized_input.attr('disabled', true);
    }
  };

  const check_file_type = function() {
    warning_popup.addClass('hidden');

    if (((typeof receipt_input === "undefined") || (receipt_input === null)) || (receipt_input[0].files.length <= 0)) { return; }

    const file_type = receipt_input[0].files[0].type;

    if (!/^image/.test(file_type) && (file_type !== 'application/pdf')) {
      return warning_popup.removeClass('hidden');
    }
  };

  check_file_type();
  toggle_project_display();

  expense_kind_input.change(e => toggle_project_display());

  return receipt_input.change(e => check_file_type());
});
