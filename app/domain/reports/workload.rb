# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class Reports::Workload
  include Filterable

  attr_reader :period, :params, :department

  WORKTIME_FIELDS = [
    :type,
    :employee_id,
    :department_id,
    :hours,
    :work_item_id,
    :path_ids,
    :billable,
    :absence_id,
    :payed
  ].freeze


  def initialize(period, department, params = {})
    @period = period
    @department = department
    @params = params
  end

  def filters_defined?
    period.limited? && department.present?
  end

  def present?
    department_worktimes.present?
  end

  def all_employees
    @all_employees ||= Employee.all.to_a
  end

  def department_period_employments
    @department_period_employments ||= begin
      department_employee_ids = all_employees.select { |e| e.department_id == department.id }.map(&:id)
      period_employments.select { |e| department_employee_ids.include?(e.employee_id) }
    end
  end

  def department_period_employees_with_employment_or_worktime
    employee_ids = (department_period_employments + department_worktimes).map(&:employee_id).uniq
    all_employees.select { |employee| employee_ids.include?(employee.id) }
  end

  def summary
    [
      Reports::Workload::SummaryEntry.new(Company.name, period, period_employments, worktimes),
      Reports::Workload::SummaryEntry.new(department, period, department_period_employments, department_worktimes)
    ]
  end

  def entries
    @entries ||= sort_entries(build_entries)
  end

  def department_worktimes
    @department_worktimes ||= worktimes.select do |worktime_entry|
      worktime_entry.department_id == department.id
    end
  end

  private

  def worktimes
    @worktimes ||= build_worktimes
  end

  def build_worktimes
    order_work_item_ids = Order.all.pluck(:work_item_id)
    order_work_items = WorkItem.where(id: order_work_item_ids).to_a
    worktimes_query.pluck(*WORKTIME_FIELDS).map do |row|
      WorktimeEntry.new(*row).tap do |worktime_entry|
        if worktime_entry.ordertime?
          worktime_entry.order_work_item = order_work_items.detect do |work_item|
            worktime_entry.path_ids.include?(work_item.id)
          end
        end
      end
    end
  end

  def worktimes_query
    Worktime.
      in_period(period).
      joins('LEFT OUTER JOIN work_items ON work_items.id = worktimes.work_item_id').
      joins('LEFT OUTER JOIN absences ON absences.id = worktimes.absence_id').
      joins(:employee)
  end

  def build_entries
    employee_employments_map = period_employments.group_by(&:employee_id)
    employee_department_worktimes_map = department_worktimes.group_by(&:employee_id)
    department_period_employees_with_employment_or_worktime.map do |employee|
      employments = employee_employments_map[employee.id] || []
      worktimes = employee_department_worktimes_map[employee.id] || []
      Reports::Workload::EmployeeEntry.new(employee, period, employments, worktimes)
    end
  end

  def period_employments
    @period_employments ||= load_employments
  end

  def load_employments
    Employment.
      where('(end_date IS NULL OR end_date >= ?) AND start_date <= ?',
            period.start_date, period.end_date).
      reorder('start_date').to_a
  end

  def sort_entries(entries)
    dir = params[:sort_dir].to_s.casecmp('desc').zero? ? 1 : -1
    if sort_by_employee?
      sort_by_employee(entries, dir)
    elsif sort_by_number?
      sort_by_number(entries, dir)
    else
      entries
    end
  end

  def sort_by_employee?
    params[:sort] == 'employee' || params[:sort].blank?
  end

  def sort_by_number?
    %w(must_hours worktime_balance ordertime_hours absencetime_hours workload billability).include?(params[:sort])
  end

  def sort_by_employee(entries, dir)
    entries.sort_by(&:to_s).tap do |sorted_entries|
      sorted_entries.reverse! if dir > 0
    end
  end

  def sort_by_number(entries, dir)
    entries.sort_by do |e|
      e.send(params[:sort]).to_f * dir
    end
  end

end
