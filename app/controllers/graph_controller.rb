# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class GraphController < ApplicationController

  before_action :set_period

  skip_authorization_check

  def weekly
    @graph = WorktimeGraph.new(@period || Period.past_month, @user)
  end

  def all_absences
    @graph = VacationGraph.new(@period)
  end

end
