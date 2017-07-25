class RemoveInvoicesAddVat < ActiveRecord::Migration[5.1]
  def change
    remove_column :invoices, :add_vat, :boolean, default: true, null: false
  end
end
