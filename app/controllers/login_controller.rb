# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz


class LoginController < ApplicationController

  verify :method => :post, :only => [ :logout ], 
         :redirect_to => { :controller => 'projecttime', :action => 'list' }
  
  def index
    redirect_to :action => "login"
  end
 
  # Login procedure for user
  def login
    puts 'login'
    if request.post?
      if login_with(params[:user], params[:pwd])
        redirect_to :controller => 'projecttime', :action => 'list'
      else
        flash[:notice] = "Ung&uuml;ltige Benutzerdaten"
      end
    end
    params[:main_controller] ||= 'projecttime'
    params[:main_action] ||= 'list'
  end
  
  #Logout procedure for user    
  def logout
    reset_session
    flash[:notice] = "Sie wurden ausgeloggt"
    redirect_to :action => "login"
  end

end
