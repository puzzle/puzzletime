# frozen_string_literal: true

class AddBillingReminderActiveToAccountingPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounting_posts, :billing_reminder_active, :boolean, default: true, null: false
  end
end
