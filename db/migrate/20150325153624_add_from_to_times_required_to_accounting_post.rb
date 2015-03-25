class AddFromToTimesRequiredToAccountingPost < ActiveRecord::Migration
  def change
    add_column :accounting_posts, :from_to_times_required, :boolean, null: false, default: false
  end
end
