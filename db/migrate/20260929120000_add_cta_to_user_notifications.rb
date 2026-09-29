# frozen_string_literal: true

# Adds an optional call to action link (url and label) to user notifications.
class AddCtaToUserNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :user_notifications, :cta_url, :string
    add_column :user_notifications, :cta_text, :string
  end
end
