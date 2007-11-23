# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class GraphController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [:clients]
  before_filter :setPeriod

  def graph
    @graph = WorktimeGraph.new(@period || Period.currentMonth, @user)
  end

  
private  

  def setPeriod
    @period = session[:period]
  end


  
end
