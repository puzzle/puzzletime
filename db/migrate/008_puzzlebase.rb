class Puzzlebase < ActiveRecord::Migration
  def self.up
    add_column :clients, :shortname, :string, :limit => 4, :null => false
    remove_column :clients, :contact
    add_column :projects, :shortname, :string, :limit => 3, :null => false
    
    setShortnames ::Client, 4
    setShortnames ::Project, 3
    ::Employee.find(:all).each do |entry|
      entry.update_attribute(:shortname, entry.shortname.upcase)
    end
  end

  def self.down
    remove_column :clients, :shortname
    remove_column :projects, :shortname
    add_column :clients, :contact, :null => false
  end
  
  def self.setShortnames(clazz, length)
    clazz.find(:all).each do |entry|
      entry.update_attribute(:shortname, entry.name.upcase.slice(0..(length-1)))
    end
  end
end
