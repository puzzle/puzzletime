class LoginController < ApplicationController

 before_filter :authorize, :except => :login
 
  def login
    if request.get?
      session[:user] = nil
    else
      logged_in_employee = Employee.new(params[:employee]).try_to_login
      if logged_in_employee
        session[:user] = logged_in_employee
        redirect_to(:controller => 'worktime', :action => 'list')
      else
        flash[:notice] = "Invalid shortname/password combination"
      end
     end
  end
      
  def logout
    session[:user]=nil
    flash[:notice]="Logged out"
    redirect_to(:action => "login")
  end
end
