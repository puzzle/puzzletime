# frozen_string_literal: true

class AddIdToOrderContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :order_contacts, :id, :primary_key
  end
end
