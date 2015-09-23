# == Schema Information
#
# Table name: employments
#
#  id          :integer          not null, primary key
#  employee_id :integer
#  percent     :decimal(5, 2)    not null
#  start_date  :date             not null
#  end_date    :date
#

Fabricator(:employment) do
  percent    { 80 }
  start_date { 1.year.ago }
end
