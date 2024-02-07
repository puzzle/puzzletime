# frozen_string_literal: true

class AddSubmissionDateToExpense < ActiveRecord::Migration[5.2]
  def change
    add_column :expenses, :submission_date, :date, default: -> { 'NOW()' }
  end
end
