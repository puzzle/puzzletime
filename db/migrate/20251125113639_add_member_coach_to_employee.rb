# frozen_string_literal: true

class AddMemberCoachToEmployee < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :member_coach_id, :integer
  end
end
