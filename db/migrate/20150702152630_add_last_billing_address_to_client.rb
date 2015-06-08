class AddLastBillingAddressToClient < ActiveRecord::Migration
  def change
    change_table :clients do |t|
      t.column :last_billing_address_id, :integer
    end
  end
end
