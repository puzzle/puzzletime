# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  def authorize
    @user = session[:user]
    unless @user
      flash[:notice] = 'Please log in'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end 
end