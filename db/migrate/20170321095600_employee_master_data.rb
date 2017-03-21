class EmployeeMasterData < ActiveRecord::Migration
  def change
    add_column :employees, :phone_office, :string
    add_column :employees, :phone_private, :string
    add_column :employees, :street, :string
    add_column :employees, :postal_code, :string
    add_column :employees, :city, :string
    add_column :employees, :birthday, :date
    add_column :employees, :emergency_contact_name, :string
    add_column :employees, :emergency_contact_phone, :string
    add_column :employees, :marital_status, :integer
    add_column :employees, :social_insurance, :string
    add_column :employees, :crm_key, :string
  end
end
