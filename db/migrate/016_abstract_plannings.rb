class AbstractPlannings < ActiveRecord::Migration
  
  def self.up
      add_column :plannings, :is_abstract, :boolean
      add_column :plannings, :abstract_amount, :decimal
      execute "UPDATE plannings SET is_abstract = false;"
      execute "UPDATE plannings SET abstract_amount = 0;"
  end

  def self.down
      remove_column :plannings, :is_abstract
      remove_column :plannings, :abstract_amount
  end
  
end