class CreateAdditionalCrmOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :additional_crm_orders do |t|
      t.belongs_to :order, null: false, index: true
      t.string :crm_key, null: false
      t.string :name
    end
  end
end
