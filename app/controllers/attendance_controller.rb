class AttendanceController < WorktimeController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :addAttendanceTime ],
         :redirect_to => { :action => :listTime }
         
  def add
    createDefaultWorktime   
  end
  
  def split
    @attendance = session[:attendance]
    redirect_to :controller => 'worktime', :action => 'addTime' if @attendance.nil?
    @worktime = @attendance.worktimeTemplate
    setWorktimeAccounts
  end
  
  def delete
    session[:attendance].removeWorktime(params[:attendance_id].to_i)
    redirect_to :action => 'split'
  end
  
  def create
    if buildWorktime     
      @attendance = Attendance.new(@worktime)
      saveAttendance
    else
      render :action => 'add'
    end  
  end
  
  def createPart
    @attendance = session[:attendance]
    if buildWorktime        
      @attendance.addWorktime(@worktime)    
      saveAttendance         
    else
      setWorktimeAccounts
      render :action => 'split'
    end  
  end
  
private 

  def buildWorktime
    @worktime = Worktime.new
    @worktime.employee = @user
    setWorktimeParams
    return @worktime.valid?    
  end  
  
  def saveAttendance
    if params[:commit] != FINISH && @attendance.incomplete?
      session[:attendance] = @attendance
      redirect_to :action => 'split'
    else
      @attendance.save
      session[:attendance] = nil
      flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
      listDetailTime
    end
  end
  
end