class ReallyChangeOfferedRateToDecimal < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up   { change_column :accounting_posts, :offered_rate, :decimal, precision: 12, scale: 2 }
      dir.down { change_column :accounting_posts, :offered_rate, :float }
    end
  end
end
