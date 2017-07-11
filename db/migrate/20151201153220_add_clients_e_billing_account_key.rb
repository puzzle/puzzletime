class AddClientsEBillingAccountKey < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :e_bill_account_key, :string
  end
end
