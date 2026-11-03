# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Mirrors ExpensesController: management sees and edits every expense, employees their own (the api client none).
# The status and its review data are only set by the review operation (Api::V2::ExpensesController#review), never
# through CRUD. The receipt is an operation as well (PUT/GET /expenses/:id/receipt).
class ExpenseResource < ApplicationResource
  model Expense

  self.default_sort = [{ payment_date: :desc }]

  attribute :employee_id, :integer, writable: :management?
  attribute :kind, :string_enum, allow: Expense.kinds.keys
  attribute :amount, :big_decimal
  attribute :payment_date, :date
  attribute :description, :string
  attribute :order_id, :integer
  attribute :status, :string_enum, allow: Expense.statuses.keys, writable: false
  attribute :reason, :string, writable: false
  attribute :reviewer_id, :integer, writable: false
  attribute :reviewed_at, :datetime, writable: false
  attribute :reimbursement_date, :date, writable: false
  attribute :submission_date, :date, writable: false

  belongs_to :employee

  class << self
    # Employees cannot touch their approved expenses any more (ExpensesController#with_protected_approved_state).
    def assert_not_approved(expense, user)
      return unless expense.approved? && !user.management?

      raise CanCan::AccessDenied, 'Freigegebene Spesen können nicht verändert werden.'
    end

    # An owner editing a rejected expense resubmits it (ExpensesController#update).
    def resubmit_rejected(expense, user)
      return unless expense.rejected? && expense.employee_id == user.id

      expense.submission_date = Time.zone.today
      expense.status = :pending
    end
  end

  def base_scope
    own_or_all(Expense.all)
  end

  before_attributes only: [:create] do |attributes|
    attributes[:employee_id] ||= context.current_user.id if context.current_user.is_a?(Employee)
  end

  before_save only: [:update] do |expense|
    self.class.assert_not_approved(expense, context.current_user)
    self.class.resubmit_rejected(expense, context.current_user)
  end

  before_destroy do |expense|
    self.class.assert_not_approved(expense, context.current_user)
  end
end
