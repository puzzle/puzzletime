# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WorktimeController < ApplicationController
  
  # Checks if employee came from login or from direct url
  before_filter :authorize
  

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def newTime
    @worktime = Worktime.new
  end
  
  def listTime
    @user_projects = @user.projects
  end
                   
  def addTime
    if params.has_key?(:project_id)
      @project = Project.find(params[:project_id])
    else
      @absence = Absence.find(:all)
    end
  end
  
  def createTime
    start_time_hour = params[:worktime_from_start_time_hour]
    start_time_minute = params[:worktime_from_start_time_minute]
    end_time_hour = params[:worktime_to_end_time_hour]
    end_time_minute = params[:worktime_to_end_time_minute]
    params[:worktime][:employee_id] = @user.id 
    params[:worktime][:project_id] = params[:project_id]
    params[:worktime][:from_start_time] = "{#{start_time_hour}:#{start_time_minute}}"
    params[:worktime][:to_end_time] = "{#{end_time_hour}:#{end_time_minute}}"
    
    if params[:worktime][:report_type]=='start_stop_day'
      hours_start = start_time_hour.to_f + (start_time_minute.to_f/60)
      hours_end = end_time_hour.to_f + (end_time_minute.to_f/60)
      params[:worktime][:hours] = hours_end-hours_start
    end
    
    worktime = Worktime.new(params[:worktime])
    if worktime.save
        flash[:notice] = 'Item was successfully created.' 
        redirect_to :action => 'listTime'
    else
      render :action => 'newTime'
    end
  end
end
