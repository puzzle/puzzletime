# frozen_string_literal: true

class RenameIdentificationFields < ActiveRecord::Migration[5.2]
  def change
    rename_column :employees, :identification_type, :identity_card_type
    rename_column :employees, :identification_valid_until, :identity_card_valid_until
  end
end
