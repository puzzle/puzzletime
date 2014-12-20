class AddSlaToContract < ActiveRecord::Migration
  def change
    change_table :contracts, bulk: true do |t|
      t.column :sla, :text
      reversible do |dir|
        dir.up do
          t.change :reference, :text
          t.change :payment_period, :integer, null: false
          t.change :start_date, :date, null: false
          t.change :end_date, :date, null: false
        end
        dir.down do
          t.change :end_date, :date
          t.change :start_date, :date
          t.change :payment_period, :integer
          t.change :reference, :string
        end
      end
    end
  end
end
