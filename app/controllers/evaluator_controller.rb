# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class EvaluatorController < ApplicationController
  include WorktimesReport
  include WorktimesCsv

  before_action :authorize_action

  before_action :set_period

  def index
    overview
  end

  def overview
    set_navigation_levels
    @periods = init_periods
    @times = @periods.collect { |p| @evaluation.sum_times_grouped(p) }
    if @evaluation.planned_hours
      @plannings = @periods.collect { |p| @evaluation.sum_plannings_grouped(p) }
    end

    render(overview_template)
  end

  def details
    set_navigation_levels
    set_evaluation_details
    paginate_times
  end

  ########################  DETAIL ACTIONS  #########################

  def compose_report
    prepare_report_header
  end

  def report
    prepare_report_header
    conditions = params[:only_billable] ? { worktimes: { billable: true } } : {}
    render_report(@evaluation.times(@period).includes(:work_item).where(conditions))
  end

  def export_csv
    set_evaluation_details
    filename = ['puzzletime', csv_label(@evaluation.category),
                csv_label(@evaluation.division)].compact.join('-') + '.csv'
    times = @evaluation.times(@period)
    send_worktimes_csv(times, filename)
  end

  private

  def evaluation
    @evaluation ||= set_evaluation
  end

  def set_evaluation
    params[:evaluation] ||= 'userworkitems'
    set_default_evaluation
    if @user.management && @evaluation.nil?
      set_management_evaluation
    end
    if @evaluation.nil?
      @evaluation = EmployeeWorkItemsEval.new(@user.id)
      params[:evaluation] = 'userworkitems'
    end
    @evaluation
  end

  def set_default_evaluation
    @evaluation = case params[:evaluation].downcase
                  when 'managed' then ManagedOrdersEval.new(@user)
                  when 'userworkitems' then EmployeeWorkItemsEval.new(@user.id)
                  when "employeesubworkitems#{@user.id}", 'usersubworkitems' then
                    params[:evaluation] = 'usersubworkitems'
                    EmployeeSubWorkItemsEval.new(params[:category_id], @user.id)
                  when 'userabsences' then EmployeeAbsencesEval.new(@user.id)
                  when 'subworkitems' then SubWorkItemsEval.new(params[:category_id])
                  when 'workitememployees' then WorkItemEmployeesEval.new(params[:category_id])
                  end
  end

  # rubocop:disable Metrics/AbcSize
  def set_management_evaluation
    @evaluation = case params[:evaluation].downcase
                  when 'clients' then ClientsEval.new
                  when 'employees' then EmployeesEval.new(params[:department_id])
                  when 'departments' then DepartmentsEval.new
                  when 'clientworkitems' then ClientWorkItemsEval.new(params[:category_id])
                  when 'employeeworkitems' then EmployeeWorkItemsEval.new(params[:category_id])
                  when /employeesubworkitems(\d+)/ then
                    EmployeeSubWorkItemsEval.new(params[:category_id], Regexp.last_match[1])
                  when 'departmentorders' then DepartmentOrdersEval.new(params[:category_id])
                  when 'absences' then AbsencesEval.new
                  when 'employeeabsences' then EmployeeAbsencesEval.new(params[:category_id])
                  end
  end
  # rubocop:enable Metrics/AbcSize

  def overview_template
    if params[:evaluation] =~ /^userworkitems$|^employeeworkitems$/
     'overview_employee'
    elsif params[:evaluation] == 'employees'
      'employees'
    else
      'overview'
    end
  end

  def prepare_report_header
    set_evaluation_details
    @employee = Employee.find(@evaluation.employee_id) if @evaluation.employee_id
    @work_item = WorkItem.find(@evaluation.account_id)
  end

  def set_evaluation_details
    evaluation.set_division_id(params[:division_id])
    if params[:start_date].present? && params[:start_date] != '0'
      @period = Period.new(params[:start_date], params[:end_date])
    end
  end

  def set_navigation_levels
    # set session evaluation levels
    session[:evalLevels] = [] if params[:clear] || session[:evalLevels].nil?
    levels = session[:evalLevels]
    current = [params[:evaluation], @evaluation.category_id, @evaluation.title]
    levels.pop while levels.any? { |level| pop_level? level, current }
    levels.push current
  end

  def pop_level?(level, current)
    pop = level[0] == current[0]
    if level[0] =~ /(employee|user)?subworkitems(\d*)/
      pop &&= level[1] == current[1]
    end
    pop
  end

  def paginate_times
    @times = @evaluation
             .times(@period)
             .includes(:employee, :work_item)
             .page(params[:page])
    if @evaluation.absences
      @times = @times.includes(:absence)
    else
      @times = @times.includes(:invoice)
    end
    @times
  end

  def redirect_to_overview
    redirect_to action: params[:evaluation],
                category_id: params[:category_id]
  end

  def send_report_csv(csv_report)
    send_csv(csv_report.to_csv, csv_report.filename)
  end

  def csv_label(item)
    item.respond_to?(:label) ? item.label.downcase.gsub(/[^0-9a-z]/, '_') : nil
  end

  def init_periods
    if @period
      [@period]
    else
      @user.eval_periods.
        collect { |p| Period.parse(p) }.
        sort_by do |p|
          [p.nil? || p.unlimited? ? 999_999 : p.length.round(-1),
           p.try(:start_date) || Time.zone.today]
        end
    end
  end

  def authorize_action
    params[:evaluation] ||= params[:action].to_s
    evaluation
    action = params[:evaluation].gsub(/\d+$/, '').to_sym
    authorize!(action, Evaluation)
  end
end
