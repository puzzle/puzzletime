# frozen_string_literal: true

class AddGraduationToEmployees < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :graduation, :string
  end
end
