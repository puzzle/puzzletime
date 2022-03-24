class FixEmployeesTimestampsDefault < ActiveRecord::Migration[5.2]
  def up
    change_column_default :employees, :created_at, -> { "now()" }
    change_column_default :employees, :updated_at, -> { "now()" }
  end
end
