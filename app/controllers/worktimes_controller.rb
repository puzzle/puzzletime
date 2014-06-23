# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimesController < CrudController

  helper_method :record_other?

  before_action :authorize_destroy, only: :destroy

  after_save :check_overlapping

  before_render_index :set_statistics
  before_render_new :create_default_worktime
  before_render_form :set_existing

  FINISH = 'Abschliessen'

  def index
    set_week_days
    super
  end

  def new
    super do |format|
      if params[:template]
        template = Worktime.find(params[:template])
        @worktime.account_id = template.account_id
        @worktime.ticket = template.ticket
        @worktime.description = template.description
      end
    end
  end


  def create
    super do |format|
      format.html do
        if @worktime.errors.blank?
          if params[:commit] == FINISH
            redirect_to index_url
          else
            @worktime = @worktime.template
            render 'new'
          end
        else
          render 'new'
        end
      end
    end
  end

  def destroy
    super(location: destroy_referer)
  end

  # ajax action
  def existing
    @worktime = Worktime.new
    @worktime.work_date = params[:worktime][:work_date]
    @worktime.employee_id = @user.management ? params[:worktime][:employee_id].presence || @user.id : @user.id
    set_existing
    render 'existing'
  end

  def self.model_identifier
    :worktime
  end

  protected

  def create_default_worktime
    set_period
    entry
    @worktime.from_start_time = Time.zone.now.change(hour: Settings.defaults.start_hour)
    @worktime.report_type = @user.report_type || Settings.defaults.report_type
    if params[:work_date]
      @worktime.work_date = params[:work_date]
    elsif @period && @period.length == 1
      @worktime.work_date = @period.startDate
    else
      @worktime.work_date = Date.today
    end
    @worktime.employee_id = record_other? ? params[:employee_id] : @user.id
    set_worktime_defaults
    true
  end

  def authorize_destroy
    unless entry.employee == @user
      flash[:notice] = 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
      redirect_to root_path
    end
  end

  def destroy_referer
    referer = request.env['HTTP_REFERER']
    if params[:back] && referer && !(referer =~ /time\/edit\/#{@worktime.id}$/)
      referer.gsub!(/time\/create[^A-Z]?/, 'time/new')
      referer.gsub!(/time\/update[^A-Z]?/, 'time/edit')
      if referer.include?('work_date')
        referer.gsub!(/work_date=[0-9]{4}\-[0-9]{2}\-[0-9]{2}/, "work_date=#{@worktime.work_date}")
      else
        referer += (referer.include?('?') ? '&' : '?') + "work_date=#{@worktime.work_date}"
      end
      referer
    else
      detail_times_path
    end
  end

  def detail_times_path
    options = evaluation_detail_params
    options[:controller] = 'evaluator'
    options[:action] = 'details'
    if params[:evaluation].nil?
      options[:evaluation] = user_evaluation
      options[:category_id] = @worktime.employee_id
      options[:division_id] = nil
      options[:clear] = 1
      set_period
      if @period.nil? || ! @period.include?(@worktime.work_date)
        period = Period.week_for(@worktime.work_date)
        options[:start_date] = period.startDate
        options[:end_date] = period.endDate
      end
    end
    options
  end

  def check_overlapping
    if @worktime.report_type.is_a? StartStopType
      conditions = ['NOT (project_id IS NULL AND absence_id IS NULL) AND ' \
                    'employee_id = :employee_id AND work_date = :work_date AND id <> :id AND (' +
                    '(from_start_time <= :start_time AND to_end_time >= :end_time) OR ' +
                    '(from_start_time >= :start_time AND from_start_time < :end_time) OR ' +
                    '(to_end_time > :start_time AND to_end_time <= :end_time))',
                    { employee_id: @worktime.employee_id,
                      work_date: @worktime.work_date,
                      id: @worktime.id,
                      start_time: @worktime.from_start_time,
                      end_time: @worktime.to_end_time }]
      overlaps = Worktime.where(conditions).to_a
      flash[:notice] += " Es besteht eine Überlappung mit mindestens einem anderen Eintrag: <br/>\n" unless overlaps.empty?
      flash[:notice] += overlaps.join("<br/>\n") unless overlaps.empty?
    end
  end

  def set_existing
    @work_date = @worktime.work_date
    @existing = Worktime.where('employee_id = ? AND work_date = ?', @worktime.employee_id, @work_date).
                         order('type DESC, from_start_time, project_id').
                         includes(:project)
  end

  def set_week_days
    if params[:week_date].present?
      week_date = Date.parse(params[:week_date])
    else
      week_date = Date.today
    end
    @week_days = (week_date.at_beginning_of_week..week_date.at_end_of_week).to_a
    @next_week_date = @week_days.last + 1.day
    @previous_week_date = @week_days.first - 7.day
  end

  def list_entries
    Worktime.where('employee_id = ? AND work_date >= ? AND work_date <= ?', @user.id, @week_days.first, @week_days.last)
            .includes(:project, :absence)
            .order('work_date, type DESC, from_start_time, project_id')
  end

  def set_statistics
    @current_overtime = @user.statistics.current_overtime
    @monthly_worktime = @user.statistics.musttime(Period.current_month)
    @pending_worktime = 0 - @user.statistics.overtime(Period.current_month).to_f
  end

  # overwrite in subclass
  def set_worktime_defaults
  end

  # may overwrite in subclass
  def user_evaluation
    record_other? ? 'employeeprojects' : 'userProjects'
  end

  def record_other?
    @user.management && params[:other]
  end

  def append_flash(msg)
    flash[:notice] = flash[:notice] ? flash[:notice] + '<br/>'.html_safe + msg : msg
  end

  def permitted_attrs
    attrs = self.class.permitted_attrs.clone
    attrs << :employee_id if @user.management
    attrs
  end

  def assign_attributes
    params[:other] = 1 if params[:worktime][:employee_id] && @user.management
    super
    entry.employee = @user unless record_other?
  end

  def ivar_name(klass)
    klass < Worktime ? Worktime.model_name.param_key : super(klass)
  end

  def evaluation_detail_params
    params.slice(:evaluation, :category_id, :division_id, :start_date, :end_date, :page)
  end
end
