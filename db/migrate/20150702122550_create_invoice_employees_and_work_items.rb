class CreateInvoiceEmployeesAndWorkItems < ActiveRecord::Migration
  def change
    create_table :employees_invoices, id: false do |t|
      t.belongs_to :employee, index: true
      t.belongs_to :invoice, index: true
    end

    create_table :invoices_work_items, id: false do |t|
      t.belongs_to :work_item, index: true
      t.belongs_to :invoice, index: true
    end
  end
end
