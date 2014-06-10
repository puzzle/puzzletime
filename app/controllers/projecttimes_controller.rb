# encoding: utf-8

class ProjecttimesController < WorktimesController

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

  def set_new_worktime
    @worktime = Projecttime.new
  end

  def set_worktime_defaults
    @worktime.set_project_defaults(params[:account_id] || @user.default_project_id) unless @worktime.project_id
  end

  def set_accounts(all = false)
    if params[:other]
      @accounts = Project.leaves
    elsif all
      set_alltime_accounts
    else
      set_project_accounts
      set_alltime_accounts unless @accounts.include? @worktime.project
    end
  end

  def running_time(reload = false)
    @user.running_project(reload)
  end

  private

  def model_params
    attrs = [:account_id, :report_type, :work_date, :hours,
             :from_start_time, :to_end_time, :description, :billable, :booked, :ticket]
    attrs << :employee_id if @user.management
    params.require(:worktime).permit(attrs)
  end

  def set_alltime_accounts
    e = @worktime.employee
    @accounts = e ? e.alltime_leaf_projects : Project.leaves
  end

end
