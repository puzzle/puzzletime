class ProjecttimeController < WorktimeController
  
  def list
    redirect_to :controller => 'evaluator', :action => 'userProjects'
  end
  
protected

  def setWorktime
    @worktime = Projecttime.new   
  end
  
  def setWorktimeAccount
    @worktime.setProjectDefaults params[:account_id]
  end

  def setAccounts    
    @accounts = @user.projects 
  end  
  
  def userEvaluation
    'userProjects'
  end
  
end