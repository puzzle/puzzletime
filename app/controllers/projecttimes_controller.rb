# encoding: utf-8

class ProjecttimesController < WorktimesController

  self.permitted_attrs = [:account_id, :report_type, :work_date, :hours,
                          :from_start_time, :to_end_time, :description, :billable, :booked, :ticket]

  def update
    if entry.employee_id != @user.id
      session[:split] = WorktimeEdit.new(entry.clone)
      create_part
    else
      super
    end
  end

  def split
    @split = session[:split]
    if @split.nil?
      redirect_to controller: 'projecttimes', action: 'new'
      return
    end
    @worktime = @split.worktime_template
    render action: 'split'
  end

  def create_part
    @split = session[:split]
    return create if @split.nil?
    entry
    @worktime.employee ||= @split.original.employee
    assign_attributes
    if @worktime.valid? && @split.add_worktime(@worktime)
      if @split.complete? || (params[:commit] == FINISH && @split.class::INCOMPLETE_FINISH)
        @split.save
        session[:split] = nil
        flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
        if @worktime.employee != @user
          params[:other] = 1
          params[:evaluation] = nil
        end
        redirect_to detail_times_path
      else
        session[:split] = @split
        redirect_to respond_to do |wants|
          wants.html do
            evaluation_detail_params
          end
          wants.js {  }
        end.merge!(action: 'split')
      end
    else
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

  def start
    running = running_time
    now = Time.zone.now
    if running
      running.description = params[:description]
      running.ticket = params[:ticket]
      stop_running running, now
    end
    time = Projecttime.new
    time.project = Project.find(params[:id])
    start_running time, now
    redirect_to_running
  end

  def stop
    running = running_time
    if running
      running.description = params[:description]
      running.ticket = params[:ticket]
      stop_running running
    else
      flash[:notice] = 'Zur Zeit läuft kein Projekt'
    end
    redirect_to_running
  end

  protected

  def set_worktime_defaults
    @worktime.set_project_defaults(params[:account_id]) unless @worktime.project_id
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

  def redirect_to_running
    redirect_to action: 'running'
  end

  def running_time(reload = false)
    @user.running_project(reload)
  end

end
