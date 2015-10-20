class RemoveDiscountReferenceFromAccountingPost < ActiveRecord::Migration
  def change
    change_table :accounting_posts do |t|
      t.remove :discount_fixed
      t.remove :discount_percent
      t.remove :reference
    end
  end
end
