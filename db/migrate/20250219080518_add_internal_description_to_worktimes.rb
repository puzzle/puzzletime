# frozen_string_literal: true

class AddInternalDescriptionToWorktimes < ActiveRecord::Migration[7.1]
  def change
    add_column :worktimes, :internal_description, :text
  end
end
