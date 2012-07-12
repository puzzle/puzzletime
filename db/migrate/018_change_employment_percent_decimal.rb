class ChangeEmploymentPercentDecimal < ActiveRecord::Migration
  def self.up
    change_column :employments, :percent, :decimal, :precision => 5, :scale => 2
  end

  def self.down
    change_column :employments, :percent, :integer
  end
end
