# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  absence_id      :integer
#  employee_id     :integer
#  report_type     :string(255)      not null
#  work_date       :date             not null
#  hours           :float
#  from_start_time :time
#  to_end_time     :time
#  description     :text
#  billable        :boolean          default(TRUE)
#  booked          :boolean          default(FALSE)
#  type            :string(255)
#  ticket          :string(255)
#  work_item_id    :integer
#  invoice_id      :integer
#

Fabricator(:ordertime) do
  work_date { Date.today }
  hours 2
  report_type 'absolute_day'
end

Fabricator(:absencetime) do
  work_date { Date.today }
  hours 2
  report_type 'absolute_day'
end
