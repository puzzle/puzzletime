class RemoveObsoleteEmployeePasswd < ActiveRecord::Migration[7.0]
  def change
    remove_column :employees, :passwd, :string
  end
end
