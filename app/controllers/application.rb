# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :set_charset

  def set_charset
    @headers["Content-Type"] = "text/html; charset=utf-8" 
  end
  
  #Filter for check if user is logged in or not
  def authenticate
    @user = session[:user]
    unless @user
      flash[:notice] = 'Please log in'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end 
  
  def authorize
    authenticate
    unless @user.management
      flash[:notice] = 'You are not authorized to view this page'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end  

end

