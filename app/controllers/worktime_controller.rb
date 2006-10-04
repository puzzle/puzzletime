class WorktimeController < ApplicationController
  
  before_filter :authorize
  

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
 
  def addTime
    @project = Project.find(params[:project_id])
  end

  def newTime
    @worktime = Worktime.new
  end
  
  def createTime
    params[:worktime][:employee_id] = @user.id 
    params[:worktime][:project_id] = params[:project_id]
    worktime = Worktime.new(params[:worktime])
    if worktime.save
      flash[:notice] = 'Worktime was successfully created.' 
      redirect_to :action => 'listTime'
    else
      render :action => 'newTime'
    end
  end

  def editTime
    @worktime = Worktime.find(params[:id])
  end

  def updateTime
    @worktime = Worktime.find(params[:id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      redirect_to :action => 'show', :id => @worktime
    else
      render :action => 'edit'
    end
  end

  def destroyTime
    Worktime.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
