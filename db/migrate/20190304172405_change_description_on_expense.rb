class ChangeDescriptionOnExpense < ActiveRecord::Migration[5.2]
  def change
    change_column_null :expenses, :description, false, '(empty)'
  end
end
