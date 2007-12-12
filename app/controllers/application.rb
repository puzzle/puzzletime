# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  before_filter :set_charset
  filter_parameter_logging :pwd, :password

  def set_charset
    headers["Content-Type"] = "text/html; charset=utf-8" 
  end
    
  #Filter for check if user is logged in or not
  def authenticate
    user_id = session[:user_id]
    unless user_id
      redirect_to(:controller => 'login', :action => 'login' )
      return false
    end
    @user = Employee.find(user_id)
    return true
  end 
  
  def authorize
    if authenticate
      unless @user.management
        flash[:notice] = 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
        redirect_to(:controller => 'login', :action => 'login' )
        return false
      end
    else
      return false  
    end  
  end  

  def rescue_action_in_public(exception)
    case exception
      when ::ActionController::RoutingError, ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
        render(:file => "#{RAILS_ROOT}/public/404.html",
               :status => "404 Not Found")
      else
        render(:file => "#{RAILS_ROOT}/public/500.html",
               :status => "500 Error")
        SystemNotifier.deliver_exception_notification(self, request, exception)
    end                    
  end
  
protected  
  
  def renderGeneric(options)
    template = options[:action]
    if template && ! template_exists?("#{self.class.controller_path}/#{template}")
      options[:action] = "../#{genericPath}/#{template}"
    end    
    render options  
  end  
  
  def genericPath
    '.'
  end
  
  def setPeriod
    @period = nil
    p = session[:period]
    if p.kind_of? Array
      @period = Period.retrieve(*p)
    end
  end
  
end

