# frozen_string_literal: true

class AddPlanningNoteToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :planning_note, :text
  end
end
