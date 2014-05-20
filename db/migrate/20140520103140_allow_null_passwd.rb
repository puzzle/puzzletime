class AllowNullPasswd < ActiveRecord::Migration
  def change
    change_column :employees, :passwd, :string, null: true
  end
end
