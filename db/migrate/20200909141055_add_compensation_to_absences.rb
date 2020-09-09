class AddCompensationToAbsences < ActiveRecord::Migration[5.2]
  def change
    add_column :absences, :compensation, :boolean, null: false, default: false
  end
end
