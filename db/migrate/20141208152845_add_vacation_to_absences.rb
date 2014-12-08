class AddVacationToAbsences < ActiveRecord::Migration
  def change
    add_column :absences, :vacation, :boolean, null: false, default: false

    Absence.where(name: 'Ferien').update_all(vacation: true)
  end
end
