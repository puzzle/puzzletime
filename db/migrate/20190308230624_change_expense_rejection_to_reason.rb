class ChangeExpenseRejectionToReason < ActiveRecord::Migration[5.2]
  def change
    rename_column :expenses, :rejection, :reason
  end
end
