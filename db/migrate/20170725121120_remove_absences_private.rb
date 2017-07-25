class RemoveAbsencesPrivate < ActiveRecord::Migration[5.1]
  def change
    remove_column :absences, :private, :boolean, default: false, null: false
  end
end
