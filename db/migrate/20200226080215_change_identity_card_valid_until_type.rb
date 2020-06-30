# frozen_string_literal: true

class ChangeIdentityCardValidUntilType < ActiveRecord::Migration[5.2]
  def up
    change_column :employees, :identity_card_valid_until, :date
  end

  def down
    change_column :employees, :identity_card_valid_until, :datetime
  end
end
