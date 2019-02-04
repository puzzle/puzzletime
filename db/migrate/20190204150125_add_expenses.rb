class AddExpenses < ActiveRecord::Migration[5.2]
  def change
    create_table :expenses do |t|
      t.belongs_to :employee, null: false
      t.integer    :kind,   null: false
      t.integer    :status, null: false, default: 0, index: true
      t.decimal    :amount, precision: 12, scale: 2, null: false
      t.date       :payment_date, null: false

      t.text       :description
      t.text       :rejection

      t.belongs_to :reviewer, index: true
      t.datetime   :reviewed_at

      t.belongs_to :order, index: true

      t.date       :reimbursement_date
    end
  end
end
