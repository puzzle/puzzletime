class AddVersionsEmployeeId < ActiveRecord::Migration[5.2]
  def change
    add_reference :versions, :employee
  end
end
