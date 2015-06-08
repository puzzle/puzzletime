class AddGroupingToInvoice < ActiveRecord::Migration
  def change
    change_table :invoices, batch: true do |t|
      t.column :grouping, :integer, default: 0, length: 1, null: false
    end
  end
  # def up
  #   execute <<-SQL
  #     CREATE TYPE invoice_grouping AS ENUM ('accounting_posts', 'employees', 'manual')
  #   SQL
  #
  #   add_column :invoices, :grouping, :invoice_grouping, default: 'accounting_posts', null: false
  # end
  # def down
  #   remove_column :invoices, :grouping
  #
  #   execute <<-SQL
  #     DROP TYPE invoice_grouping;
  #   SQL
  # end
end
