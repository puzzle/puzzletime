# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class WorktimesController < CrudController
  authorize_resource :worktime, except: :index, parent: false

  helper_method :record_other?

  before_save :check_has_accounting_post, :check_worktimes_committed
  after_save :check_overlapping, :check_employment

  before_render_index :set_statistics
  before_render_new :create_default_worktime
  before_render_form :set_existing
  before_render_form :set_employees

  FINISH = 'Abschliessen'

  def index
    set_week_days
    @notifications = UserNotification.list_during(@period, current_user)
    super
  end

  def show
    redirect_to index_path
  end

  def new
    super
    return unless params[:template]

    template = Worktime.find_by(id: params[:template])
    return unless template

    @worktime.account_id = template.account_id
    @worktime.ticket = template.ticket
    @worktime.description = template.description
    @worktime.internal_description = template.internal_description
    @worktime.billable = template.billable
    @worktime.meal_compensation = template.meal_compensation
  end

  def create(options = {})
    if params[:redirect_to_self]
      work_date = params[:ordertime][:work_date]
      options[:location] = new_ordertime_path(work_date:)
    end

    super
  end

  # ajax action
  def existing
    @worktime = Worktime.new
    @worktime.work_date = model_params[:work_date]
    @worktime.employee_id = @user.management ? model_params[:employee_id].presence || @user.id : @user.id
    set_existing
    render 'existing'
  end

  private

  def create_default_worktime
    set_period
    entry
    set_work_date
    @worktime.employee_id = employee_id
    set_worktime_defaults
    true
  end

  def set_work_date
    return if @worktime.work_date

    @worktime.work_date = if params[:work_date]
                            params[:work_date]
                          elsif @period && @period.length == 1
                            @period.start_date
                          else
                            Time.zone.today
                          end
  end

  def check_overlapping
    return unless @worktime.report_type.is_a? ReportType::StartStopType

    conditions = ['NOT (work_item_id IS NULL AND absence_id IS NULL) AND ' \
                  'employee_id = :employee_id AND work_date = :work_date AND id <> :id AND (' \
                  '(from_start_time <= :start_time AND to_end_time >= :end_time) OR ' \
                  '(from_start_time >= :start_time AND from_start_time < :end_time) OR ' \
                  '(to_end_time > :start_time AND to_end_time <= :end_time))',
                  { employee_id: @worktime.employee_id,
                    work_date: @worktime.work_date,
                    id: @worktime.id,
                    start_time: @worktime.from_start_time,
                    end_time: @worktime.to_end_time }]
    overlaps = Worktime.where(conditions).includes(:work_item).to_a
    return if overlaps.blank?

    flash[:warning] = "#{@worktime}: Es besteht eine Überlappung mit mindestens einem anderen Eintrag:\n".html_safe
    flash[:warning] += overlaps.collect { |o| ERB::Util.h(o) }.join("\n").html_safe
  end

  def check_employment
    employment = @worktime.employee.employment_at(@worktime.work_date)

    unless employment
      flash[:warning] = "Es besteht keine Anstellung am #{l(@worktime.work_date)}".html_safe
      return
    end

    return unless employment.percent.zero?

    flash[:warning] = "Vorsicht, am #{l(@worktime.work_date)} wurde bereits unbezahlter Urlaub eingetragen".html_safe
    nil
  end

  def set_existing
    @work_date = @worktime.work_date
    @existing = Worktime.where('employee_id = ? AND work_date = ?', @worktime.employee_id, @work_date)
                        .order('type DESC, from_start_time, work_item_id')
                        .includes(:work_item, :absence)
  end

  def set_week_days
    set_selected_date
    @week_days = (@selected_date.at_beginning_of_week..@selected_date.at_end_of_week).to_a
    @next_week_date = @week_days.last + 1.day
    @previous_week_date = @week_days.first - 7.days

    @today_week_date = Time.zone.today.at_beginning_of_week
  end

  def set_selected_date
    @selected_date = params[:week_date].present? ? Date.parse(params[:week_date]) : Time.zone.today
  rescue ArgumentError
    @selected_date = Time.zone.today
  end

  def set_employees
    @employees = Employee.list if record_other?
  end

  def list_entries
    @worktimes = Worktime.where('employee_id = ? AND work_date >= ? AND work_date <= ?',
                                @user.id, @week_days.first, @week_days.last)
                         .includes(:work_item, :absence, :employee, :invoice)
                         .order('work_date, from_start_time, work_item_id')
    @daily_worktimes = @worktimes.group_by(&:work_date)
    @worktimes
  end

  def index_path
    if params[:back_url].present?
      sanitized_back_url
    elsif record_other?
      week = Period.week_for(entry.work_date)
      { controller: 'evaluator',
        action: 'details',
        evaluation: generic_evaluation,
        division_id: employee_id,
        start_date: week.start_date,
        end_date: week.end_date,
        clear: 1 }
    else
      { action: 'index', week_date: entry.work_date }
    end
  end

  def set_statistics
    @current_overtime = @user.statistics.current_overtime
    @monthly_worktime = @user.statistics.musttime(Period.current_month)
    @pending_worktime = @user.statistics.pending_worktime(Period.current_month).to_f
    @remaining_vacations = @user.statistics.current_remaining_vacations
  end

  # returns the employee's id from the params or the logged in user
  def employee_id
    if record_other?
      params.key?(model_identifier) ? model_params[:employee_id] : params[:employee_id]
    else
      @user.id
    end
  end

  # overwrite in subclass
  def set_worktime_defaults; end

  def record_other?
    @user.management && (%w[1 true].include?(params[:other]) || other_employee_param?)
  end

  def other_employee_param?
    params.key?(model_identifier) &&
      model_params[:employee_id] &&
      model_params[:employee_id] != @user.id
  end

  def append_flash(msg)
    flash[:notice] = flash[:notice] ? flash[:notice] + '<br/>'.html_safe + msg : msg
  end

  def permitted_attrs
    attrs = self.class.permitted_attrs.clone
    attrs << :employee_id if @user.management
    attrs
  end

  def build_entry
    super.tap do |worktime|
      worktime.employee ||= @user
    end
  end

  def assign_attributes
    return unless params.key?(model_identifier)

    # Set start/end time to nil, this way we correctly unset
    # the time on "hours" change with entry.attributes = model_params
    # Otherwise the start/end time recalculate the hours property.
    params[model_identifier][:from_start_time] ||= nil
    params[model_identifier][:to_end_time] ||= nil

    params[:other] = '1' if model_params[:employee_id] && @user.management
    super
    entry.employee = @user unless record_other?
  end

  def generic_evaluation
    'employees'
  end

  def ivar_name(klass)
    klass < Worktime ? Worktime.model_name.param_key : super
  end

  def check_has_accounting_post
    return if entry.work_item.respond_to?(:accounting_post)

    entry.errors.add(:work_item, 'Bitte wähle eine Buchungsposition aus')
    throw :abort
  end

  def check_worktimes_committed
    if entry.try(:order).try(:responsible_id) != @user.id &&
       entry.employee_id == @user.id && entry.worktimes_committed?
      date = I18n.l(@user.committed_worktimes_at, format: :month)
      entry.errors.add(:work_date, "Die Zeiten bis und mit #{date} wurden freigegeben " \
                                   'und können nicht mehr bearbeitet werden.')
      throw :abort
    end
  end
end
