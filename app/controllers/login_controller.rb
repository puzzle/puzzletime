# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz


class LoginController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize, :except => :login
 
  # Login procedure for user
  def login
    if request.get?
      session[:user] = nil
    else 
      logged_in = Employee.login(params[:employee][:shortname], params[:employee][:pwd])
      if  logged_in != nil
        session[:user] = logged_in
        redirect_to(:controller => 'worktime', :action => 'listTime')
      else
        flash[:notice] = "Invalid shortname/password combination"
      end
     end
  end
  
  #Logout procedure for user    
  def logout
    session[:user]=nil
    flash[:notice]="Logged out"
    redirect_to(:action => "login")
  end
end
