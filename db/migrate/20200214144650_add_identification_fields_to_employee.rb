class AddIdentificationFieldsToEmployee < ActiveRecord::Migration[5.2]
  def change
    add_column :employees, :identification_type, :string
    add_column :employees, :identification_valid_until, :datetime
  end
end
