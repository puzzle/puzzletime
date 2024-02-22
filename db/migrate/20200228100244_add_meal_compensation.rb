# frozen_string_literal: true

class AddMealCompensation < ActiveRecord::Migration[5.2]
  def change
    add_column :accounting_posts, :meal_compensation, :boolean, default: false, null: false
    add_column :worktimes, :meal_compensation, :boolean, default: false, null: false
  end
end
