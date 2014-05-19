# encoding: utf-8

class AttendanceEval < Evaluation

  include Conditioner

  DETAIL_COLUMNS   = [:work_date, :hours, :times]

  def initialize(employee_id)
    super(Employee.find(employee_id))
  end

  def for?(user)
    category == user
  end

  def division_label
    'Anwesenheitszeiten'
  end

  def worktime_name
    Attendancetime.label
  end

  # Sums all worktimes for a given period.
  # If a division is passed or set previously, their sum will be returned.
  # Otherwise the sum of all worktimes in the main category is returned.
  def sum_times(period, div = nil, options = {})
    category.sum_attendance period, options
  end

  # Sums all worktimes for the category in a given period.
  def sum_total_times(period = nil, options = {})
    sum_times period, nil, options
  end

  # Counts the number of Worktime entries in the current Evaluation for a given period.
  def count_times(period = nil, options = {})
    options = add_conditions options, period
    category.attendancetimes.count('*', options).to_i
  end

  # Returns a list of all Worktime entries for this Evaluation in the given period
  # of time.
  def times(period, options = {})
    options = add_conditions options, period
    options[:order] ||= 'work_date ASC, from_start_time'
    category.attendancetimes.where(options[:conditions]).
                             includes(options[:include]).
                             reorder(options[:order])
  end

  # Do nothing, attendance has no divisions
  def set_division_id(division_id = nil)
  end

  def edit_link?(user)
    for? user
  end

  def split_link?(user)
    for? user
  end

  def employee_id
    category.id
  end

  private

  def add_conditions(options = {}, period = nil)
    if period
      options = clone_options options
      append_conditions(options[:conditions], ['work_date BETWEEN ? AND ?', period.startDate, period.endDate])
    end
    options
  end

end
