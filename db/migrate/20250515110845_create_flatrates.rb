# frozen_string_literal: true

class CreateFlatrates < ActiveRecord::Migration[7.1]
  def change
    create_table :flatrates do |t|
      t.string :name
      t.date 'active_from', null: false
      t.date 'active_to'
      t.text :description
      t.decimal :amount
      t.integer :periodicity, array: true, default: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      t.references :accounting_post, foreign_key: true
      t.integer :unit
      t.timestamps
    end

    create_table :invoice_flatrates do |t|
      t.references :flatrate, foreign_key: true
      t.references :invoice, foreign_key: true
      t.integer :quantity
      t.string :comment

      t.timestamps
    end

    add_index :invoice_flatrates, %i[invoice_id flatrate_id], unique: true
  end
end
