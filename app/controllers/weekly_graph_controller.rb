# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class WeeklyGraphController < ApplicationController

  before_action :set_period

  skip_authorization_check

  def show
    @graph = WorktimeGraph.new(@period || Period.past_month, @user)
  end

end
