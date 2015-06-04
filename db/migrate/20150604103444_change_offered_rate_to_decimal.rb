class ChangeOfferedRateToDecimal < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up   { change_column :accounting_posts, :offered_rate, :float }
      dir.down { change_column :accounting_posts, :offered_rate, :integer }
    end
  end
end
