# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz


class LoginController < ApplicationController

  verify :method => :post, :only => [ :logout ], 
         :redirect_to => HOME_ACTION
  
  def index
    redirect_to :action => "login"
  end
 
  # Login procedure for user
  def login
    if request.post?
      if login_with(params[:user], params[:pwd])
        redirect_to HOME_ACTION
      else
        flash[:notice] = "Ung&uuml;ltige Benutzerdaten"
      end
    end
  end
  
  #Logout procedure for user    
  def logout
    reset_session
    flash[:notice] = "Sie wurden ausgeloggt"
    redirect_to :action => "login"
  end

end
