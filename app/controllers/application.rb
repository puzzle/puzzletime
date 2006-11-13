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
  def authorize
    @user = session[:user]
    unless @user
      flash[:notice] = 'Please log in'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end 
  
  #returns the startdate of current week
  def startCurrentWeek(date)
    if date.wday == '0'
      date-6
    else
      date-(date.wday-1)
    end
  end
  
  #returns the enddate of current week
  def endCurrentWeek(date)
    startCurrentWeek(date)+5 
  end
  
  def parseDate(attributes, prefix)
    Date.parse("#{attributes[prefix + '(3i)']}-#{attributes[prefix + '(2i)']}-#{attributes[prefix + '(1i)']}")
  end
end

