# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimesController < ApplicationController

  # TODO remove
  include ApplicationHelper

  helper_method :record_other?
  hide_action :detail_action


  FINISH = 'Abschliessen'


  def index
    redirect_to controller: 'evaluator', action: user_evaluation, clear: 1
  end

  # Shows the add time page.
  def new
    create_default_worktime
    set_worktime_defaults
    set_accounts
    set_existing
    render action: 'new'
  end

  # Stores the new time the data on DB.
  def create
    set_new_worktime
    set_worktime_params
    params[:other] = 1 if params[:worktime][:employee_id] && @user.management
    @worktime.employee = @user unless record_other?
    if @worktime.save
      flash[:notice] = "Die #{@worktime.class.label} wurde erfasst."
      check_overlapping
      return list_detail_time if params[:commit] == FINISH
      @worktime = @worktime.template
    end
    set_accounts
    set_existing
    render action: 'new'
  end

  # Shows the edit page for the selected time.
  def edit
    set_worktime
    set_worktime_defaults
    set_accounts true
    set_existing
    render action: 'edit'
  end

  # Update the selected worktime on DB.
  def update
    set_worktime
    if @worktime.employee_id != @user.id
      return list_detail_time if @worktime.absence?
      session[:split] = WorktimeEdit.new(@worktime.clone)
      create_part
    else
      set_worktime_params
      if @worktime.save
        flash[:notice] = "Die #{@worktime.class.label} wurde aktualisiert."
        check_overlapping
        list_detail_time
      else
        set_accounts true
        set_existing
        render action: 'edit'
      end
    end
  end

  def confirm_delete
    set_worktime
    render action: 'confirm_delete'
  end

  def destroy
    set_worktime
    if @worktime.employee == @user
      if @worktime.destroy
        flash[:notice] = "Die #{@worktime.class.label} wurde entfernt"
      else
        # errors enumerator yields attr and message (=second item)
        flash[:notice] = @worktime.errors.messages.collect(&:second).flatten.join(', ')
      end
    end
    referer = request.headers['Referer']
    if params[:back] && referer && !(referer =~ /time\/edit\/#{@worktime.id}$/)
      referer.gsub!(/time\/create[^A-Z]?/, 'time/new')
      referer.gsub!(/time\/update[^A-Z]?/, 'time/edit')
      if referer.include?('work_date')
        referer.gsub!(/work_date=[0-9]{4}\-[0-9]{2}\-[0-9]{2}/, "work_date=#{@worktime.work_date}")
      else
        referer += (referer.include?('?') ? '&' : '?') + "work_date=#{@worktime.work_date}"
      end
      redirect_to(referer)
    else
      list_detail_time
    end
  end

  def view
    set_worktime
    render action: 'view'
  end

  def split
    @split = session[:split]
    if @split.nil?
      redirect_to controller: 'projecttimes', action: 'new'
      return
    end
    @worktime = @split.worktime_template
    set_project_accounts
    render action: 'split'
  end

  def create_part
    @split = session[:split]
    return create if @split.nil?
    params[:id] ? set_worktime : set_new_worktime
    @worktime.employee ||= @split.original.employee
    set_worktime_params
    if @worktime.valid? && @split.add_worktime(@worktime)
      if @split.complete? || (params[:commit] == FINISH && @split.class::INCOMPLETE_FINISH)
        @split.save
        session[:split] = nil
        flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
        if @worktime.employee != @user
          params[:other] = 1
          params[:evaluation] = nil
        end
        list_detail_time
      else
        session[:split] = @split
        redirect_to evaluation_detail_params.merge!(action: 'split')
      end
    else
      set_project_accounts
      render action: 'split'
    end
  end

  def delete_part
    session[:split].remove_worktime(params[:part_id].to_i)
    redirect_to evaluation_detail_params.merge!(action: 'split')
  end

  def running
    if request.env['HTTP_USER_AGENT'] =~ /.*iPhone.*/
      render action: 'running', layout: 'phone'
    else
      render action: 'running'
    end
  end

  # ajax action
  def existing
    @worktime = Worktime.new
    begin
      @worktime.work_date = Date.strptime(params[:worktime][:work_date].to_s, DATE_FORMAT)
   rescue ArgumentError
      # invalid string, date will remain unaffected, i.e., nil
    end
    @worktime.employee_id = @user.management ? params[:worktime][:employee_id] : @user.id
    set_existing
    render action: 'existing'
  end

  # no action, may overwrite in subclass
  def detail_action
    'details'
  end

  protected

  def create_default_worktime
    set_period
    set_new_worktime
    @worktime.from_start_time = Time.zone.now.change(hour: DEFAULT_START_HOUR)
    @worktime.report_type = @user.report_type || DEFAULT_REPORT_TYPE
    if params[:work_date]
      @worktime.work_date = params[:work_date]
    elsif @period && @period.length == 1
      @worktime.work_date = @period.startDate
    else
      @worktime.work_date = Date.today
    end
    @worktime.employee_id = record_other? ? params[:employee_id] : @user.id
  end

  def set_worktime_params
    @worktime.attributes = model_params
  end

  def list_detail_time
    options = evaluation_detail_params
    options[:controller] = 'evaluator'
    options[:action] = detail_action
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
    redirect_to options
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

  def set_worktime
    @worktime = find_worktime
  end

  def set_existing
    @work_date = @worktime.work_date
    @existing = Worktime.where('employee_id = ? AND work_date = ?', @worktime.employee_id, @work_date).
                         order('type DESC, from_start_time, project_id')
  end

  def find_worktime
    Worktime.find(params[:id])
  end

  # overwrite in subclass
  def set_new_worktime
    @worktime = nil
  end

  # overwrite in subclass
  def set_worktime_defaults
  end

  # overwrite in subclass
  def set_accounts(all = false)
    @accounts = nil
  end

  def set_project_accounts
    @accounts = (@worktime.employee || @user).leaf_projects
  end

  # may overwrite in subclass
  def user_evaluation
    record_other? ? 'employeeprojects' : 'userProjects'
  end

  def record_other?
    @user.management && params[:other]
  end

  ################   RUNNING TIME FUNCTIONS    ##################

  def start_running(time, start = Time.zone.now)
    time.employee = @user
    time.report_type = AutoStartType::INSTANCE
    time.work_date = start.to_date
    time.from_start_time = start
    time.billable = time.project.billable if time.project
    save_running time, "Die #{time.account ? 'Projektzeit ' + time.account.label_verbose : 'Anwesenheit'} mit #time_string wurde erfasst.\n"
  end

  def stop_running(time = running_time, stop = Time.zone.now)
    time.to_end_time = time.work_date == Date.today ? stop : '23:59'
    time.report_type = StartStopType::INSTANCE
    time.store_hours
    if time.hours < 0.0166
      append_flash "#{time.class.label} unter einer Minute wird nicht erfasst.\n"
      time.destroy
      running_time(true)
    else
      save_running time, "Die #{time.account ? 'Projektzeit ' + time.account.label_verbose : 'Anwesenheit'} von #time_string wurde gespeichert.\n"
    end
  end

  def save_running(time, message)
    if time.save
      append_flash message.sub('#time_string', time.time_string)
    else
      append_flash "Die #{time.class.label} konnte nicht gespeichert werden:\n"
      time.errors.each { |attr, msg| flash[:notice] += '<br/> - ' + msg + "\n" }
    end
    running_time(true)
    time
  end

  def running_time(reload = false)
    # implement in subclass
  end

  def redirect_to_running
    redirect_to controller: 'worktimes', action: 'running'
  end

  def append_flash(msg)
    flash[:notice] = flash[:notice] ? flash[:notice] + '<br/>' + msg : msg
  end
end
