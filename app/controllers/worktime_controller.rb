class WorktimeController < ApplicationController
  
  before_filter :authorize
  
  def list
    @employee = session[:user]
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


  def addtime
    @project = Project.find(params[:project_id])
    @employee = Employee.find(@user.id)
  end

  def new
    @worktime = Worktime.new
  end
  
  def hide_stuff
    while true
      case params[:report_type]
        when 'start_stop_day':
          page.visual_effect :fade, 'worktime_hours', :duration => 3
        when 'absolute_day':
          page.visual_effect :fade, 'worktime_from_start_time'
          page.visual_effect :fade, 'worktime_to_end_time'
        when 'week':
        when 'month':
      else
       flash[:notice] = "Its over"
      end 
    end  
  end
  
  def createtime
    @project = Project.find(params[:project_id])
    @employee = Employee.find(params[@user.id])
    if
      flash[:notice] = 'Worktime was successfully created.' 
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def changepasswd
  @employee = Employee.find(@user.id)
  end

  def edit
    @worktime = Worktime.find(params[:id])
  end

  def update
    @worktime = Worktime.find(params[:id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      redirect_to :action => 'show', :id => @worktime
    else
      render :action => 'edit'
    end
  end

  def destroy
    Worktime.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
