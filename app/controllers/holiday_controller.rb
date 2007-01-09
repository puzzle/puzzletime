
class HolidayController < ApplicationController
  
  # Checks if employee came from login or from direct url.
  before_filter :authorize

  scaffold :holiday
  
  def list
    @holiday_pages, @holidays = paginate :holidays, 
                                         :order => 'holiday_date', 
                                         :per_page => NO_OF_OVERVIEW_ROWS
  end
  
  def show
    redirect_to :action => 'list'
  end
  
end
