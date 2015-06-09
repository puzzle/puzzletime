class CreateInvoices < ActiveRecord::Migration
  def up
    create_table :invoices do |t|
      t.belongs_to :order, null: false
      t.date :billing_date, null: false
      t.date :due_date, null: false
      t.decimal :total_amount, null: false, precision: 12, scale: 2
      t.float :total_hours, null: false
      t.string :reference, null: false, unique: true #(seq numb 4 digits)
      t.date :period_from, null: false
      t.date :period_to, null: false
      t.string :status, null: false
      t.boolean :add_vat, null: false, default: true
      t.belongs_to :billing_address, null: false
      t.string :invoicing_key
      
      t.timestamps
    end

    add_index :invoices, :order_id
    add_index :invoices, :billing_address_id

    add_column :clients, :last_invoice_number, :integer, default: 0

    add_column :worktimes, :invoice_id, :integer
    add_index :worktimes, :invoice_id

    add_column :clients, :invoicing_key, :string
    add_column :billing_addresses, :invoicing_key, :string
    add_column :contacts, :invoicing_key, :string

    change_column :billing_addresses, :contact_id, :integer, null: true
    change_column :billing_addresses, :country, :string, limit: 2
  end

  def down
    remove_column :contacts, :invoicing_key
    remove_column :billing_addresses, :invoicing_key
    remove_column :clients, :invoicing_key

    remove_column :worktimes, :invoice_id
    remove_column :clients, :last_invoice_number

    drop_table :invoices
  end
end
