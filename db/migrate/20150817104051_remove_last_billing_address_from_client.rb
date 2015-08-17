class RemoveLastBillingAddressFromClient < ActiveRecord::Migration
  def change
    remove_column :clients, :last_billing_address_id
  end
end
