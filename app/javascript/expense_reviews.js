$(document).on('turbolinks:load', function() {
  $('.js-toggle-inlineedit').on('click', function(e) {
    e.preventDefault();
    $('.inlineedit').toggleClass('hidden');
  });

  const reimbursement    = $('#expense_reimbursement_date');
  const reason           = $('#expense_reason');
  const approve_button   = $('#approve_btn');
  const reject_button    = $('#reject_btn');

  const toggle_approve_button = function() {
    const switch_to = (reimbursement.val() === '');
    return approve_button.prop('disabled', switch_to);
  };

  const toggle_reject_button = function() {
    const switch_to = ((reason.val() === '') || (reimbursement.val() !== ''));
    return reject_button.prop('disabled', switch_to);
  };

  toggle_approve_button();
  toggle_reject_button();

  reimbursement.change(function(e) {
    toggle_approve_button();
    return toggle_reject_button();
  });

  reason.change(e => toggle_reject_button());

  return reason.keyup(e => toggle_reject_button());
});
