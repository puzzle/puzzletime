
class HolidayController < ApplicationController
  
  include ManageModule
  
  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
  def modelClass
    Holiday
  end
  
end
