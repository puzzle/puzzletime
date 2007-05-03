class UserNotifications < ActiveRecord::Migration
  def self.up
    create_table :user_notifications do |t|      
      t.column :date_from, :date, :null => false
      t.column :date_to, :date, :null => true
      t.column :message, :text, :null => false
    end
    Holiday.find(:all).each do |holiday|
      holiday.createUserNotification
    end
  end

  def self.down
    drop_table :user_notifications
  end
end
