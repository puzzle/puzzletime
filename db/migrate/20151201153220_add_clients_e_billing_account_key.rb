class AddClientsEBillingAccountKey < ActiveRecord::Migration
  def change
    add_column :clients, :e_bill_account_key, :string
  end
end
