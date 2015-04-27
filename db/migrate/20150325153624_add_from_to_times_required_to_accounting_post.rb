class AddFromToTimesRequiredToAccountingPost < ActiveRecord::Migration
  def change
    # added column retroactively to migration '20140714093557_create_erp_tables'
    # we keep this migration for environments where the original create_erp_tables migration was already run
    unless column_exists? :accounting_posts, :from_to_times_required
      add_column :accounting_posts, :from_to_times_required, :boolean, null: false, default: false
    end
  end
end
