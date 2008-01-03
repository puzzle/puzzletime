# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class GraphController < ApplicationController
 
  # Checks if employee came from login or from direct url.
  before_filter :authenticate
  before_filter :authorize, :only => [:all_absences]
  before_filter :setPeriod

  def weekly
    @graph = WorktimeGraph.new(@period || Period.currentMonth, @user)
  end
  
  def all_absences
    @graph = VacationGraph.new(@period)
 end
  
end
