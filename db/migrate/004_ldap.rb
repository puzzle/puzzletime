class Ldap < ActiveRecord::Migration
  def self.up
     add_column :employees, :ldapname, :string
     remove_column :employees, :phone
  end

  def self.down
     add_column :employees, :phone, :string
     remove_column :employees, :ldapname
  end
end
