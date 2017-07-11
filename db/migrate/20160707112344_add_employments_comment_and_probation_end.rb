class AddEmploymentsCommentAndProbationEnd < ActiveRecord::Migration[5.1]
  def change
    add_column :employments, :comment, :string
    add_column :employments, :probation_period_end_date, :date
  end
end
