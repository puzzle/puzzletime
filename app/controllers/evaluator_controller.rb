# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class EvaluatorController < ApplicationController
  include WorktimesReport
  include WorktimesCsv

  before_action :authorize_action

  before_action :set_period

  helper_method :search_conditions, :evaluation_type

  def index
    overview
  end

  def overview
    set_navigation_levels
    @periods = init_periods
    @times = @periods.collect { |p| @evaluation.sum_times_grouped(p) }
    @plannings = @periods.collect { |p| @evaluation.sum_plannings_grouped(p) } if @evaluation.planned_hours
    @order = @evaluation.category.is_a?(WorkItem).presence && @evaluation.category.order

    render(overview_template)
  end

  def details
    @absence = Absence.find_by(id: params[:absence_id]) if params[:absence_id]
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
    prepare_worktimes(@evaluation.times(@period).includes(:work_item).where(conditions))
    pdf_generator = Order::Services::TimeRapportPdfGenerator.new(@order, @worktimes, @tickets, @ticket_view, @employees, @employee, @work_items, @period, params)

    send_data pdf_generator.generate_pdf.render,
              filename: 'report.pdf',
              type: 'application/pdf',
              disposition: 'inline'
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
    set_default_params

    set_default_evaluation
    set_management_evaluation if @user.management && @evaluation.nil?

    if @evaluation.nil?
      @evaluation = Evaluations::EmployeeWorkItemsEval.new(@user.id)
      params[:evaluation] = 'userworkitems'
    end
    @evaluation
  end

  def evaluation_type
    params[:evaluation]
  end

  def set_default_evaluation
    @evaluation =
      case params[:evaluation].downcase
      when 'managed'                                             then Evaluations::ManagedOrdersEval.new(@user)
      when 'userworkitems'                                       then Evaluations::EmployeeWorkItemsEval.new(@user.id)
      when "employeesubworkitems#{@user.id}", 'usersubworkitems'
        params[:evaluation] = 'usersubworkitems'
        Evaluations::EmployeeSubWorkItemsEval.new(params[:category_id], @user.id)
      when 'userabsences' then Evaluations::EmployeeAbsencesEval.new(
        @user.id, **search_conditions
      )
      when 'subworkitems'                                        then Evaluations::SubWorkItemsEval.new(params[:category_id])
      when 'workitememployees'                                   then Evaluations::WorkItemEmployeesEval.new(params[:category_id])
      end
  end

  def set_default_params
    params[:evaluation] ||= 'userworkitems'

    case params[:evaluation].downcase
    when 'employees'
      params[:department_id] = current_user.department_id unless params.key?(:department_id)
    end
  end

  def set_management_evaluation
    @evaluation =
      case params[:evaluation].downcase
      when 'clients'                   then Evaluations::ClientsEval.new
      when 'employees'                 then Evaluations::EmployeesEval.new(params[:department_id])
      when 'departments'               then Evaluations::DepartmentsEval.new
      when 'clientworkitems'           then Evaluations::ClientWorkItemsEval.new(params[:category_id])
      when 'employeeworkitems'         then Evaluations::EmployeeWorkItemsEval.new(params[:category_id])
      when /employeesubworkitems(\d+)/ then Evaluations::EmployeeSubWorkItemsEval.new(
        params[:category_id], Regexp.last_match[1]
      )
      when 'departmentorders'          then Evaluations::DepartmentOrdersEval.new(params[:category_id])
      when 'absences'                  then Evaluations::AbsencesEval.new(**search_conditions)
      when 'employeeabsences'          then Evaluations::EmployeeAbsencesEval.new(
        params[:category_id], **search_conditions
      )
      end
  end

  def overview_template
    if /^userworkitems$|^employeeworkitems$/.match?(params[:evaluation])
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
    @work_items = [WorkItem.find(@evaluation.account_id)]
  end

  def set_evaluation_details
    evaluation.set_division_id(params[:division_id])
    return unless params[:start_date].present? && params[:start_date] != '0'

    @period = Period.new(params[:start_date], params[:end_date])
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
    pop &&= level[1] == current[1] if /(employee|user)?subworkitems(\d*)/.match?(level[0])
    pop
  end

  def paginate_times
    @times = @evaluation
             .times(@period)
             .includes(:employee, :work_item)
             .page(params[:page])
    @times = if @evaluation.absences
               @times.includes(:absence)
             else
               @times.includes(:invoice)
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
      @user.eval_periods
           .collect { |p| Period.parse(p) }
           .sort_by do |p|
        [p.nil? || p.unlimited? ? 999_999 : p.length.round(-1),
         p.try(:start_date) || Time.zone.today]
      end
    end
  end

  def search_conditions
    return {} if params[:absence_id].blank?

    { absence_id: params[:absence_id] }
  end

  def authorize_action
    params[:evaluation] ||= params[:action].to_s
    evaluation
    action = params[:evaluation].gsub(/\d+$/, '').to_sym
    authorize!(action, Evaluations::Evaluation)
  end
end
