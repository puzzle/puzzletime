# frozen_string_literal: true

class AddNationalitiesOnEmployee < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :nationalities, :string, array: true
  end
end
