# frozen_string_literal: true

class CreateWorkplaces < ActiveRecord::Migration[5.2]
  def change
    create_table :workplaces do |t|
      t.string :name
    end
    add_reference :employees, :workplace
  end
end
