# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class GraphController < ApplicationController

  # Checks if employee came from login or from direct url.
  before_action :authenticate
  before_action :set_period

  def weekly
    @graph = WorktimeGraph.new(@period || Period.past_month, @user)
  end

  def all_absences
    @graph = VacationGraph.new(@period)
 end

end
