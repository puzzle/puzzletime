class AddEmploymentsCommentAndProbationEnd < ActiveRecord::Migration
  def change
    add_column :employments, :comment, :string
    add_column :employments, :probation_period_end_date, :date
  end
end
