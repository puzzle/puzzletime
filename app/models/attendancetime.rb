# encoding: utf-8
# == Schema Information
#
# Table name: worktimes
#
#  id              :integer          not null, primary key
#  project_id      :integer
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
#


class Attendancetime < Worktime

  attr_reader :projecttime

  def self.label
    'Anwesenheitszeit'
  end

  def self.account_label
    'Anwesenheit'
  end

  def projecttime=(value)
    @projecttime = value.kind_of?(String) ? value.to_i != 0 : value
  end

  def corresponding_type
    Projecttime
  end

end
